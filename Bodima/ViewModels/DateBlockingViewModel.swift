import Foundation
import SwiftUI

/**
 * DateBlockingViewModel manages date blocking functionality for reservation calendars.
 * Handles fetching reserved dates and providing date availability checking for calendar components.
 * 
 * Key Features:
 * - Fetches reserved dates for specific habitations
 * - Provides date blocking logic for calendar UI components
 * - Real-time availability checking with caching
 * - Clean separation of concerns following MVVM architecture
 * - Integration with existing ReservationViewModel for data consistency
 */
@MainActor
class DateBlockingViewModel: ObservableObject {
    
    /**
     * Published properties for date blocking state management.
     * These properties provide reactive updates to SwiftUI views.
     */
    
    /// Collection of blocked date ranges for the current habitation
    @Published var blockedDateRanges: [ReservedDateRange] = []
    
    /// Set of individual blocked dates for efficient lookup
    @Published var blockedDates: Set<Date> = []
    
    /// Loading state indicator for date fetching operations
    @Published var isLoadingBlockedDates = false
    
    /// Error message for date blocking operations
    @Published var dateBlockingError: String?
    
    /// Current habitation ID being tracked
    @Published var currentHabitationId: String?
    
    /**
     * Dependencies and initialization.
     */
    
    /// Reservation view model for fetching reserved dates
    private let reservationViewModel: ReservationViewModel
    
    /// Calendar instance for date calculations
    private let calendar = Calendar.current
    
    /**
     * Initializes the DateBlockingViewModel with reservation dependencies.
     * 
     * @param reservationViewModel The reservation view model for data fetching (defaults to new instance)
     */
    init(reservationViewModel: ReservationViewModel? = nil) {
        self.reservationViewModel = reservationViewModel ?? ReservationViewModel()
    }
    
    /**
     * Core date blocking management methods.
     */
    
    /**
     * Fetches and processes blocked dates for a specific habitation.
     * Updates the blocked dates collection and provides efficient date lookup.
     * 
     * @param habitationId The unique identifier of the habitation
     */
    func fetchBlockedDates(for habitationId: String) {
        guard !habitationId.isEmpty else {
            dateBlockingError = "Invalid habitation ID"
            return
        }
        
        // Skip if already loading for the same habitation
        if isLoadingBlockedDates && currentHabitationId == habitationId {
            return
        }
        
        currentHabitationId = habitationId
        isLoadingBlockedDates = true
        dateBlockingError = nil
        
        reservationViewModel.getReservedDates(habitationId: habitationId) { [weak self] reservedRanges in
            DispatchQueue.main.async {
                self?.processReservedDates(reservedRanges)
            }
        }
    }
    
    /**
     * Processes reserved date ranges and converts them to blocked dates set.
     * Creates an efficient lookup structure for calendar date checking.
     * 
     * @param reservedRanges Array of reserved date ranges from the server
     */
    private func processReservedDates(_ reservedRanges: [ReservedDateRange]) {
        blockedDateRanges = reservedRanges
        blockedDates = generateBlockedDatesSet(from: reservedRanges)
        isLoadingBlockedDates = false
        
        print("🔍 DEBUG - Processed \(reservedRanges.count) reserved ranges into \(blockedDates.count) blocked dates")
    }
    
    /**
     * Generates a set of individual blocked dates from reserved date ranges.
     * Includes all dates within each reserved range for comprehensive blocking.
     * 
     * @param ranges Array of reserved date ranges
     * @return Set of individual blocked dates
     */
    private func generateBlockedDatesSet(from ranges: [ReservedDateRange]) -> Set<Date> {
        var dates = Set<Date>()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        for range in ranges {
            print("🔍 DEBUG - Processing range: \(range.checkInDate) to \(range.checkOutDate)")
            
            guard let startDate = dateFormatter.date(from: range.checkInDate),
                  let endDate = dateFormatter.date(from: range.checkOutDate) else {
                print("🔍 DEBUG - Failed to parse dates for range")
                print("🔍 DEBUG - Trying alternative date parsing...")
                
                // Try alternative parsing without fractional seconds
                let alternativeFormatter = ISO8601DateFormatter()
                alternativeFormatter.formatOptions = [.withInternetDateTime]
                
                // Remove fractional seconds if present
                let cleanCheckIn = range.checkInDate.replacingOccurrences(of: "\\.\\d{3}", with: "", options: .regularExpression)
                let cleanCheckOut = range.checkOutDate.replacingOccurrences(of: "\\.\\d{3}", with: "", options: .regularExpression)
                
                guard let altStartDate = alternativeFormatter.date(from: cleanCheckIn),
                      let altEndDate = alternativeFormatter.date(from: cleanCheckOut) else {
                    print("🔍 DEBUG - Alternative parsing also failed")
                    continue
                }
                
                print("🔍 DEBUG - Alternative parsing succeeded: \(altStartDate) to \(altEndDate)")
                
                // Use alternative parsed dates
                var currentDate = calendar.startOfDay(for: altStartDate)
                let rangeEndDate = calendar.startOfDay(for: altEndDate)
                
                print("🔍 DEBUG - Processing from \(currentDate) to \(rangeEndDate)")
                
                while currentDate < rangeEndDate {
                    dates.insert(currentDate)
                    print("🔍 DEBUG - Added blocked date: \(currentDate)")
                    guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                        break
                    }
                    currentDate = nextDate
                }
                continue
            }
            
            print("🔍 DEBUG - Parsed dates: \(startDate) to \(endDate)")
            
            // Add all dates in the range (inclusive of start, exclusive of end for checkout)
            var currentDate = calendar.startOfDay(for: startDate)
            let rangeEndDate = calendar.startOfDay(for: endDate)
            
            print("🔍 DEBUG - Processing from \(currentDate) to \(rangeEndDate)")
            
            while currentDate < rangeEndDate {
                dates.insert(currentDate)
                print("🔍 DEBUG - Added blocked date: \(currentDate)")
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                    break
                }
                currentDate = nextDate
            }
        }
        
        print("🔍 DEBUG - Final blocked dates count: \(dates.count)")
        return dates
    }
    
    /**
     * Date availability checking methods.
     */
    
    /**
     * Checks if a specific date is blocked (reserved).
     * Provides efficient O(1) lookup for calendar date validation.
     * 
     * @param date The date to check for availability
     * @return True if the date is blocked, false if available
     */
    func isDateBlocked(_ date: Date) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        return blockedDates.contains(dayStart)
    }
    
    /**
     * Checks if a date range is available for reservation.
     * Validates that no dates in the range are blocked.
     * 
     * @param checkInDate The proposed check-in date
     * @param checkOutDate The proposed check-out date
     * @return True if the entire range is available, false if any date is blocked
     */
    func isDateRangeAvailable(checkInDate: Date, checkOutDate: Date) -> Bool {
        let startDay = calendar.startOfDay(for: checkInDate)
        let endDay = calendar.startOfDay(for: checkOutDate)
        
        var currentDate = startDay
        while currentDate < endDay {
            if blockedDates.contains(currentDate) {
                return false
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return true
    }
    
    /**
     * Gets the next available date after a blocked date.
     * Useful for suggesting alternative dates to users.
     * 
     * @param fromDate The starting date to search from
     * @param maxDaysAhead Maximum number of days to search ahead
     * @return Next available date if found within the search limit
     */
    func getNextAvailableDate(from fromDate: Date, maxDaysAhead: Int = 30) -> Date? {
        var currentDate = calendar.startOfDay(for: fromDate)
        
        for _ in 0..<maxDaysAhead {
            if !blockedDates.contains(currentDate) {
                return currentDate
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return nil
    }
    
    /**
     * Gets conflicting reservations for a specific date range.
     * Provides detailed information about reservation conflicts.
     * 
     * @param checkInDate The proposed check-in date
     * @param checkOutDate The proposed check-out date
     * @return Array of conflicting reserved date ranges
     */
    func getConflictingReservations(checkInDate: Date, checkOutDate: Date) -> [ReservedDateRange] {
        let dateFormatter = ISO8601DateFormatter()
        let startDay = calendar.startOfDay(for: checkInDate)
        let endDay = calendar.startOfDay(for: checkOutDate)
        
        return blockedDateRanges.filter { range in
            guard let rangeStart = dateFormatter.date(from: range.checkInDate),
                  let rangeEnd = dateFormatter.date(from: range.checkOutDate) else {
                return false
            }
            
            let rangeStartDay = calendar.startOfDay(for: rangeStart)
            let rangeEndDay = calendar.startOfDay(for: rangeEnd)
            
            // Check for any overlap between the ranges
            return !(endDay <= rangeStartDay || startDay >= rangeEndDay)
        }
    }
    
    /**
     * Utility and state management methods.
     */
    
    /**
     * Refreshes blocked dates for the current habitation.
     * Forces a fresh fetch from the server.
     */
    func refreshBlockedDates() {
        guard let habitationId = currentHabitationId else { return }
        fetchBlockedDates(for: habitationId)
    }
    
    /**
     * Clears all blocked dates state.
     * Used for cleanup when switching between habitations.
     */
    func clearBlockedDates() {
        blockedDateRanges = []
        blockedDates = []
        currentHabitationId = nil
        dateBlockingError = nil
        isLoadingBlockedDates = false
    }
    
    /**
     * Gets a summary of blocked dates for display purposes.
     * Provides user-friendly information about reservation status.
     * 
     * @return Dictionary containing blocked dates statistics
     */
    func getBlockedDatesSummary() -> [String: Any] {
        return [
            "totalBlockedDates": blockedDates.count,
            "reservationRanges": blockedDateRanges.count,
            "isLoading": isLoadingBlockedDates,
            "hasError": dateBlockingError != nil
        ]
    }
    
    /**
     * Validates if a proposed reservation doesn't conflict with existing ones.
     * Comprehensive validation including edge cases and date boundaries.
     * 
     * @param checkInDate The proposed check-in date
     * @param checkOutDate The proposed check-out date
     * @return Validation result with success status and error message
     */
    func validateReservationDates(checkInDate: Date, checkOutDate: Date) -> (isValid: Bool, errorMessage: String?) {
        // Basic date validation
        guard checkOutDate > checkInDate else {
            return (false, "Check-out date must be after check-in date")
        }
        
        // Check for past dates
        let today = calendar.startOfDay(for: Date())
        let checkInDay = calendar.startOfDay(for: checkInDate)
        
        guard checkInDay >= today else {
            return (false, "Check-in date cannot be in the past")
        }
        
        // Check for blocked dates in the range
        if !isDateRangeAvailable(checkInDate: checkInDate, checkOutDate: checkOutDate) {
            let conflictingReservations = getConflictingReservations(checkInDate: checkInDate, checkOutDate: checkOutDate)
            let conflictCount = conflictingReservations.count
            return (false, "Selected dates conflict with \(conflictCount) existing reservation\(conflictCount > 1 ? "s" : "")")
        }
        
        return (true, nil)
    }
}

/**
 * Extension for date formatting and utility functions.
 */
extension DateBlockingViewModel {
    
    /**
     * Formats a date for display in error messages and user feedback.
     * 
     * @param date The date to format
     * @return Formatted date string
     */
    func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /**
     * Gets a user-friendly description of blocked date ranges.
     * 
     * @return Array of formatted date range descriptions
     */
    func getBlockedRangesDescription() -> [String] {
        return blockedDateRanges.map { range in
            let dateFormatter = ISO8601DateFormatter()
            guard let startDate = dateFormatter.date(from: range.checkInDate),
                  let endDate = dateFormatter.date(from: range.checkOutDate) else {
                return "Invalid date range"
            }
            
            let startFormatted = formatDateForDisplay(startDate)
            let endFormatted = formatDateForDisplay(endDate)
            return "\(startFormatted) - \(endFormatted)"
        }
    }
}

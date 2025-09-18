import SwiftUI
import Foundation

struct IndustryDatePickerComponent: View {
    @Binding var checkInDate: Date
    @Binding var checkOutDate: Date
    let habitationId: String
    let onDateChange: (Date, Date) -> Void
    
    // Date blocking functionality
    @StateObject private var dateBlockingViewModel = DateBlockingViewModel()
    @State private var showingDateConflictAlert = false
    @State private var dateConflictMessage = ""
    @State private var isSelectingCheckIn = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Date selection mode toggle
            dateSelectionModeToggle
            
            // Selected dates summary
            selectedDatesSummary
            
            // Native date picker with validation
            nativeDatePicker
            
            // Availability information
            availabilityInfo
            
            // Blocked dates list (if any in current selection)
            blockedDatesWarning
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .alert("Date Unavailable", isPresented: $showingDateConflictAlert) {
            Button("Choose Different Date") { }
        } message: {
            Text(dateConflictMessage)
        }
        .onAppear {
            dateBlockingViewModel.fetchBlockedDates(for: habitationId)
        }
    }
    
    // MARK: - View Components
    
    private var dateSelectionModeToggle: some View {
        HStack(spacing: 0) {
            Button(action: { isSelectingCheckIn = true }) {
                VStack(spacing: 4) {
                    Text("Check-in")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelectingCheckIn ? .white : AppColors.foreground)
                    Text(formatDate(checkInDate))
                        .font(.caption)
                        .foregroundColor(isSelectingCheckIn ? .white.opacity(0.8) : AppColors.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelectingCheckIn ? AppColors.primary : Color.clear)
                )
            }
            
            Button(action: { isSelectingCheckIn = false }) {
                VStack(spacing: 4) {
                    Text("Check-out")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(!isSelectingCheckIn ? .white : AppColors.foreground)
                    Text(formatDate(checkOutDate))
                        .font(.caption)
                        .foregroundColor(!isSelectingCheckIn ? .white.opacity(0.8) : AppColors.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(!isSelectingCheckIn ? AppColors.primary : Color.clear)
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.primary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var selectedDatesSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Dates")
                .font(.headline)
                .foregroundColor(AppColors.foreground)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Check-in")
                        .font(.caption)
                        .foregroundColor(AppColors.secondary)
                    Text(formatDateLong(checkInDate))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.primary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(AppColors.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Check-out")
                        .font(.caption)
                        .foregroundColor(AppColors.secondary)
                    Text(formatDateLong(checkOutDate))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.primary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.primary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Duration display
            let nights = Calendar.current.dateComponents([.day], from: checkInDate, to: checkOutDate).day ?? 0
            if nights > 0 {
                Text("\(nights) night\(nights == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(AppColors.secondary)
            }
        }
    }
    
    private var nativeDatePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isSelectingCheckIn ? "Select Check-in Date" : "Select Check-out Date")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppColors.foreground)
            
            DatePicker(
                "",
                selection: Binding(
                    get: { isSelectingCheckIn ? checkInDate : checkOutDate },
                    set: { newDate in
                        handleDateSelection(newDate)
                    }
                ),
                in: dateRange,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(AppColors.primary)
            .onChange(of: isSelectingCheckIn) { _ in
                // Auto-switch to checkout after selecting checkin
                if !isSelectingCheckIn && checkInDate >= checkOutDate {
                    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: checkInDate) ?? checkInDate
                    checkOutDate = nextDay
                    onDateChange(checkInDate, checkOutDate)
                }
            }
        }
    }
    
    private var availabilityInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !dateBlockingViewModel.blockedDates.isEmpty {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("\(dateBlockingViewModel.blockedDates.count) dates are unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Validation status
            let validation = dateBlockingViewModel.validateReservationDates(
                checkInDate: checkInDate,
                checkOutDate: checkOutDate
            )
            
            if !validation.isValid, let errorMessage = validation.errorMessage {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else if validation.isValid && !dateBlockingViewModel.blockedDates.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Selected dates are available")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private var blockedDatesWarning: some View {
        let conflicts = dateBlockingViewModel.getConflictingReservations(
            checkInDate: checkInDate,
            checkOutDate: checkOutDate
        )
        
        return Group {
            if !conflicts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unavailable Dates in Your Selection:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    
                    ForEach(conflicts.indices, id: \.self) { index in
                        if let startDate = ISO8601DateFormatter().date(from: conflicts[index].checkInDate),
                           let endDate = ISO8601DateFormatter().date(from: conflicts[index].checkOutDate) {
                            Text("• \(formatDateRange(startDate: startDate, endDate: endDate))")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var dateRange: ClosedRange<Date> {
        let today = Date()
        let futureLimit = Calendar.current.date(byAdding: .year, value: 2, to: today) ?? today
        
        if isSelectingCheckIn {
            return today...futureLimit
        } else {
            let minCheckOut = Calendar.current.date(byAdding: .day, value: 1, to: checkInDate) ?? checkInDate
            return minCheckOut...futureLimit
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleDateSelection(_ newDate: Date) {
        if isSelectingCheckIn {
            // Check if selected check-in date is blocked
            if dateBlockingViewModel.isDateBlocked(newDate) {
                dateConflictMessage = "This date is already reserved. Please select a different check-in date."
                showingDateConflictAlert = true
                return
            }
            
            checkInDate = newDate
            
            // Auto-adjust checkout if needed
            if checkOutDate <= checkInDate {
                let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: checkInDate) ?? checkInDate
                checkOutDate = nextDay
            }
            
            // Auto-switch to checkout selection
            isSelectingCheckIn = false
            
        } else {
            // Check if selected check-out date is blocked
            if dateBlockingViewModel.isDateBlocked(newDate) {
                dateConflictMessage = "This date is already reserved. Please select a different check-out date."
                showingDateConflictAlert = true
                return
            }
            
            checkOutDate = newDate
        }
        
        // Validate the entire range
        let validation = dateBlockingViewModel.validateReservationDates(
            checkInDate: checkInDate,
            checkOutDate: checkOutDate
        )
        
        if !validation.isValid {
            dateConflictMessage = validation.errorMessage ?? "Selected dates are not available"
            showingDateConflictAlert = true
            return
        }
        
        // All good, update parent
        onDateChange(checkInDate, checkOutDate)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatDateLong(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDateRange(startDate: Date, endDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

// MARK: - Preview
struct IndustryDatePickerComponent_Previews: PreviewProvider {
    static var previews: some View {
        IndustryDatePickerComponent(
            checkInDate: .constant(Date()),
            checkOutDate: .constant(Date().addingTimeInterval(86400)),
            habitationId: "test",
            onDateChange: { _, _ in }
        )
        .padding()
    }
}

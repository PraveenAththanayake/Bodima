import SwiftUI

// Date picker component for reservation date selection
// Handles check-in and check-out date selection with validation and date blocking
struct ReserveDatePickerComponent: View {
    @Binding var checkInDate: Date
    @Binding var checkOutDate: Date
    let habitationId: String
    let onDateChange: (Date, Date) -> Void
    
    // Date blocking functionality
    @StateObject private var dateBlockingViewModel = DateBlockingViewModel()
    @State private var showingDateConflictAlert = false
    @State private var dateConflictMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Availability status display
            availabilityStatusSection
            
            // Date selection interface
            dateSelectionSection
            
            // Selected dates summary
            selectedDatesSummary
            
            // Date validation and conflict display
            dateValidationStatus
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
        .alert("Date Conflict", isPresented: $showingDateConflictAlert) {
            Button("OK") { }
        } message: {
            Text(dateConflictMessage)
        }
        .onAppear {
            dateBlockingViewModel.fetchBlockedDates(for: habitationId)
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var availabilityStatusSection: some View {
        if !dateBlockingViewModel.blockedDates.isEmpty {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("\(dateBlockingViewModel.blockedDates.count) dates are unavailable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var dateSelectionSection: some View {
        VStack(spacing: 16) {
            checkInDatePicker
            checkOutDateSection
        }
    }
    
    @ViewBuilder
    private var checkInDatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Check-in Date")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.foreground)
            
            CustomCalendarView(
                selectedDate: $checkInDate,
                blockedDates: dateBlockingViewModel.blockedDates,
                minDate: Date(),
                maxDate: Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date(),
                onDateSelected: { newDate in
                    handleCheckInDateChange(newDate)
                }
            )
            
            checkInDateWarning
        }
    }
    
    @ViewBuilder
    private var checkInDateWarning: some View {
        if dateBlockingViewModel.isDateBlocked(checkInDate) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("This date is not available")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var checkOutDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Check-out Date")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.foreground)
            
            CustomCalendarView(
                selectedDate: $checkOutDate,
                blockedDates: dateBlockingViewModel.blockedDates,
                minDate: minCheckOutDate,
                maxDate: Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date(),
                onDateSelected: { newDate in
                    handleCheckOutDateChange(newDate)
                }
            )
        }
    }
    
    private var minCheckOutDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: checkInDate) ?? checkInDate
    }
    
    private var availableDateRange: ClosedRange<Date> {
        let today = Date()
        let futureLimit = Calendar.current.date(byAdding: .year, value: 2, to: today) ?? today
        
        // For now, return today to future limit - we'll handle individual date blocking in the handler
        return today...futureLimit
    }
    
    private var availableCheckOutDateRange: ClosedRange<Date> {
        let minDate = minCheckOutDate
        let futureLimit = Calendar.current.date(byAdding: .year, value: 2, to: Date()) ?? Date()
        
        // For now, return min checkout date to future limit - we'll handle individual date blocking in the handler
        return minDate...futureLimit
    }
    
    @ViewBuilder
    private var selectedDatesSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected Dates")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.foreground)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Check-in")
                        .font(.caption)
                        .foregroundColor(AppColors.secondary)
                    Text(formatDateForDisplay(checkInDate))
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
                    Text(formatDateForDisplay(checkOutDate))
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
    
    @ViewBuilder
    private var dateValidationStatus: some View {
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
    
    @ViewBuilder
    private var conflictingReservationsSection: some View {
        let conflicts = dateBlockingViewModel.getConflictingReservations(
            checkInDate: checkInDate,
            checkOutDate: checkOutDate
        )
        
        if !conflicts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Conflicting Reservations:")
                    .font(.caption.bold())
                    .foregroundColor(.red)
                
                ForEach(conflicts.indices, id: \.self) { index in
                    conflictRow(for: conflicts[index])
                }
            }
        }
    }
    
    @ViewBuilder
    private func conflictRow(for conflict: ReservedDateRange) -> some View {
        if let startDate = ISO8601DateFormatter().date(from: conflict.checkInDate),
           let endDate = ISO8601DateFormatter().date(from: conflict.checkOutDate) {
            Text("• \(formatDateRange(startDate: startDate, endDate: endDate))")
                .font(.caption)
                .foregroundColor(.red)
        }
    }
    
    private func formatDateRange(startDate: Date, endDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
    }
    
    private var backgroundStyle: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(AppColors.background)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColors.border, lineWidth: 1)
            )
    }
    
    // MARK: - Private Methods
    
    /**
     * Handles check-in date changes with smooth validation.
     * Only processes valid dates from the custom calendar.
     */
    private func handleCheckInDateChange(_ newDate: Date) {
        print("🔍 DEBUG - Check-in date handler called with: \(newDate)")
        
        // Update the binding directly and call the parent handler
        let minCheckOut = Calendar.current.date(byAdding: .day, value: 1, to: newDate) ?? newDate
        let adjustedCheckOut = max(checkOutDate, minCheckOut)
        
        print("🔍 DEBUG - Calling onDateChange with: \(newDate), \(adjustedCheckOut)")
        onDateChange(newDate, adjustedCheckOut)
    }
    
    private func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /**
     * Handles check-out date changes with smooth validation.
     * Only processes valid dates from the custom calendar.
     */
    private func handleCheckOutDateChange(_ newDate: Date) {
        // Since CustomCalendarView prevents blocked date selection,
        // we can proceed with confidence that the date is valid
        onDateChange(checkInDate, newDate)
    }
}

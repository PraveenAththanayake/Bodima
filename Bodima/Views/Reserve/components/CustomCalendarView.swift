import SwiftUI
import Foundation

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let blockedDates: Set<Date>
    let minDate: Date
    let maxDate: Date
    let onDateSelected: (Date) -> Void
    
    @State private var currentMonth = Date()
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 8) {
            // Month navigation header
            monthNavigationHeader
            
            // Days of week header
            daysOfWeekHeader
            
            // Calendar grid
            calendarGrid
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
    }
    
    private var monthNavigationHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .foregroundColor(AppColors.primary)
                    .font(.title2)
            }
            .disabled(!canNavigateToPreviousMonth)
            
            Spacer()
            
            Text(monthYearString)
                .font(.headline)
                .foregroundColor(AppColors.foreground)
            
            Spacer()
            
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.primary)
                    .font(.title2)
            }
            .disabled(!canNavigateToNextMonth)
        }
    }
    
    private var daysOfWeekHeader: some View {
        HStack {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
            ForEach(0..<daysInMonth.count, id: \.self) { index in
                if let date = daysInMonth[index] {
                    dayCell(for: date)
                } else {
                    // Empty cell for padding
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 32)
                }
            }
        }
    }
    
    private func dayCell(for date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isBlocked = blockedDates.contains(calendar.startOfDay(for: date))
        let isToday = calendar.isDateInToday(date)
        let isPastDate = date < minDate
        let isFutureDate = date > maxDate
        let isDisabled = isBlocked || isPastDate || isFutureDate
        
        return Button(action: {
            if !isDisabled {
                selectedDate = date
                onDateSelected(date)
            }
        }) {
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundColorForDate(isSelected: isSelected, isBlocked: isBlocked, isToday: isToday, isDisabled: isDisabled))
                    .frame(width: 28, height: 28)
                
                // Date text
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(textColorForDate(isSelected: isSelected, isBlocked: isBlocked, isDisabled: isDisabled))
                
                // Blocked indicator
                if isBlocked {
                    Image(systemName: "xmark")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                        .offset(x: 8, y: -8)
                }
            }
        }
        .disabled(isDisabled)
        .frame(height: 32)
    }
    
    // MARK: - Helper Methods
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDayOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let numberOfDays = monthRange.count
        
        var days: [Date?] = []
        
        // Add empty cells for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add actual days of the month
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private var canNavigateToPreviousMonth: Bool {
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else {
            return false
        }
        return previousMonth >= minDate
    }
    
    private var canNavigateToNextMonth: Bool {
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else {
            return false
        }
        return nextMonth <= maxDate
    }
    
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func backgroundColorForDate(isSelected: Bool, isBlocked: Bool, isToday: Bool, isDisabled: Bool) -> Color {
        if isSelected {
            return AppColors.primary
        } else if isBlocked {
            return Color.red.opacity(0.8)
        } else if isToday {
            return AppColors.primary.opacity(0.2)
        } else if isDisabled {
            return AppColors.border.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private func textColorForDate(isSelected: Bool, isBlocked: Bool, isDisabled: Bool) -> Color {
        if isSelected {
            return .white
        } else if isBlocked {
            return .white
        } else if isDisabled {
            return AppColors.secondary.opacity(0.5)
        } else {
            return AppColors.foreground
        }
    }
}

// MARK: - Preview
struct CustomCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CustomCalendarView(
            selectedDate: .constant(Date()),
            blockedDates: Set([Date()]),
            minDate: Date(),
            maxDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date(),
            onDateSelected: { _ in }
        )
        .padding()
    }
}

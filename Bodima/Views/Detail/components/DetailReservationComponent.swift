import SwiftUI

// Reservation status display with period management and loading states
// Handles reservation data visualization and availability indicators
struct DetailReservationComponent: View {
    let reservedDates: [ReservedDateRange]
    let isLoadingReservations: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reservation Status")
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Spacer()
                
                // Loading indicator for async reservation data fetching
                if isLoadingReservations {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Conditional content based on reservation state
            if reservedDates.isEmpty && !isLoadingReservations {
                // Available state with positive visual feedback
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                    
                    Text("Available for Booking")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                    
                    Text("This property has no current reservations")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else if !reservedDates.isEmpty {
                // Reserved periods list with detailed information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Reserved Periods")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.foreground)
                    
                    ForEach(reservedDates) { reservation in
                        ReservationPeriodItemView(reservation: reservation)
                    }
                }
            }
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
        .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// Individual reservation period display with status indicators
// Shows reservation details, dates, and user information
struct ReservationPeriodItemView: View {
    let reservation: ReservedDateRange
    
    // Date formatting utilities for consistent display
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    private var checkInDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: reservation.checkInDate) {
            return date
        }
        
        // Fallback: try without fractional seconds
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]
        let cleanDateString = reservation.checkInDate.replacingOccurrences(of: "\\.\\d{3}", with: "", options: .regularExpression)
        return fallbackFormatter.date(from: cleanDateString)
    }
    
    private var checkOutDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: reservation.checkOutDate) {
            return date
        }
        
        // Fallback: try without fractional seconds
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]
        let cleanDateString = reservation.checkOutDate.replacingOccurrences(of: "\\.\\d{3}", with: "", options: .regularExpression)
        return fallbackFormatter.date(from: cleanDateString)
    }
    
    // Status-based styling for visual differentiation
    private var statusColor: Color {
        switch reservation.status.lowercased() {
        case "confirmed":
            return .red
        case "pending":
            return .orange
        default:
            return .gray
        }
    }
    
    private var statusText: String {
        switch reservation.status.lowercased() {
        case "confirmed":
            return "Confirmed"
        case "pending":
            return "Pending Payment"
        default:
            return reservation.status.capitalized
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.mutedForeground)
                    
                    if let checkIn = checkInDate, let checkOut = checkOutDate {
                        Text("\(dateFormatter.string(from: checkIn)) - \(dateFormatter.string(from: checkOut))")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.foreground)
                    } else {
                        Text("Invalid dates")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.mutedForeground)
                    }
                }
                
                // Optional user information display
                if let user = reservation.user, !user.fullName.isEmpty {
                    HStack {
                        Image(systemName: "person")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.mutedForeground)
                        
                        Text("Reserved by \(user.fullName)")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                    }
                }
            }
            
            Spacer()
            
            // Status badge with color-coded styling
            Text(statusText)
                .font(.caption.bold())
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(12)
        .background(AppColors.input)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

import SwiftUI

// Individual reservation card component with comprehensive details
// Displays property info, dates, status, and payment information
struct ReservationHistoryCardComponent: View {
    let reservation: EnhancedReservationData
    
    // Date formatting utilities for consistent display
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
    
    private var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter
    }
    
    // Parse check-in date with multiple format fallbacks
    private var checkInDate: Date? {
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: reservation.checkInDate) {
            return date
        }
        
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: reservation.checkInDate) {
            return date
        }
        
        let standardFormatter = DateFormatter()
        standardFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return standardFormatter.date(from: reservation.checkInDate)
    }
    
    // Parse check-out date with multiple format fallbacks
    private var checkOutDate: Date? {
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: reservation.checkOutDate) {
            return date
        }
        
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: reservation.checkOutDate) {
            return date
        }
        
        let standardFormatter = DateFormatter()
        standardFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return standardFormatter.date(from: reservation.checkOutDate)
    }
    
    // Dynamic status color based on reservation state
    private var statusColor: Color {
        switch reservation.status.lowercased() {
        case "confirmed":
            return .green
        case "pending":
            return .orange
        case "cancelled":
            return .red
        case "expired":
            return .gray
        default:
            return .blue
        }
    }
    
    // Human-readable status text with context
    private var statusText: String {
        switch reservation.status.lowercased() {
        case "confirmed":
            return "Confirmed"
        case "pending":
            return "Pending Payment"
        case "cancelled":
            return "Cancelled"
        case "expired":
            return "Expired"
        default:
            return reservation.status.capitalized
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Property information header with image and details
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: reservation.habitation?.mainPictureUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.input)
                        .overlay(
                            Image(systemName: "house.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(AppColors.mutedForeground)
                        )
                }
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Property image")
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(reservation.habitation?.name ?? "Unknown Property")
                        .font(.headline.bold())
                        .foregroundStyle(AppColors.foreground)
                        .lineLimit(2)
                    
                    Text(reservation.habitation?.type ?? "Room")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppColors.mutedForeground.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text("LKR \(reservation.totalAmount)")
                        .font(.title3.bold())
                        .foregroundStyle(AppColors.primary)
                    
                    Text("\(reservation.totalDays) night\(reservation.totalDays == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                }
                
                Spacer()
                
                // Status and payment indicators
                VStack(alignment: .trailing, spacing: 8) {
                    Text(statusText)
                        .font(.caption.bold())
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.15))
                        .cornerRadius(12)
                    
                    if reservation.isPaymentCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.green)
                            Text("Paid")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                        .accessibilityLabel("Payment completed")
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.orange)
                            Text("Unpaid")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        .accessibilityLabel("Payment pending")
                    }
                }
            }
            
            Divider()
                .background(AppColors.border)
            
            // Detailed reservation information section
            VStack(spacing: 12) {
                // Check-in and check-out dates
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 20)
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if let checkIn = checkInDate, let checkOut = checkOutDate {
                            HStack {
                                Text("Check-in:")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.mutedForeground)
                                Text(dateFormatter.string(from: checkIn))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppColors.foreground)
                                Spacer()
                            }
                            HStack {
                                Text("Check-out:")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.mutedForeground)
                                Text(dateFormatter.string(from: checkOut))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppColors.foreground)
                                Spacer()
                            }
                        } else {
                            Text("Date parsing error - Raw dates:")
                                .font(.caption)
                                .foregroundStyle(.red)
                            Text("In: \(reservation.checkInDate)")
                                .font(.caption2)
                                .foregroundStyle(AppColors.mutedForeground)
                            Text("Out: \(reservation.checkOutDate)")
                                .font(.caption2)
                                .foregroundStyle(AppColors.mutedForeground)
                        }
                    }
                    
                    Spacer()
                }
                
                // Reservation identifier for reference
                HStack {
                    Image(systemName: "number")
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 20)
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reservation ID")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        Text(String(reservation.id.suffix(8)))
                            .font(.caption.bold())
                            .foregroundStyle(AppColors.foreground)
                    }
                    
                    Spacer()
                }
                
                // Booking creation timestamp
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 20)
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Booked on")
                            .font(.caption)
                            .foregroundStyle(AppColors.mutedForeground)
                        if let createdDate = parseCreatedDate() {
                            Text(dateFormatter.string(from: createdDate))
                                .font(.caption.bold())
                                .foregroundStyle(AppColors.foreground)
                        } else {
                            Text("Unknown")
                                .font(.caption.bold())
                                .foregroundStyle(AppColors.mutedForeground)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(AppColors.input)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(createAccessibilityLabel())
    }
    
    // Parse creation date with format fallbacks
    private func parseCreatedDate() -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: reservation.createdAt) {
            return date
        }
        
        let standardFormatter = DateFormatter()
        standardFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return standardFormatter.date(from: reservation.createdAt)
    }
    
    // Create comprehensive accessibility label for screen readers
    private func createAccessibilityLabel() -> String {
        let propertyName = reservation.habitation?.name ?? "Unknown Property"
        let amount = "LKR \(reservation.totalAmount)"
        let nights = "\(reservation.totalDays) night\(reservation.totalDays == 1 ? "" : "s")"
        let status = statusText
        let paymentStatus = reservation.isPaymentCompleted ? "Payment completed" : "Payment pending"
        
        return "\(propertyName), \(amount) for \(nights), Status: \(status), \(paymentStatus)"
    }
}

#Preview {
    // Preview with mock data would require EnhancedReservationData
    Text("ReservationHistoryCardComponent Preview")
}

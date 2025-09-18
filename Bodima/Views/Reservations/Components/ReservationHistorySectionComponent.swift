import SwiftUI

// Section component for grouping reservations by status
// Displays categorized reservations with visual indicators and counts
struct ReservationHistorySectionComponent: View {
    let title: String
    let reservations: [EnhancedReservationData]
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Spacer()
                
                Text("\(reservations.count)")
                    .font(.caption.bold())
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.1))
                    .cornerRadius(8)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title) section with \(reservations.count) reservations")
            
            LazyVStack(spacing: 12) {
                ForEach(reservations) { reservation in
                    ReservationHistoryCardComponent(reservation: reservation)
                }
            }
        }
    }
}

#Preview {
    ReservationHistorySectionComponent(
        title: "Upcoming",
        reservations: [],
        color: .blue,
        icon: "calendar"
    )
}

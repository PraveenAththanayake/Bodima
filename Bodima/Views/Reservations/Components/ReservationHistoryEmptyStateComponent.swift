import SwiftUI

// Empty state component for when user has no reservations
// Provides encouraging message and visual feedback for first-time users
struct ReservationHistoryEmptyStateComponent: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.mutedForeground)
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                Text("No Reservations Yet")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Text("Start exploring properties and make your first reservation!")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.mutedForeground)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No reservations found")
        .accessibilityHint("You haven't made any reservations yet. Start exploring properties to make your first booking")
    }
}

#Preview {
    ReservationHistoryEmptyStateComponent()
}

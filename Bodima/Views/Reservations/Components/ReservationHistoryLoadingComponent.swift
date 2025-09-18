import SwiftUI

// Loading state component for reservation history
// Displays centered progress indicator with descriptive text
struct ReservationHistoryLoadingComponent: View {
    var body: some View {
        ProgressView("Loading your reservations...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 100)
            .accessibilityLabel("Loading reservations")
            .accessibilityHint("Please wait while we fetch your reservation history")
    }
}

#Preview {
    ReservationHistoryLoadingComponent()
}

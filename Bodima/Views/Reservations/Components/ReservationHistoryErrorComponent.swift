import SwiftUI

// Error state component for reservation history failures
// Provides clear error messaging with retry functionality
struct ReservationHistoryErrorComponent: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.red)
                .accessibilityHidden(true)
            
            Text("Error Loading Reservations")
                .font(.headline)
                .foregroundStyle(AppColors.foreground)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppColors.mutedForeground)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Double tap to retry loading reservations")
        }
        .padding(.top, 100)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error loading reservations. \(message)")
    }
}

#Preview {
    ReservationHistoryErrorComponent(
        message: "Network connection failed",
        onRetry: {}
    )
}

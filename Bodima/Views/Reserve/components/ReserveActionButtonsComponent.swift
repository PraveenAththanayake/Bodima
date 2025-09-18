import SwiftUI

// Action buttons component for reservation confirmation and calendar integration
// Handles calendar permission requests and navigation to payment flow
struct ReserveActionButtonsComponent: View {
    let onContinueAction: () -> Void
    
    var body: some View {
        Button(action: onContinueAction) {
            HStack {
                Text("Add to Calendar & Continue")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add to Calendar and Continue to Payment")
    }
}

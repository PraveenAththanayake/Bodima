import SwiftUI

// Payment action buttons component for payment processing
// Handles pay button state, loading indicators, and validation
struct PaymentActionButtonsComponent: View {
    let selectedCard: PaymentCard?
    let isProcessingPayment: Bool
    let onPayAction: () -> Void
    
    var body: some View {
        Button(action: onPayAction) {
            HStack {
                if isProcessingPayment {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }
                
                Text(isProcessingPayment ? "Processing..." : "Pay Now")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                selectedCard != nil && !isProcessingPayment ? AppColors.primary : AppColors.mutedForeground
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(selectedCard == nil || isProcessingPayment)
        .accessibilityLabel("Pay Now")
    }
}

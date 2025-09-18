import SwiftUI

// Pricing display and reservation action component
// Handles price presentation and reservation flow initiation
struct DetailPricingComponent: View {
    let habitation: EnhancedHabitationData
    let onReserveAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Primary pricing display with currency formatting
            Text("LKR \(habitation.price).00")
                .font(.title2.bold())
                .foregroundStyle(AppColors.foreground)
            
            Text("Monthly rent")
                .font(.subheadline)
                .foregroundStyle(AppColors.mutedForeground)
            
            // Primary action button for reservation initiation
            Button(action: onReserveAction) {
                Text("Reserve Now")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reserve Now")
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

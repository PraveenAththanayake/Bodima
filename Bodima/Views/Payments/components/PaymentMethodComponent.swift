import SwiftUI

// Payment method selection component with card options
// Handles payment card selection and state management
struct PaymentMethodComponent: View {
    let paymentCards: [PaymentCard]
    let selectedCard: PaymentCard?
    let onCardSelected: (PaymentCard) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Payment Method")
                .font(.headline.bold())
                .foregroundStyle(AppColors.foreground)
                .padding(.horizontal, 16)
            
            VStack(spacing: 12) {
                ForEach(paymentCards) { card in
                    PaymentCardRow(
                        card: card,
                        isSelected: selectedCard?.id == card.id
                    ) {
                        onCardSelected(card)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// Individual payment card row component with selection state
// Displays card information and selection indicator
struct PaymentCardRow: View {
    let card: PaymentCard
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Card type icon with brand colors
                Image(systemName: card.type.iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(card.type.color)
                    .frame(width: 40, height: 40)
                    .background(AppColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                
                // Card information display
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.type.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.foreground)
                    
                    Text(card.maskedCardNumber)
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                    
                    Text(card.holderName)
                        .font(.caption)
                        .foregroundStyle(AppColors.mutedForeground)
                }
                
                Spacer()
                
                // Selection indicator with animated state
                Circle()
                    .fill(isSelected ? AppColors.primary : AppColors.input)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: 2)
                    )
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? AppColors.primary : AppColors.border, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

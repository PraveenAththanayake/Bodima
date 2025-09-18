import SwiftUI

// Pricing breakdown component showing cost details and total amount
// Displays monthly rent and calculates total with clear formatting
struct ReservePricingBreakdownComponent: View {
    let monthlyRent: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Summary")
                .font(.headline.bold())
                .foregroundStyle(AppColors.foreground)
            
            VStack(spacing: 12) {
                // Monthly rent line item
                HStack {
                    Text("Monthly Rent")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.foreground)
                    Spacer()
                    Text("LKR \(String(format: "%.2f", monthlyRent))")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.foreground)
                }
                
                Divider()
                    .background(AppColors.border)
                
                // Total amount with emphasis styling
                HStack {
                    Text("Total Amount")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.foreground)
                    Spacer()
                    Text("LKR \(String(format: "%.2f", monthlyRent))")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColors.primary)
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

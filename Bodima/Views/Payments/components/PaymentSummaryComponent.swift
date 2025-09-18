import SwiftUI

// Payment summary component displaying cost breakdown and total amount
// Shows monthly rent and final total with clear formatting
struct PaymentSummaryComponent: View {
    let totalAmount: Double
    
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
                    Text("LKR \(String(format: "%.2f", totalAmount))")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.foreground)
                }
                
                Divider()
                    .background(AppColors.border)
                
                // Total amount with emphasis styling
                HStack {
                    Text("Total Amount")
                        .font(.headline.bold())
                        .foregroundStyle(AppColors.foreground)
                    
                    Spacer()
                    
                    Text("LKR \(String(format: "%.2f", totalAmount))")
                        .font(.headline.bold())
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

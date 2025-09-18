import SwiftUI

// Header component for reservation view with navigation and title
// Provides consistent navigation pattern and validates reservation state
struct ReserveHeaderComponent: View {
    let onBackTapped: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reserve")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Text("Complete your reservation")
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedForeground)
            }
            
            Spacer()
            
            Button(action: onBackTapped) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.foreground)
                    .frame(width: 44, height: 44)
                    .background(AppColors.input)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
        }
    }
}

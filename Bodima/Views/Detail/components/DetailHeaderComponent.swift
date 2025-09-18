import SwiftUI

// Navigation header with app branding and back functionality
// Provides consistent navigation experience across detail screens
struct DetailHeaderComponent: View {
    let onBackTapped: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // App branding section with hierarchical information display
            VStack(alignment: .leading, spacing: 4) {
                Text("Bodima")
                    .font(.title2.bold())
                    .foregroundStyle(AppColors.foreground)
                
                Text("Habitation Info")
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedForeground)
            }
            
            Spacer()
            
            // Circular back button with proper touch target and accessibility
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.background)
    }
}

import SwiftUI

// Header component for settings view with app icon and title
// Provides visual branding and context for settings interface
struct SettingsHeaderComponent: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(AppColors.primary)
            
            Text("App Settings")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            Text("Customize your experience")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
        }
        .padding(.top, 20)
    }
}

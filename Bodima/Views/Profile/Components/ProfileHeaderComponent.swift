import SwiftUI

// Profile header component with title and settings navigation
// Provides consistent branding and access to accessibility settings
struct ProfileHeaderComponent: View {
    var body: some View {
        VStack(spacing: 0) {
            ProfileTopBarComponent()
        }
        .background(AppColors.background)
    }
}

// Top navigation bar with profile title and settings access
// Includes hierarchical text layout and settings gear icon
struct ProfileTopBarComponent: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Profile")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                
                Text("Your Account")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
            
            NavigationLink(destination: AccessibilitySettingsView()) {
                ZStack {
                    Circle()
                        .fill(AppColors.input)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                    
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.foreground)
                }
            }
            .accessibilityLabel("Settings")
            .accessibilityHint("Navigate to accessibility settings")
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 24)
    }
}

#Preview {
    ProfileHeaderComponent()
}

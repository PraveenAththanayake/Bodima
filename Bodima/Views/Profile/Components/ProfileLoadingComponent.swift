import SwiftUI

// Loading state component for profile data fetching
// Displays centered progress indicator with descriptive text and proper theming
struct ProfileLoadingComponent: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(AppColors.primary)
            
            Text("Loading profile...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading profile data")
        .accessibilityHint("Please wait while we fetch your profile information")
    }
}

#Preview {
    ProfileLoadingComponent()
}

import SwiftUI

// Empty state component for profile data absence or errors
// Handles both error states and no-data scenarios with appropriate messaging
struct ProfileEmptyStateComponent: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            if profileViewModel.hasError {
                ProfileErrorComponent(profileViewModel: profileViewModel)
            } else {
                ProfileNoDataComponent()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

// Error state component with retry functionality
// Displays error message with visual indicators and retry action
struct ProfileErrorComponent: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.orange)
            }
            .accessibilityHidden(true)
            
            Text("Error Loading Profile")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            Text(profileViewModel.errorMessage ?? "Unknown error occurred")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                Task {
                    await retryLoadProfile()
                }
            }) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.primary)
                    .cornerRadius(20)
            }
            .accessibilityLabel("Retry loading profile")
            .accessibilityHint("Double tap to attempt loading profile data again")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Profile loading error. \(profileViewModel.errorMessage ?? "Unknown error occurred")")
    }
    
    // Retry profile loading with authentication validation
    private func retryLoadProfile() async {
        guard let userId = UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        await MainActor.run {
            profileViewModel.refreshProfile(userId: userId)
        }
    }
}

// No data state component for missing profile information
// Provides informative message when profile data is unavailable
struct ProfileNoDataComponent: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.input)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.circle")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
            .accessibilityHidden(true)
            
            Text("No Profile Data")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            Text("Your profile information is not available")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No profile data available")
    }
}

#Preview {
    ProfileEmptyStateComponent(profileViewModel: ProfileViewModel())
}

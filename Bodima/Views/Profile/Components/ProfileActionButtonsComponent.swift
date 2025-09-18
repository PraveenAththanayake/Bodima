import SwiftUI

// Profile action buttons component with edit, refresh, and sign out functionality
// Provides primary user actions with proper state management and visual feedback
struct ProfileActionButtonsComponent: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showingEditProfile = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Edit profile navigation button
            Button(action: {
                showingEditProfile = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Edit Profile")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.primary)
                .cornerRadius(12)
            }
            .accessibilityLabel("Edit Profile")
            .accessibilityHint("Opens profile editing screen")
            
            // Refresh profile data button with loading state
            Button(action: {
                Task {
                    await refreshProfile()
                }
            }) {
                HStack(spacing: 8) {
                    if profileViewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(profileViewModel.isLoading ? "Refreshing..." : "Refresh Profile")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.input)
                .cornerRadius(12)
            }
            .disabled(profileViewModel.isLoading)
            .accessibilityLabel(profileViewModel.isLoading ? "Refreshing profile" : "Refresh Profile")
            .accessibilityHint("Reloads profile data from server")
            
            // Sign out button with destructive styling
            Button(action: {
                authViewModel.signOut()
                profileViewModel.clearProfile()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red)
                .cornerRadius(12)
            }
            .accessibilityLabel("Sign Out")
            .accessibilityHint("Signs out of your account and returns to login")
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(profileViewModel: profileViewModel)
        }
    }
    
    // Refresh profile data with proper authentication handling
    private func refreshProfile() async {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        await MainActor.run {
            profileViewModel.refreshProfile(userId: userId)
        }
    }
}

#Preview {
    ProfileActionButtonsComponent(
        profileViewModel: ProfileViewModel(),
        authViewModel: AuthViewModel.shared
    )
}

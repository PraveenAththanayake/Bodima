import Foundation
import SwiftUI
import LocalAuthentication

// Main profile view orchestrating modular components and state management
// Coordinates between profile data loading, accessibility settings, and user interactions
struct ProfileView: View {
    // State management for profile data and accessibility features
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var authViewModel = AuthViewModel.shared
    @StateObject private var accessibilityViewModel: AccessibilityViewModel = AccessibilityViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ProfileHeaderComponent()
                ProfileContentComponent(profileViewModel: profileViewModel)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .onAppear {
                loadProfile()
                loadAccessibilitySettings()
            }
            .modifier(AccessibilityAwareModifier(settings: accessibilityViewModel.accessibilitySettings))
            .alert("Error", isPresented: $profileViewModel.hasError) {
                Button("OK") {
                    profileViewModel.hasError = false
                }
                Button("Retry") {
                    Task {
                        await refreshProfile()
                    }
                }
            } message: {
                Text(profileViewModel.errorMessage ?? "An error occurred")
            }
        }
    }
    
    // Load user profile data with authentication validation
    // Handles user ID retrieval from multiple sources and error management
    private func loadProfile() {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            profileViewModel.showError("User ID not found. Please login again.")
            return
        }
        
        profileViewModel.fetchUserProfile(userId: userId)
    }
    
    // Refresh profile data asynchronously with proper main actor handling
    private func refreshProfile() async {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        await MainActor.run {
            profileViewModel.refreshProfile(userId: userId)
        }
    }
    
    // Load accessibility settings from local storage and server
    // Ensures consistent accessibility experience across app sessions
    private func loadAccessibilitySettings() {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        accessibilityViewModel.loadLocalSettings()
        accessibilityViewModel.fetchAccessibilitySettings(userId: userId)
    }
}

// Profile content coordinator component managing different view states
// Handles loading, data display, and empty state transitions based on profile data availability
struct ProfileContentComponent: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        if profileViewModel.isLoading {
            ProfileLoadingComponent()
        } else if let profile = profileViewModel.userProfile {
            ProfileDataComponent(profile: profile, profileViewModel: profileViewModel)
        } else {
            ProfileEmptyStateComponent(profileViewModel: profileViewModel)
        }
    }
}

// Profile data display component with scrollable content and refresh functionality
// Orchestrates image section, details, and action buttons with pull-to-refresh support
struct ProfileDataComponent: View {
    let profile: ProfileData
    @ObservedObject var profileViewModel: ProfileViewModel
    @StateObject private var authViewModel = AuthViewModel.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProfileImageSectionComponent(profile: profile, profileViewModel: profileViewModel)
                ProfileDetailsSectionComponent(profile: profile, profileViewModel: profileViewModel)
                ProfileActionButtonsComponent(profileViewModel: profileViewModel, authViewModel: authViewModel)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .refreshable {
            await refreshProfile()
        }
    }
    
    // Refresh profile data with authentication validation
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
    ProfileView()
}


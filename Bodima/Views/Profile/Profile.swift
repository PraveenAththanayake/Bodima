import Foundation
import SwiftUI

struct ProfileView: View {
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var authViewModel = AuthViewModel.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ProfileHeaderView()
                ProfileContentView(profileViewModel: profileViewModel)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
            .onAppear {
                loadProfile()
            }
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
    
    private func loadProfile() {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            profileViewModel.showError("User ID not found. Please login again.")
            return
        }
        
        profileViewModel.fetchUserProfile(userId: userId)
    }
    
    private func refreshProfile() async {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        await MainActor.run {
            profileViewModel.refreshProfile(userId: userId)
        }
    }
}

// MARK: - Profile Header
struct ProfileHeaderView: View {
    var body: some View {
        VStack(spacing: 0) {
            ProfileTopBarView()
        }
        .background(AppColors.background)
    }
}

// MARK: - Profile Top Bar
struct ProfileTopBarView: View {
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
            
            Button(action: {
                // Add settings action here
            }) {
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
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 24)
    }
}

// MARK: - Profile Content
struct ProfileContentView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        if profileViewModel.isLoading {
            ProfileLoadingView()
        } else if let profile = profileViewModel.userProfile {
            ProfileDataView(profile: profile, profileViewModel: profileViewModel)
        } else {
            ProfileEmptyStateView(profileViewModel: profileViewModel)
        }
    }
}

// MARK: - Profile Loading View
struct ProfileLoadingView: View {
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
    }
}

// MARK: - Profile Data View
struct ProfileDataView: View {
    let profile: ProfileData
    @ObservedObject var profileViewModel: ProfileViewModel
    @StateObject private var authViewModel = AuthViewModel.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProfileImageSectionView(profile: profile, profileViewModel: profileViewModel)
                ProfileDetailsSectionView(profile: profile, profileViewModel: profileViewModel)
                ProfileActionButtonsView(profileViewModel: profileViewModel, authViewModel: authViewModel)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .refreshable {
            await refreshProfile()
        }
    }
    
    private func refreshProfile() async {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        await MainActor.run {
            profileViewModel.refreshProfile(userId: userId)
        }
    }
}

// MARK: - Profile Image Section
struct ProfileImageSectionView: View {
    let profile: ProfileData
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(AppColors.input)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(AppColors.border, lineWidth: 2)
                    )
                
                if let imageURL = profile.profileImageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } placeholder: {
                        ProfileInitialsView(profile: profile)
                    }
                } else {
                    ProfileInitialsView(profile: profile)
                }
            }
            
            // Name and Username
            VStack(spacing: 4) {
                Text(profileViewModel.displayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.foreground)
                
                Text("@\(profile.auth.username)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            // Profile Status Badge
            ProfileStatusBadge(isComplete: profileViewModel.isProfileComplete)
        }
        .padding(.top, 20)
    }
}

// MARK: - Profile Initials View
struct ProfileInitialsView: View {
    let profile: ProfileData
    
    var body: some View {
        Text(profile.auth.username.prefix(1).uppercased())
            .font(.system(size: 36, weight: .bold))
            .foregroundColor(AppColors.foreground)
    }
}

// MARK: - Profile Status Badge
struct ProfileStatusBadge: View {
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isComplete ? .green : .orange)
            
            Text(isComplete ? "Profile Complete" : "Profile Incomplete")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isComplete ? .green : .orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill((isComplete ? Color.green : Color.orange).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isComplete ? .green : .orange, lineWidth: 1)
                )
        )
    }
}

// MARK: - Profile Details Section
struct ProfileDetailsSectionView: View {
    let profile: ProfileData
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Personal Information Card
            ProfileCardView(title: "Personal Information") {
                VStack(spacing: 12) {
                    ProfileDetailRow(title: "User ID", value: profile.id ?? "Not provided")
                    
                    ProfileDetailRow(title: "Last Name", value: profile.lastName ?? "Not provided")
                    ProfileDetailRow(title: "Email", value: profile.auth.email)
                    ProfileDetailRow(title: "Phone", value: profile.phoneNumber ?? "Not provided")
                    
                    if let bio = profile.bio, !bio.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bio:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.foreground)
                            
                            Text(bio)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.mutedForeground)
                                .lineLimit(nil)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            // Address Information Card
            ProfileCardView(title: "Address Information") {
                VStack(spacing: 12) {
                    ProfileDetailRow(title: "Address", value: profileViewModel.fullAddress)
                }
            }
            
            // Account Information Card
            ProfileCardView(title: "Account Information") {
                VStack(spacing: 12) {
                    ProfileDetailRow(title: "User ID", value: profile.id)
                    ProfileDetailRow(title: "Username", value: profile.auth.username)
                    ProfileDetailRow(title: "Created", value: profileViewModel.formatDate(profile.createdAt))
                    ProfileDetailRow(title: "Last Updated", value: profileViewModel.formatDate(profile.updatedAt))
                }
            }
        }
    }
}

// MARK: - Profile Card View
struct ProfileCardView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            content
        }
        .padding(20)
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

// MARK: - Profile Detail Row
struct ProfileDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title + ":")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.foreground)
                .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
                .multilineTextAlignment(.trailing)
                .lineLimit(nil)
        }
    }
}

// MARK: - Profile Action Buttons
struct ProfileActionButtonsView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Edit Profile Button
            Button(action: {
                // Add edit profile action
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
            
            // Refresh Button
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
            
            // Sign Out Button
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
        }
    }
    
    private func refreshProfile() async {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        await MainActor.run {
            profileViewModel.refreshProfile(userId: userId)
        }
    }
}

// MARK: - Profile Empty State
struct ProfileEmptyStateView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            if profileViewModel.hasError {
                ProfileErrorView(profileViewModel: profileViewModel)
            } else {
                ProfileNoDataView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

// MARK: - Profile Error View
struct ProfileErrorView: View {
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
        }
    }
    
    private func retryLoadProfile() async {
        guard let userId = UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        await MainActor.run {
            profileViewModel.refreshProfile(userId: userId)
        }
    }
}

// MARK: - Profile No Data View
struct ProfileNoDataView: View {
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
            
            Text("No Profile Data")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            Text("Your profile information is not available")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    ProfileView()
}


import Foundation
import SwiftUI
import LocalAuthentication

struct ProfileView: View {
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var authViewModel = AuthViewModel.shared
    @StateObject private var accessibilityViewModel: AccessibilityViewModel = AccessibilityViewModel()
    
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
    
    private func loadAccessibilitySettings() {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        accessibilityViewModel.loadLocalSettings()
        accessibilityViewModel.fetchAccessibilitySettings(userId: userId)
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
            
            // Security Settings Card
            ProfileSecuritySettingsView()
            
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
    @State private var showingEditProfile = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Edit Profile Button
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
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(profileViewModel: profileViewModel)
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

// MARK: - Profile Security Settings
struct ProfileSecuritySettingsView: View {
    @StateObject private var biometricManager = BiometricManager.shared
    @StateObject private var authViewModel = AuthViewModel.shared
    @State private var showingBiometricAlert = false
    @State private var biometricAlertMessage = ""
    @State private var showingConfirmationAlert = false
    
    var body: some View {
        ProfileCardView(title: "Security Settings") {
            VStack(spacing: 16) {
                if biometricManager.isBiometricAvailable {
                    BiometricToggleRow(
                        biometricManager: biometricManager,
                        showingAlert: $showingBiometricAlert,
                        alertMessage: $biometricAlertMessage,
                        showingConfirmation: $showingConfirmationAlert
                    )
                } else {
                    BiometricUnavailableRow(biometricManager: biometricManager)
                }
                
                Divider()
                    .background(AppColors.border)
                
                // Additional security settings can be added here
                SecurityInfoRow()
            }
        }
        .alert("Biometric Authentication", isPresented: $showingBiometricAlert) {
            Button("OK") {
                showingBiometricAlert = false
            }
        } message: {
            Text(biometricAlertMessage)
        }
        .alert("Disable Biometric Authentication?", isPresented: $showingConfirmationAlert) {
            Button("Cancel", role: .cancel) {
                showingConfirmationAlert = false
            }
            Button("Disable", role: .destructive) {
                disableBiometric()
                showingConfirmationAlert = false
            }
        } message: {
            Text("This will remove your saved biometric login. You'll need to enable it again and sign in with your password.")
        }
    }
    
    private func toggleBiometric() {
        if biometricManager.isBiometricEnabled {
            showingConfirmationAlert = true
        } else {
            enableBiometric()
        }
    }
    
    private func enableBiometric() {
        // Don't try to authenticate with biometrics when enabling for the first time
        // Just store the current token directly
        guard let token = authViewModel.jwtToken, !token.isEmpty else {
            biometricAlertMessage = "No valid session found. Please sign in again."
            showingBiometricAlert = true
            return
        }
        
        Task {
            do {
                let success = biometricManager.storeBiometricToken(token)
                
                await MainActor.run {
                    if success {
                        biometricManager.setBiometricEnabled(true)
                        biometricAlertMessage = "\(biometricManager.getBiometricTypeString()) has been enabled successfully!"
                    } else {
                        biometricAlertMessage = "Failed to store authentication data. Please try again."
                    }
                    showingBiometricAlert = true
                }
            } catch {
                await MainActor.run {
                    biometricAlertMessage = "Error enabling biometric authentication: \(error.localizedDescription)"
                    showingBiometricAlert = true
                }
            }
        }
    }
    
    private func disableBiometric() {
        biometricManager.setBiometricEnabled(false)
        biometricManager.clearBiometricToken()
    }
}

// MARK: - Biometric Toggle Row
struct BiometricToggleRow: View {
    @ObservedObject var biometricManager: BiometricManager
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    @Binding var showingConfirmation: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Biometric Icon
            ZStack {
                Circle()
                    .fill(biometricManager.isBiometricEnabled ? AppColors.primary.opacity(0.1) : AppColors.input)
                    .frame(width: 40, height: 40)
                
                Image(systemName: biometricManager.getBiometricIcon())
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(biometricManager.isBiometricEnabled ? AppColors.primary : AppColors.mutedForeground)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                Text(biometricManager.getBiometricTypeString())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                Text(biometricManager.isBiometricEnabled ? "Enabled" : "Sign in with \(biometricManager.getBiometricTypeString().lowercased())")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
            
            // Toggle Switch
            Toggle("", isOn: .init(
                get: { biometricManager.isBiometricEnabled },
                set: { _ in toggleBiometric() }
            ))
            .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
        }
    }
    
    private func toggleBiometric() {
        if biometricManager.isBiometricEnabled {
            showingConfirmation = true
        } else {
            enableBiometric()
        }
    }
    
    private func enableBiometric() {
        guard let token = AuthViewModel.shared.jwtToken, !token.isEmpty else {
            alertMessage = "No valid session found. Please sign in again."
            showingAlert = true
            return
        }
        
        Task {
            do {
                let success = biometricManager.storeBiometricToken(token)
                
                await MainActor.run {
                    if success {
                        biometricManager.setBiometricEnabled(true)
                        alertMessage = "\(biometricManager.getBiometricTypeString()) has been enabled successfully!"
                    } else {
                        alertMessage = "Failed to store authentication data. Please try again."
                    }
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Error enabling biometric authentication: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Biometric Unavailable Row
struct BiometricUnavailableRow: View {
    @ObservedObject var biometricManager: BiometricManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Warning Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                Text("Biometric Authentication")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                Text("Not available on this device")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
        }
    }
}

// MARK: - Security Info Row
struct SecurityInfoRow: View {
    var body: some View {
        HStack(spacing: 12) {
            // Info Icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.primary)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                Text("Security Information")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                Text("Your biometric data is stored securely on your device and never shared")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}


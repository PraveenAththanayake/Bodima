import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProfile: ProfileData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    // Create profile specific states
    @Published var isCreatingProfile = false
    @Published var profileCreationSuccess = false
    @Published var profileCreationMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    // MARK: - Fetch User Profile
    func fetchUserProfile(userId: String) {
        guard !userId.isEmpty else {
            showError("User ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showError("Authentication token not found. Please login again.")
            return
        }
        
        isLoading = true
        clearError()
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        networkManager.requestWithHeaders(
            endpoint: .getUserProfile(userId: userId),
            headers: headers,
            responseType: ProfileResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - ProfileResponse success: \(response.success)")
                    print("🔍 DEBUG - ProfileResponse message: \(response.message ?? "")")
                    print("🔍 DEBUG - ProfileResponse data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.userProfile = response.data
                        print("✅ Profile fetched successfully")
                    } else {
                        self?.showError(response.message ?? "Unknown error occurred")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Network error: \(error)")
                    self?.handleNetworkError(error)
                }
            }
        }
    }
    
    // MARK: - Create Profile
    func createProfile(
        userId: String,
        firstName: String,
        lastName: String,
        profileImageURL: String,
        bio: String,
        phoneNumber: String,
        addressNo: String,
        addressLine1: String,
        addressLine2: String,
        city: String,
        district: String
    ) {
        guard !userId.isEmpty else {
            showProfileCreationError("User ID is required")
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            showProfileCreationError("Authentication token not found. Please login again.")
            return
        }
        
        isCreatingProfile = true
        clearProfileCreationError()
        
        let createProfileRequest = CreateProfileRequest(
            userId: userId,
            firstName: firstName,
            lastName: lastName,
            profileImageURL: profileImageURL,
            bio: bio,
            phoneNumber: phoneNumber,
            addressNo: addressNo,
            addressLine1: addressLine1,
            addressLine2: addressLine2,
            city: city,
            district: district
        )
        
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
        
        // Use the correct response type for create profile
        networkManager.requestWithHeaders(
            endpoint: .createProfile(userId: userId),
            body: createProfileRequest,
            headers: headers,
            responseType: CreateProfileResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isCreatingProfile = false
                
                switch result {
                case .success(let response):
                    print("🔍 DEBUG - CreateProfile success: \(response.success)")
                    print("🔍 DEBUG - CreateProfile message: \(response.message)")
                    print("🔍 DEBUG - CreateProfile data: \(String(describing: response.data))")
                    
                    if response.success {
                        self?.profileCreationSuccess = true
                        self?.profileCreationMessage = response.message
                        print("✅ Profile created successfully")
                        
                        // Update AuthViewModel to reflect profile completion
                        self?.updateAuthViewModelAfterProfileCreation(
                            firstName: firstName,
                            lastName: lastName,
                            bio: bio,
                            phoneNumber: phoneNumber,
                            addressNo: addressNo,
                            addressLine1: addressLine1,
                            addressLine2: addressLine2,
                            city: city,
                            district: district,
                            profileImageURL: profileImageURL
                        )
                        
                        // Optionally store the created profile data
                        if let createdProfile = response.data {
                            print("✅ Created profile data: \(createdProfile)")
                        }
                    } else {
                        self?.showProfileCreationError(response.message)
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG - Create profile error: \(error)")
                    self?.handleProfileCreationError(error)
                }
            }
        }
    }
    
    // MARK: - Update AuthViewModel After Profile Creation
    private func updateAuthViewModelAfterProfileCreation(
        firstName: String,
        lastName: String,
        bio: String,
        phoneNumber: String,
        addressNo: String,
        addressLine1: String,
        addressLine2: String,
        city: String,
        district: String,
        profileImageURL: String
    ) {
        let authViewModel = AuthViewModel.shared
        
        // Update the current user with profile completion
        if var currentUser = authViewModel.currentUser {
            currentUser.hasCompletedProfile = true
            currentUser.firstName = firstName
            currentUser.lastName = lastName
            currentUser.bio = bio
            currentUser.phoneNumber = phoneNumber
            currentUser.addressNo = addressNo
            currentUser.addressLine1 = addressLine1
            currentUser.addressLine2 = addressLine2
            currentUser.city = city
            currentUser.district = district
            currentUser.profileImageURL = profileImageURL
            
            // Update the AuthViewModel
            authViewModel.updateCurrentUser(currentUser)
            
            // Mark profile as available
            authViewModel.isUserProfileAvailable = true
            authViewModel.profileCheckCompleted = true
            
            // Save profile availability to storage
            UserDefaultsManager.shared.saveUserProfileAvailability(true)
            
            print("✅ AuthViewModel updated with profile completion")
        }
    }
    
    // MARK: - Refresh Profile
    func refreshProfile(userId: String) {
        fetchUserProfile(userId: userId)
    }
    
    // MARK: - Error Handling
    private func handleNetworkError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showError("Session expired. Please login again.")
                UserDefaults.standard.removeObject(forKey: "auth_token")
                
            case .clientError(let message):
                showError(message)
                
            case .serverError(let message):
                showError("Server error: \(message)")
                
            default:
                showError(networkError.localizedDescription)
            }
        } else {
            showError("Network error: \(error.localizedDescription)")
        }
    }
    
    private func handleProfileCreationError(_ error: Error) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                showProfileCreationError("Session expired. Please login again.")
                UserDefaults.standard.removeObject(forKey: "auth_token")
                
            case .clientError(let message):
                showProfileCreationError(message)
                
            case .serverError(let message):
                showProfileCreationError("Server error: \(message)")
                
            default:
                showProfileCreationError(networkError.localizedDescription)
            }
        } else {
            showProfileCreationError("Network error: \(error.localizedDescription)")
        }
    }
    
    func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ Profile Error: \(message)")
    }
    
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
    
    func showProfileCreationError(_ message: String) {
        profileCreationMessage = message
        profileCreationSuccess = false
        print("❌ Profile Creation Error: \(message)")
    }
    
    private func clearProfileCreationError() {
        profileCreationMessage = nil
        profileCreationSuccess = false
    }
    
    // MARK: - Computed Properties
    var displayName: String {
        guard let profile = userProfile else { return "Unknown User" }
        
        if let firstName = profile.firstName, !firstName.isEmpty,
           let lastName = profile.lastName, !lastName.isEmpty {
            return "\(firstName) \(lastName)"
        }
        
        return profile.auth.username
    }
    
    var fullAddress: String {
        guard let profile = userProfile else { return "No address available" }
        
        var addressComponents: [String] = []
        
        if let addressNo = profile.addressNo, !addressNo.isEmpty {
            addressComponents.append(addressNo)
        }
        if let addressLine1 = profile.addressLine1, !addressLine1.isEmpty {
            addressComponents.append(addressLine1)
        }
        if let addressLine2 = profile.addressLine2, !addressLine2.isEmpty {
            addressComponents.append(addressLine2)
        }
        if let city = profile.city, !city.isEmpty {
            addressComponents.append(city)
        }
        if let district = profile.district, !district.isEmpty {
            addressComponents.append(district)
        }
        
        return addressComponents.isEmpty ? "No address available" : addressComponents.joined(separator: ", ")
    }
    
    var profileImageURL: String? {
        return userProfile?.profileImageURL
    }
    
    var isProfileComplete: Bool {
        guard let profile = userProfile else { return false }
        
        return profile.firstName != nil && !profile.firstName!.isEmpty &&
               profile.lastName != nil && !profile.lastName!.isEmpty &&
               profile.phoneNumber != nil && !profile.phoneNumber!.isEmpty &&
               profile.addressNo != nil && !profile.addressNo!.isEmpty &&
               profile.addressLine1 != nil && !profile.addressLine1!.isEmpty &&
               profile.city != nil && !profile.city!.isEmpty &&
               profile.district != nil && !profile.district!.isEmpty
    }
    
    // MARK: - Utility Methods
    func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "N/A" }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    // MARK: - Clear Data
    func clearProfile() {
        userProfile = nil
        clearError()
        clearProfileCreationError()
    }
    
    // MARK: - Reset Profile Creation State
    func resetProfileCreationState() {
        isCreatingProfile = false
        profileCreationSuccess = false
        profileCreationMessage = nil
    }
}

import Foundation

/**
 * ProfileViewModel manages user profile operations for the Bodima application.
 * Handles profile creation, fetching, updating, and provides comprehensive state management
 * for profile-related UI components with integration to the authentication system.
 * 
 * Features:
 * - Complete profile lifecycle management (create, read, update)
 * - Authentication integration with AuthViewModel synchronization
 * - Comprehensive validation and error handling
 * - Real-time state updates for responsive UI
 * - Profile completeness validation and computed properties
 * - Address formatting and display name generation
 */
@MainActor
class ProfileViewModel: ObservableObject {
    
    /**
     * Published properties for reactive UI updates and state management.
     */
    @Published var userProfile: ProfileData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
    /**
     * Profile creation specific state properties.
     */
    @Published var isCreatingProfile = false
    @Published var profileCreationSuccess = false
    @Published var profileCreationMessage: String?
    
    /**
     * Network manager instance for API communication.
     */
    private let networkManager = NetworkManager.shared
    private let profileCache = ProfileCacheRepository.shared
    private var lastRequestedUserId: String?
    
    /**
     * Core profile data management methods.
     */
    
    /**
     * Fetches user profile data for the specified user ID.
     * Implements proper authentication validation and comprehensive error handling.
     * Updates UI state throughout the request lifecycle.
     * 
     * @param userId The unique identifier of the user whose profile to fetch
     */
    func fetchUserProfile(userId: String) {
        guard validateUserId(userId) else { return }

        prepareProfileFetch()
        // Prefill from cache for better UX and offline support
        if let cached = profileCache.fetch(userId: userId) {
            self.userProfile = cached
        }
        lastRequestedUserId = userId

        // If we don't have a token, stop after prefill
        guard let token = validateAuthToken() else { return }

        let headers = buildAuthHeaders(token: token)
        
        networkManager.requestWithHeaders(
            endpoint: .getUserProfile(userId: userId),
            headers: headers,
            responseType: ProfileResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleFetchProfileResponse(result)
            }
        }
    }
    
    /**
     * Creates a new user profile with comprehensive profile information.
     * Handles profile creation with authentication validation and AuthViewModel synchronization.
     * Updates authentication state upon successful profile creation.
     * 
     * @param userId The unique identifier of the user
     * @param firstName User's first name
     * @param lastName User's last name
     * @param profileImageURL URL for the user's profile image
     * @param bio User's biographical information
     * @param phoneNumber User's contact phone number
     * @param addressNo Address number/house number
     * @param addressLine1 Primary address line
     * @param addressLine2 Secondary address line
     * @param city City of residence
     * @param district District/region of residence
     */
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
        guard validateUserId(userId) else {
            showProfileCreationError("User ID is required")
            return
        }
        
        guard let token = validateAuthToken() else {
            showProfileCreationError("Authentication token not found. Please login again.")
            return
        }
        
        prepareProfileCreation()
        
        let createProfileRequest = buildCreateProfileRequest(
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
        
        let headers = buildAuthHeaders(token: token)
        
        processProfileCreation(
            request: createProfileRequest,
            headers: headers,
            userId: userId,
            profileData: (firstName, lastName, bio, phoneNumber, addressNo, addressLine1, addressLine2, city, district, profileImageURL)
        )
    }
    
    
    
    /**
     * Updates profile information with comprehensive validation and state management.
     * Provides completion handler for external flow control and error handling.
     * 
     * @param userId The unique identifier of the user
     * @param firstName Updated first name
     * @param lastName Updated last name
     * @param profileImageURL Updated profile image URL
     * @param bio Updated biographical information
     * @param phoneNumber Updated contact phone number
     * @param addressNo Updated address number/house number
     * @param addressLine1 Updated primary address line
     * @param addressLine2 Updated secondary address line
     * @param city Updated city of residence
     * @param district Updated district/region of residence
     * @param completion Completion handler with success status and optional message
     */
    
    func updateProfile(
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
        district: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard validateUserId(userId) else {
            completion(false, "User ID is required")
            return
        }
        
        guard let token = validateAuthToken() else {
            completion(false, "Authentication token not found. Please login again.")
            return
        }
        
        let updateProfileRequest = buildUpdateProfileRequest(
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
        
        let headers = buildAuthHeaders(token: token)
        
        processProfileUpdate(
            request: updateProfileRequest,
            headers: headers,
            userId: userId,
            completion: completion
        )
    }
    
    /**
     * Refreshes the current user profile by re-fetching data from the server.
     * Convenience method for manual refresh operations.
     * 
     * @param userId The unique identifier of the user whose profile to refresh
     */
    func refreshProfile(userId: String) {
        fetchUserProfile(userId: userId)
    }
    
    /**
     * Private helper methods for internal profile management operations.
     */
    
    /**
     * Validates user ID parameter.
     * 
     * @param userId The user ID to validate
     * @return True if valid, false otherwise
     */
    private func validateUserId(_ userId: String) -> Bool {
        return !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /**
     * Validates and retrieves authentication token.
     * 
     * @return Authentication token if valid, nil otherwise
     */
    private func validateAuthToken() -> String? {
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    /**
     * Builds authentication headers for API requests.
     * 
     * @param token The authentication token
     * @return Dictionary of headers for API requests
     */
    private func buildAuthHeaders(token: String) -> [String: String] {
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
    }
    
    /**
     * Prepares state for profile fetch operations.
     */
    private func prepareProfileFetch() {
        isLoading = true
        clearError()
    }
    
    /**
     * Prepares state for profile creation operations.
     */
    private func prepareProfileCreation() {
        isCreatingProfile = true
        clearProfileCreationError()
    }
    
    /**
     * Builds create profile request object.
     */
    private func buildCreateProfileRequest(
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
    ) -> CreateProfileRequest {
        return CreateProfileRequest(
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
    }
    
    /**
     * Builds update profile request object.
     */
    private func buildUpdateProfileRequest(
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
    ) -> UpdateProfileRequest {
        return UpdateProfileRequest(
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
    }
    
    /**
     * Processes profile creation through network manager.
     */
    private func processProfileCreation(
        request: CreateProfileRequest,
        headers: [String: String],
        userId: String,
        profileData: (String, String, String, String, String, String, String, String, String, String)
    ) {
        networkManager.requestWithHeaders(
            endpoint: .createProfile(userId: userId),
            body: request,
            headers: headers,
            responseType: CreateProfileResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleCreateProfileResponse(result, profileData: profileData)
            }
        }
    }
    
    /**
     * Processes profile update through network manager.
     */
    private func processProfileUpdate(
        request: UpdateProfileRequest,
        headers: [String: String],
        userId: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        networkManager.requestWithHeaders(
            endpoint: .updateProfile(userId: userId),
            body: request,
            headers: headers,
            responseType: UpdateProfileResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleUpdateProfileResponse(result, userId: userId, completion: completion)
            }
        }
    }
    
    /**
     * Response handling methods for API operations.
     */
    
    /**
     * Handles fetch profile API response.
     */
    private func handleFetchProfileResponse(_ result: Result<ProfileResponse, Error>) {
        isLoading = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - ProfileResponse success: \(response.success)")
            print("🔍 DEBUG - ProfileResponse message: \(response.message ?? "")")
            print("🔍 DEBUG - ProfileResponse data: \(String(describing: response.data))")
            
            if response.success {
                userProfile = response.data
                if let data = response.data {
                    // Save to offline cache
                    profileCache.save(profile: data)
                }
                print("✅ Profile fetched successfully")
            } else {
                showError(response.message ?? "Unknown error occurred")
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Network error: \(error)")
            // Fallback to cached profile when offline or on error
            if let userId = lastRequestedUserId, let cached = profileCache.fetch(userId: userId) {
                self.userProfile = cached
                // Do not surface an error if we have valid cached data
                self.clearError()
            } else {
                handleNetworkError(error)
            }
        }
    }
    
    /**
     * Handles create profile API response.
     */
    private func handleCreateProfileResponse(
        _ result: Result<CreateProfileResponse, Error>,
        profileData: (String, String, String, String, String, String, String, String, String, String)
    ) {
        isCreatingProfile = false
        
        switch result {
        case .success(let response):
            print("🔍 DEBUG - CreateProfile success: \(response.success)")
            print("🔍 DEBUG - CreateProfile message: \(response.message)")
            print("🔍 DEBUG - CreateProfile data: \(String(describing: response.data))")
            
            if response.success {
                profileCreationSuccess = true
                profileCreationMessage = response.message
                print("✅ Profile created successfully")
                
                updateAuthViewModelAfterProfileCreation(
                    firstName: profileData.0,
                    lastName: profileData.1,
                    bio: profileData.2,
                    phoneNumber: profileData.3,
                    addressNo: profileData.4,
                    addressLine1: profileData.5,
                    addressLine2: profileData.6,
                    city: profileData.7,
                    district: profileData.8,
                    profileImageURL: profileData.9
                )
                
                if let createdProfile = response.data {
                    print("✅ Created profile data: \(createdProfile)")
                    // Build ProfileData from CreatedProfileData for caching
                    let authVM = AuthViewModel.shared
                    let currentUser = authVM.currentUser
                    let authData = AuthData(
                        id: currentUser?.id ?? createdProfile.auth,
                        email: currentUser?.email ?? "",
                        username: currentUser?.username ?? "",
                        createdAt: currentUser?.createdAt ?? "",
                        updatedAt: currentUser?.updatedAt ?? ""
                    )
                    let normalized = ProfileData(
                        id: createdProfile.id,
                        auth: authData,
                        firstName: createdProfile.firstName,
                        lastName: createdProfile.lastName,
                        bio: createdProfile.bio,
                        phoneNumber: createdProfile.phoneNumber,
                        addressNo: createdProfile.addressNo,
                        addressLine1: createdProfile.addressLine1,
                        addressLine2: createdProfile.addressLine2,
                        city: createdProfile.city,
                        district: createdProfile.district,
                        profileImageURL: createdProfile.profileImageURL,
                        createdAt: createdProfile.createdAt,
                        updatedAt: createdProfile.updatedAt,
                        profileImageUrl: createdProfile.profileImageURL,
                        accessibilitySettings: nil
                    )
                    // Update in-memory and cache
                    self.userProfile = normalized
                    profileCache.save(profile: normalized)
                }
            } else {
                showProfileCreationError(response.message)
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Create profile error: \(error)")
            handleProfileCreationError(error)
        }
    }
    
    /**
     * Handles update profile API response.
     */
    private func handleUpdateProfileResponse(
        _ result: Result<UpdateProfileResponse, Error>,
        userId: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        switch result {
        case .success(let response):
            print("🔍 DEBUG - UpdateProfile success: \(response.success)")
            print("🔍 DEBUG - UpdateProfile message: \(response.message)")
            
            if response.success {
                print("✅ Profile updated successfully")
                fetchUserProfile(userId: userId)
                completion(true, response.message)
            } else {
                completion(false, response.message)
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Update profile error: \(error)")
            handleUpdateProfileNetworkError(error, completion: completion)
        }
    }
    
    /**
     * Updates AuthViewModel after successful profile creation.
     * Synchronizes profile completion state with authentication system.
     */
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
            
            authViewModel.updateCurrentUser(currentUser)
            authViewModel.isUserProfileAvailable = true
            authViewModel.profileCheckCompleted = true
            
            UserDefaultsManager.shared.saveUserProfileAvailability(true)
            
            print("✅ AuthViewModel updated with profile completion")
        }
    }
    
    /**
     * Error handling and message management methods.
     */
    
    /**
     * Handles network errors for profile operations.
     */
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
    
    /**
     * Handles network errors for profile creation operations.
     */
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
    
    /**
     * Handles network errors for profile update operations.
     */
    private func handleUpdateProfileNetworkError(_ error: Error, completion: @escaping (Bool, String?) -> Void) {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized:
                completion(false, "Session expired. Please login again.")
            case .clientError(let message):
                completion(false, message)
            case .serverError(let message):
                completion(false, "Server error: \(message)")
            default:
                completion(false, networkError.localizedDescription)
            }
        } else {
            completion(false, "Network error: \(error.localizedDescription)")
        }
    }
    
    /**
     * Displays error messages for profile operations.
     */
    func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ Profile Error: \(message)")
    }
    
    /**
     * Clears error state for profile operations.
     */
    private func clearError() {
        errorMessage = nil
        hasError = false
    }
    
    /**
     * Displays error messages for profile creation operations.
     */
    func showProfileCreationError(_ message: String) {
        profileCreationMessage = message
        profileCreationSuccess = false
        print("❌ Profile Creation Error: \(message)")
    }
    
    /**
     * Clears error state for profile creation operations.
     */
    private func clearProfileCreationError() {
        profileCreationMessage = nil
        profileCreationSuccess = false
    }
    
    /**
     * Computed properties for profile analysis and UI presentation.
     */
    
    /**
     * Generates a display-friendly name from profile data.
     * Falls back to username if first/last names are not available.
     * 
     * @return Formatted display name or fallback identifier
     */
    var displayName: String {
        guard let profile = userProfile else { return "Unknown User" }
        
        if let firstName = profile.firstName, !firstName.isEmpty,
           let lastName = profile.lastName, !lastName.isEmpty {
            return "\(firstName) \(lastName)"
        }
        
        return profile.auth.username
    }
    
    /**
     * Constructs a complete address string from profile address components.
     * Combines all available address fields into a readable format.
     * 
     * @return Formatted address string or fallback message
     */
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
    
    /**
     * Provides access to the user's profile image URL.
     * 
     * @return Profile image URL if available, nil otherwise
     */
    var profileImageURL: String? {
        return userProfile?.profileImageURL
    }
    
    /**
     * Determines if the user profile has all required fields completed.
     * Validates essential profile information for completeness.
     * 
     * @return True if profile is complete, false otherwise
     */
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
    
    /**
     * Utility methods for profile management and data formatting.
     */
    
    /**
     * Formats ISO8601 date strings into user-friendly display format.
     * Handles various date string formats with fallback options.
     * 
     * @param dateString The ISO8601 formatted date string to format
     * @return Human-readable date and time string
     */
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
    
    /**
     * Clears all profile data and resets error states.
     * Used for logout operations and data cleanup.
     */
    func clearProfile() {
        userProfile = nil
        clearError()
        clearProfileCreationError()
    }
    
    /**
     * Resets profile creation state to initial values.
     * Clears creation flags and messages for new operations.
     */
    func resetProfileCreationState() {
        isCreatingProfile = false
        profileCreationSuccess = false
        profileCreationMessage = nil
    }
}

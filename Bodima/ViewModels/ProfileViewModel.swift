import Foundation


@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProfile: ProfileData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    
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
                    print("🔍 DEBUG - ProfileResponse message: \(response.message)")
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
    
    // MARK: - Manual JSON Parsing (for debugging)
    private func parseProfileData(_ data: [String: Any]) {
        guard let profileId = data["_id"] as? String else {
            showError("Profile ID not found")
            return
        }
        
        guard let authData = data["auth"] as? [String: Any],
              let authId = authData["_id"] as? String,
              let email = authData["email"] as? String,
              let username = authData["username"] as? String,
              let authCreatedAt = authData["createdAt"] as? String,
              let authUpdatedAt = authData["updatedAt"] as? String else {
            showError("Auth data is incomplete")
            return
        }
        
        let auth = AuthData(
            id: authId,
            email: email,
            username: username,
            createdAt: authCreatedAt,
            updatedAt: authUpdatedAt
        )
        
        let profile = ProfileData(
            id: profileId,
            auth: auth,
            firstName: data["firstName"] as? String,
            lastName: data["lastName"] as? String,
            bio: data["bio"] as? String,
            phoneNumber: data["phoneNumber"] as? String,
            addressNo: data["addressNo"] as? String,
            addressLine1: data["addressLine1"] as? String,
            addressLine2: data["addressLine2"] as? String,
            city: data["city"] as? String,
            district: data["district"] as? String,
            profileImageURL: data["profileImageURL"] as? String,
            createdAt: data["createdAt"] as? String,
            updatedAt: data["updatedAt"] as? String,
            profileImageUrl: data["profileImageUrl"] as? String
        )
        
        self.userProfile = profile
        print("✅ Profile parsed successfully")
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
    
    func showError(_ message: String) {
        errorMessage = message
        hasError = true
        print("❌ Profile Error: \(message)")
    }
    
    private func clearError() {
        errorMessage = nil
        hasError = false
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
    }
}

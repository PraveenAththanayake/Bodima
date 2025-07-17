import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    
    static let shared = AuthViewModel()
    
    @Published var authState: AuthState = .idle
    @Published var isLoading = false
    @Published var alertMessage: AlertMessage?
    @Published var currentUser: User?
    @Published var jwtToken: String?
    @Published var isUserProfileAvailable = false
    @Published var profileCheckCompleted = false
    
    private let networkManager: NetworkManager
    private let storageManager: UserDefaultsManager
    private let validator: AuthValidator
    private let imageProcessor: ImageProcessor
    
    private init(
        networkManager: NetworkManager = NetworkManager.shared,
        storageManager: UserDefaultsManager = UserDefaultsManager.shared,
        validator: AuthValidator = AuthValidator(),
        imageProcessor: ImageProcessor = ImageProcessor()
    ) {
        self.networkManager = networkManager
        self.storageManager = storageManager
        self.validator = validator
        self.imageProcessor = imageProcessor
        
        checkAuthStatus()
    }
    
    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }
    
    var isUnauthenticated: Bool {
        if case .unauthenticated = authState { return true }
        return false
    }
    
    var hasAlert: Bool {
        alertMessage != nil
    }
    
    var needsProfileCompletion: Bool {
        guard case .authenticated = authState else { return false }
        guard let user = currentUser else { return false }
        if !profileCheckCompleted { return false }
        if isUserProfileAvailable { return false }
        if user.hasCompletedProfile == true { return false }
        
        let hasFirstAndLastName = user.firstName != nil && !user.firstName!.isEmpty &&
                                  user.lastName != nil && !user.lastName!.isEmpty
        
        let hasFullNameWithSpace = user.fullName != nil && !user.fullName!.isEmpty &&
                                   user.fullName!.contains(" ")
        
        if hasFirstAndLastName || hasFullNameWithSpace {
            var updatedUser = user
            updatedUser.hasCompletedProfile = true
            updateCurrentUser(updatedUser)
            return false
        }
        
        return true
    }
    
    var hasValidToken: Bool {
        return jwtToken != nil && !jwtToken!.isEmpty
    }
    
    private func checkAuthStatus() {
        profileCheckCompleted = false
        
        if let user = storageManager.getUser(),
           let token = storageManager.getToken() {
            currentUser = user
            jwtToken = token
            
            let storedProfileAvailability = storageManager.getUserProfileAvailability()
            isUserProfileAvailable = storedProfileAvailability
            
            authState = .authenticated(user)
            checkProfileCompletionFromServer()
        } else {
            authState = .unauthenticated
            jwtToken = nil
            isUserProfileAvailable = false
            profileCheckCompleted = true
        }
    }
    
    func checkProfileCompletionFromServer() {
        guard let userId = currentUser?.id,
              let token = jwtToken else {
            profileCheckCompleted = true
            return
        }
        
        let endpoint = APIEndpoint.getUserProfile(userId: userId)
        let headers = ["Authorization": "Bearer \(token)"]
        
        networkManager.requestWithHeaders(
            endpoint: endpoint,
            body: nil as String?,
            headers: headers,
            responseType: ProfileResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleProfileCheckResponse(result)
            }
        }
    }

    private func handleProfileCheckResponse(_ result: Result<ProfileResponse, Error>) {
        profileCheckCompleted = true
        
        switch result {
        case .success(let response):
            if response.success, let profileData = response.data {
                isUserProfileAvailable = true
                storageManager.saveUserProfileAvailability(true)
                
                if var user = currentUser {
                    // Update user with all profile data
                    user.hasCompletedProfile = true
                    user.firstName = profileData.firstName
                    user.lastName = profileData.lastName
                    user.bio = profileData.bio
                    user.phoneNumber = profileData.phoneNumber
                    user.addressNo = profileData.addressNo
                    user.addressLine1 = profileData.addressLine1
                    user.addressLine2 = profileData.addressLine2
                    user.city = profileData.city
                    user.district = profileData.district
                    user.profileImageURL = profileData.profileImageURL
                    user.createdAt = profileData.createdAt
                    user.updatedAt = profileData.updatedAt
                    
                    // Update email and username from auth data if available
                    user.email = profileData.auth.email
                    user.username = profileData.auth.username
                    user.id = profileData.id
                    
                    updateCurrentUser(user)
                }
            } else {
                isUserProfileAvailable = false
                storageManager.saveUserProfileAvailability(false)
                if var user = currentUser {
                    user.hasCompletedProfile = false
                    updateCurrentUser(user)
                }
            }
        case .failure(let error):
            let errorString = error.localizedDescription
            
            if errorString.contains("resource exceeds maximum size") {
                isUserProfileAvailable = true
                storageManager.saveUserProfileAvailability(true)
                if var user = currentUser {
                    user.hasCompletedProfile = true
                    updateCurrentUser(user)
                }
            } else {
                isUserProfileAvailable = false
                storageManager.saveUserProfileAvailability(false)
                if var user = currentUser {
                    user.hasCompletedProfile = false
                    updateCurrentUser(user)
                }
            }
        }
    }

    // Also update the handleProfileResponse method for create profile
    private func handleProfileResponse(_ result: Result<ProfileResponse, Error>) {
        switch result {
        case .success(let response):
            if response.success {
                isUserProfileAvailable = true
                storageManager.saveUserProfileAvailability(true)
                
                if var user = currentUser {
                    user.hasCompletedProfile = true
                    
                    if let profileData = response.data {
                        // Update user with all profile data
                        user.firstName = profileData.firstName
                        user.lastName = profileData.lastName
                        user.bio = profileData.bio
                        user.phoneNumber = profileData.phoneNumber
                        user.addressNo = profileData.addressNo
                        user.addressLine1 = profileData.addressLine1
                        user.addressLine2 = profileData.addressLine2
                        user.city = profileData.city
                        user.district = profileData.district
                        user.profileImageURL = profileData.profileImageURL
                        user.createdAt = profileData.createdAt
                        user.updatedAt = profileData.updatedAt
                        
                        // Update email and username from auth data if available
                        user.email = profileData.auth.email
                        user.username = profileData.auth.username
                        user.id = profileData.id
                    }
                    
                    updateCurrentUser(user)
                }
                showAlert(.success("Profile created successfully"))
            } else {
                if let message = response.message {
                    showAlert(.error(message))
                } else {
                    showAlert(.error("Profile creation failed"))
                }
            }
            
        case .failure(let error):
            let errorString = error.localizedDescription
            if errorString.contains("User profile already exists") {
                isUserProfileAvailable = true
                storageManager.saveUserProfileAvailability(true)
                if var user = currentUser {
                    user.hasCompletedProfile = true
                    updateCurrentUser(user)
                }
                showAlert(.info("Profile already exists. Proceeding to main app."))
            } else {
                handleNetworkError(error)
            }
        }
    }

    // Add a method to refresh profile data
    func refreshProfile() {
        checkProfileCompletionFromServer()
    }
    
    func signIn(email: String, password: String, rememberMe: Bool) {
        guard validator.validateSignInInput(email: email, password: password) else {
            showAlert(.error(validator.lastError))
            return
        }
        
        setLoading(true)
        
        let request = LoginRequest(
            email: email,
            password: password,
            rememberMe: rememberMe
        )
        
        performAuthRequest(endpoint: .login, request: request, isSignUp: false)
    }
    
    func signUp(email: String, username: String, password: String, agreedToTerms: Bool) {
        guard validator.validateSignUpInput(
            email: email,
            username: username,
            password: password,
            agreedToTerms: agreedToTerms
        ) else {
            showAlert(.error(validator.lastError))
            return
        }
        
        setLoading(true)
        
        let request = RegisterRequest(
            email: email,
            username: username,
            password: password,
            agreedToTerms: agreedToTerms
        )
        
        performSignUpRequest(request: request, email: email, password: password)
    }
    
    func createProfile(
        firstName: String,
        lastName: String,
        profileImageURL: String = "",
        bio: String = "",
        phoneNumber: String,
        addressNo: String,
        addressLine1: String,
        addressLine2: String,
        city: String,
        district: String
    ) {
        guard validator.validateCompleteProfileInput(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            addressNo: addressNo,
            addressLine1: addressLine1,
            city: city,
            district: district
        ) else {
            showAlert(.error(validator.lastError))
            return
        }
        
        guard let userId = currentUser?.id else {
            showAlert(.error("User ID not found. Please sign in again."))
            return
        }
        
        guard let token = jwtToken else {
            showAlert(.error("Authentication token not found. Please sign in again."))
            return
        }
        
        setLoading(true)
        
        let request = CreateProfileRequest(
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
        
        performProfileRequest(request: request, token: token)
    }
    
    func createProfile(firstName: String, lastName: String, profileImage: UIImage?) {
        let profileImageURL = imageProcessor.processProfileImage(profileImage)
        
        createProfile(
            firstName: firstName,
            lastName: lastName,
            profileImageURL: profileImageURL,
            bio: "",
            phoneNumber: "",
            addressNo: "",
            addressLine1: "",
            addressLine2: "",
            city: "",
            district: ""
        )
    }
    
    func signOut() {
        storageManager.clearAuthData()
        currentUser = nil
        jwtToken = nil
        isUserProfileAvailable = false
        profileCheckCompleted = false
        authState = .unauthenticated
        clearAlert()
        showAlert(.info("You have been signed out successfully"))
    }
    
    private func performAuthRequest<T: Codable>(endpoint: APIEndpoint, request: T, isSignUp: Bool) {
        networkManager.request(
            endpoint: endpoint,
            body: request,
            responseType: AuthResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                self?.handleAuthResponse(result, isSignUp: isSignUp)
            }
        }
    }
    
    private func performSignUpRequest(request: RegisterRequest, email: String, password: String) {
        networkManager.request(
            endpoint: .register,
            body: request,
            responseType: AuthResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleSignUpResponse(result, email: email, password: password)
            }
        }
    }
    
    private func performProfileRequest(request: CreateProfileRequest, token: String) {
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]

        let userId = currentUser?.id ?? ""
        let endpoint = APIEndpoint.createProfile(userId: userId)

        networkManager.requestWithHeaders(
            endpoint: endpoint,
            body: request,
            headers: headers,
            responseType: ProfileResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                self?.handleProfileResponse(result)
            }
        }
    }
    
    private func handleAuthResponse(_ result: Result<AuthResponse, Error>, isSignUp: Bool) {
        switch result {
        case .success(let response):
            if response.success {
                if let userData = response.userData, let token = response.token {
                    if let profileAvailable = response.isUserProfileAvailable {
                        isUserProfileAvailable = profileAvailable
                        storageManager.saveUserProfileAvailability(profileAvailable)
                        profileCheckCompleted = true
                    }
                    handleAuthSuccess(user: userData, token: token, isSignUp: isSignUp)
                } else {
                    let message = response.message.isEmpty ? "Authentication successful but incomplete response received." : response.message
                    showAlert(.error(message))
                    authState = .unauthenticated
                }
            } else {
                let message = response.message.isEmpty ? "Authentication failed" : response.message
                showAlert(.error(message))
                authState = .unauthenticated
            }
            
        case .failure(let error):
            handleNetworkError(error)
        }
    }
    
    private func handleSignUpResponse(_ result: Result<AuthResponse, Error>, email: String, password: String) {
        switch result {
        case .success(let response):
            if response.success {
                DispatchQueue.main.asyncAfter(deadline: .now() + AuthConstants.autoLoginDelay) {
                    self.performAutoLogin(email: email, password: password)
                }
            } else {
                setLoading(false)
                let message = response.message.isEmpty ? "Signup failed" : response.message
                showAlert(.error(message))
                authState = .unauthenticated
            }
            
        case .failure(let error):
            setLoading(false)
            handleNetworkError(error)
        }
    }
    
    private func handleAuthSuccess(user: User, token: String, isSignUp: Bool) {
        storageManager.saveToken(token)
        storageManager.saveUser(user)
        
        currentUser = user
        jwtToken = token
        authState = .authenticated(user)
        
        if !profileCheckCompleted {
            checkProfileCompletionFromServer()
        }
        
        clearAlert()
        let message = isSignUp ? "Welcome! Your account has been created." : "Welcome back!"
        showAlert(.success(message))
    }
    
    private func handleNetworkError(_ error: Error) {
        let message = ErrorHandler.getErrorMessage(for: error)
        showAlert(.error(message))
        
        if let nsError = error as NSError?, nsError.code == 401 {
            forceSignOut()
        }
    }
    
    private func forceSignOut() {
        storageManager.clearAuthData()
        currentUser = nil
        jwtToken = nil
        isUserProfileAvailable = false
        profileCheckCompleted = false
        authState = .unauthenticated
        clearAlert()
        showAlert(.error("Session expired. Please sign in again."))
    }
    
    private func performAutoLogin(email: String, password: String, retryCount: Int = 0) {
        let request = LoginRequest(
            email: email,
            password: password,
            rememberMe: true
        )
        
        networkManager.request(
            endpoint: .login,
            body: request,
            responseType: AuthResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleAutoLoginResponse(result, email: email, password: password, retryCount: retryCount)
            }
        }
    }
    
    private func handleAutoLoginResponse(_ result: Result<AuthResponse, Error>, email: String, password: String, retryCount: Int) {
        switch result {
        case .success(let response):
            if response.success {
                setLoading(false)
                handleAuthResponse(result, isSignUp: true)
            } else {
                retryAutoLoginIfNeeded(email: email, password: password, retryCount: retryCount)
            }
            
        case .failure(let error):
            if shouldRetryAutoLogin(error: error, retryCount: retryCount) {
                retryAutoLoginIfNeeded(email: email, password: password, retryCount: retryCount)
            } else {
                showSuccessAndRequireManualLogin()
            }
        }
    }
    
    private func retryAutoLoginIfNeeded(email: String, password: String, retryCount: Int) {
        if retryCount < AuthConstants.autoLoginRetryCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.performAutoLogin(email: email, password: password, retryCount: retryCount + 1)
            }
        } else {
            showSuccessAndRequireManualLogin()
        }
    }
    
    private func shouldRetryAutoLogin(error: Error, retryCount: Int) -> Bool {
        if let nsError = error as NSError?, nsError.code == 401, retryCount < AuthConstants.autoLoginRetryCount {
            return true
        }
        return false
    }
    
    private func showSuccessAndRequireManualLogin() {
        setLoading(false)
        showAlert(.success("Account created successfully! Please sign in."))
        authState = .unauthenticated
    }
    
    func showAlert(_ alert: AlertMessage) {
        alertMessage = alert
        
        if alert.type == .success {
            DispatchQueue.main.asyncAfter(deadline: .now() + AuthConstants.alertDismissDelay) {
                if self.alertMessage?.message == alert.message {
                    self.clearAlert()
                }
            }
        }
    }
    
    func clearAlert() {
        alertMessage = nil
    }
    
    private func setLoading(_ loading: Bool) {
        isLoading = loading
        if loading {
            clearAlert()
        }
    }
    
    private func updateCurrentUser(_ user: User) {
        storageManager.saveUser(user)
        currentUser = user
        authState = .authenticated(user)
    }
    
    func refreshTokenIfNeeded() {
        
    }
    
    func isTokenExpired() -> Bool {
        guard let token = jwtToken else { return true }
        
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else { return true }
        
        let payload = components[1]
        guard let data = Data(base64Encoded: payload.base64Padded()) else { return true }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let exp = json["exp"] as? TimeInterval {
                return Date().timeIntervalSince1970 > exp
            }
        } catch {
            return true
        }
        
        return true
    }
    
    
}

private extension String {
    func base64Padded() -> String {
        let remainder = self.count % 4
        if remainder > 0 {
            return self + String(repeating: "=", count: 4 - remainder)
        }
        return self
    }
}

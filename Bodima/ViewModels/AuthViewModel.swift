import Foundation
import SwiftUI

/**
 * AuthViewModel - Core Authentication State Manager
 *
 * Manages user authentication state, token validation, and profile completion status.
 * Implements singleton pattern for global authentication state management across the app.
 *
 * Key Responsibilities:
 * - User sign-in/sign-up operations
 * - JWT token management and validation
 * - Biometric authentication integration
 * - Profile completion status tracking
 * - Automatic token refresh and session management
 */
@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Singleton Instance
    static let shared = AuthViewModel()
    
    // MARK: - Published Properties
    /// Current authentication state of the user
    @Published var authState: AuthState = .idle
    
    /// Loading state for UI feedback during authentication operations
    @Published var isLoading = false
    
    /// Alert message for user feedback (errors, success messages)
    @Published var alertMessage: AlertMessage?
    
    /// Currently authenticated user data
    @Published var currentUser: User?
    
    /// JWT token for API authentication
    @Published var jwtToken: String?
    
    /// Flag indicating if user has completed profile setup
    @Published var isUserProfileAvailable = false
    
    /// Flag indicating if profile check has been completed
    @Published var profileCheckCompleted = false
    
    // MARK: - Dependencies
    private let networkManager: NetworkManager
    private let storageManager: UserDefaultsManager
    private let validator: AuthValidator
    private let biometricManager: BiometricManager
    private let keychainManager: KeychainManager
    private let profileCache = ProfileCacheRepository.shared
    
    // MARK: - Initialization
    /**
     * Private initializer for singleton pattern.
     * Initializes all dependencies and starts authentication status check.
     */
    private init(
        networkManager: NetworkManager = NetworkManager.shared,
        storageManager: UserDefaultsManager = UserDefaultsManager.shared,
        validator: AuthValidator = AuthValidator(),
        biometricManager: BiometricManager = BiometricManager.shared,
        keychainManager: KeychainManager = KeychainManager.shared
    ) {
        self.networkManager = networkManager
        self.storageManager = storageManager
        self.validator = validator
        self.biometricManager = biometricManager
        self.keychainManager = keychainManager
        
        checkAuthStatus()
        startTokenValidationTimer()
    }
    
    // MARK: - Token Validation Timer
    /// Timer for periodic JWT token validation to prevent expired token usage
    private var tokenValidationTimer: Timer?
    
    /**
     * Starts a periodic timer to validate JWT token every 60 seconds.
     * Prevents users from making API calls with expired tokens.
     */
    private func startTokenValidationTimer() {
        tokenValidationTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.validateTokenPeriodically()
        }
    }
    
    /**
     * Validates token periodically and signs out user if token is expired.
     * Only performs validation when user is in authenticated state.
     */
    private func validateTokenPeriodically() {
        if case .authenticated = authState {
            if isTokenExpired() {
                forceSignOut()
            }
        }
    }
    
    // MARK: - Computed Properties
    /// Returns true if user is currently authenticated
    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }
    
    /// Returns true if user is not authenticated
    var isUnauthenticated: Bool {
        if case .unauthenticated = authState { return true }
        return false
    }
    
    /// Returns true if there's an active alert message
    var hasAlert: Bool {
        alertMessage != nil
    }
    
    /**
     * Determines if authenticated user needs to complete their profile.
     * Checks multiple conditions including profile completion status and name availability.
     * Automatically updates user profile completion status if valid name data is found.
     */
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
        
        // Auto-complete profile if valid name data exists
        if hasFirstAndLastName || hasFullNameWithSpace {
            var updatedUser = user
            updatedUser.hasCompletedProfile = true
            updateCurrentUser(updatedUser)
            return false
        }
        
        return true
    }
    
    /// Returns true if JWT token exists and is not empty
    var hasValidToken: Bool {
        return jwtToken != nil && !jwtToken!.isEmpty
    }
    
    // MARK: - Authentication Status Management
    /**
     * Checks current authentication status on app launch.
     * Validates stored tokens and restores user session if valid.
     * Automatically signs out user if token is expired.
     */
    private func checkAuthStatus() {
        profileCheckCompleted = false
        
        if let user = storageManager.getUser(),
           let token = storageManager.getToken() {
            
            // Validate token before restoring session
            if isTokenExpired(token: token) {
                forceSignOut()
                return
            }
            
            // Restore authenticated session
            currentUser = user
            jwtToken = token
            isUserProfileAvailable = storageManager.getUserProfileAvailability()
            authState = .authenticated(user)
            // Seed profile cache from stored user if profile was completed previously
            if let userId = user.id, (user.hasCompletedProfile == true || isUserProfileAvailable) {
                if profileCache.fetch(userId: userId) == nil {
                    let synthesized = synthesizeProfileData(from: user)
                    profileCache.save(profile: synthesized)
                }
            }
            
            // Verify profile completion status with server
            checkProfileCompletionFromServer()
        } else {
            // No stored credentials, set unauthenticated state
            authState = .unauthenticated
            jwtToken = nil
            isUserProfileAvailable = false
            profileCheckCompleted = true
        }
    }
    
    /**
     * Fetches user profile completion status from server.
     * Called after successful authentication to verify profile data.
     * Updates local profile availability flags based on server response.
     */
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

    /**
     * Handles the response from profile completion check API call.
     * Updates user profile data and completion status based on server response.
     * Handles special case for "resource exceeds maximum size" error as profile complete.
     */
    private func handleProfileCheckResponse(_ result: Result<ProfileResponse, Error>) {
        profileCheckCompleted = true
        
        switch result {
        case .success(let response):
            if response.success, let profileData = response.data {
                // Profile exists and is complete
                isUserProfileAvailable = true
                storageManager.saveUserProfileAvailability(true)
                
                updateUserWithProfileData(profileData)
                // Cache profile for offline use
                profileCache.save(profile: profileData)
            } else {
                // Profile incomplete or doesn't exist
                markProfileIncomplete()
            }
            
        case .failure(let error):
            handleProfileCheckError(error)
        }
    }
    
    /**
     * Updates current user with complete profile data from server response.
     */
    private func updateUserWithProfileData(_ profileData: ProfileData) {
        guard var user = currentUser else { return }
        
        // Update profile completion status
        user.hasCompletedProfile = true
        
        // Update profile fields
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
        
        // Update authentication data
        user.email = profileData.auth.email
        user.username = profileData.auth.username
        user.id = profileData.id
        
        updateCurrentUser(user)
    }
    
    /**
     * Marks user profile as incomplete and updates storage.
     */
    private func markProfileIncomplete() {
        isUserProfileAvailable = false
        storageManager.saveUserProfileAvailability(false)
        
        if var user = currentUser {
            user.hasCompletedProfile = false
            updateCurrentUser(user)
        }
    }
    
    /**
     * Handles errors from profile check API call.
     * Special handling for "resource exceeds maximum size" which indicates complete profile.
     */
    private func handleProfileCheckError(_ error: Error) {
        let errorString = error.localizedDescription
        
        if errorString.contains("resource exceeds maximum size") {
            // Large profile response indicates complete profile
            isUserProfileAvailable = true
            storageManager.saveUserProfileAvailability(true)
            
            if var user = currentUser {
                user.hasCompletedProfile = true
                updateCurrentUser(user)
            }
        } else {
            // Try offline fallback from cache to avoid forcing profile completion when offline
            if let userId = currentUser?.id, let cached = profileCache.fetch(userId: userId) {
                isUserProfileAvailable = true
                storageManager.saveUserProfileAvailability(true)
                updateUserWithProfileData(cached)
            } else {
                // Preserve existing state instead of forcing incomplete when offline
                // This avoids pushing CreateProfileView unnecessarily
                profileCheckCompleted = true
            }
        }
    }

    /**
     * Refreshes user profile data from server.
     * Can be called manually to update profile completion status.
     */
    func refreshProfile() {
        checkProfileCompletionFromServer()
    }
    
    // MARK: - Authentication Operations
    /**
     * Performs user sign-in with email and password.
     * Validates input before making API request and handles remember me functionality.
     */
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
    
    // MARK: - Biometric Authentication
    /**
     * Performs biometric authentication using stored token.
     * Validates token format and verifies with backend before authentication.
     */
    func signInWithBiometric(token: String) {
        guard !token.isEmpty, token.count > 10 else {
            showAlert(.error("Invalid authentication token"))
            return
        }
        
        setLoading(true)
        
        let headers = ["Authorization": "Bearer \(token)"]
        let emptyBody = EmptyRequest()
        
        networkManager.requestWithHeaders(
            endpoint: .verifyToken,
            body: emptyBody,
            headers: headers,
            responseType: TokenVerificationResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                self?.handleBiometricAuthResponse(result, token: token)
            }
        }
    }
    
    /**
     * Handles biometric authentication response from server.
     * Updates authentication state on success or clears biometric data on failure.
     */
    private func handleBiometricAuthResponse(_ result: Result<TokenVerificationResponse, Error>, token: String) {
        switch result {
        case .success(let response):
            if response.success, let userData = response.userData {
                // Store authentication data
                storageManager.saveToken(token)
                storageManager.saveUser(userData)
                
                // Update current session
                currentUser = userData
                jwtToken = token
                authState = .authenticated(userData)
                
                // Handle profile availability
                handleProfileAvailabilityFromResponse(response)
                
                clearAlert()
                showAlert(.success("Welcome back! Signed in with biometric authentication."))
            } else {
                let message = response.message.isEmpty ? "Token verification failed" : response.message
                showAlert(.error(message))
                clearBiometricData()
            }
            
        case .failure(let error):
            handleNetworkError(error)
            clearBiometricData()
        }
    }
    
    /**
     * Handles profile availability data from authentication response.
     */
    private func handleProfileAvailabilityFromResponse(_ response: TokenVerificationResponse) {
        if let profileAvailable = response.isUserProfileAvailable {
            isUserProfileAvailable = profileAvailable
            storageManager.saveUserProfileAvailability(profileAvailable)
            profileCheckCompleted = true
        } else if !profileCheckCompleted {
            checkProfileCompletionFromServer()
        }
    }
    
    /**
     * Clears biometric authentication data when authentication fails.
     */
    private func clearBiometricData() {
        biometricManager.clearBiometricToken()
        biometricManager.setBiometricEnabled(false)
    }
    
    /**
     * Performs user registration with email, username, and password.
     * Validates input and initiates auto-login after successful registration.
     */
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
    
    /**
     * Signs out the current user and clears authentication data.
     * Preserves biometric token if biometric authentication is enabled.
     */
    func signOut() {
        // Stop token validation
        tokenValidationTimer?.invalidate()
        tokenValidationTimer = nil
        
        // Clear stored authentication data
        storageManager.clearAuthData()
        
        // Conditionally clear biometric data
        if !biometricManager.isBiometricEnabled {
            keychainManager.clearAllBiometricData()
        }
        
        // Reset authentication state
        resetAuthenticationState()
        
        showAlert(.info("You have been signed out successfully"))
    }
    
    /**
     * Resets all authentication-related state variables.
     */
    private func resetAuthenticationState() {
        currentUser = nil
        jwtToken = nil
        isUserProfileAvailable = false
        profileCheckCompleted = false
        authState = .unauthenticated
        clearAlert()
    }
    
    // MARK: - Private Authentication Helpers
    /**
     * Generic method to perform authentication requests (sign-in/sign-up).
     * Handles network request and response processing.
     */
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
        
        // Store token for biometric access if biometric is enabled
        if biometricManager.isBiometricEnabled {
            _ = biometricManager.storeBiometricToken(token)
        }
        
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
    
    /**
     * Forces user sign-out due to expired or invalid token.
     * Called automatically when token validation fails.
     */
    func forceSignOut() {
        // Stop token validation
        tokenValidationTimer?.invalidate()
        tokenValidationTimer = nil
        
        // Clear stored authentication data
        storageManager.clearAuthData()
        
        // Conditionally clear biometric data
        if !biometricManager.isBiometricEnabled {
            keychainManager.clearAllBiometricData()
        }
        
        // Reset authentication state
        resetAuthenticationState()
        
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

    // MARK: - Offline Cache Synthesis
    private func synthesizeProfileData(from user: User) -> ProfileData {
        let auth = AuthData(
            id: user.id ?? "",
            email: user.email,
            username: user.username,
            createdAt: user.createdAt ?? "",
            updatedAt: user.updatedAt ?? ""
        )
        return ProfileData(
            id: user.id ?? "",
            auth: auth,
            firstName: user.firstName,
            lastName: user.lastName,
            bio: user.bio,
            phoneNumber: user.phoneNumber,
            addressNo: user.addressNo,
            addressLine1: user.addressLine1,
            addressLine2: user.addressLine2,
            city: user.city,
            district: user.district,
            profileImageURL: user.profileImageURL ?? user.profileImageUrl,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
            profileImageUrl: user.profileImageURL ?? user.profileImageUrl,
            accessibilitySettings: nil
        )
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
    
    func updateCurrentUser(_ user: User) {
        storageManager.saveUser(user)
        currentUser = user
        authState = .authenticated(user)
        // If profile is complete, ensure cache is updated for offline use
        if let userId = user.id, user.hasCompletedProfile == true {
            let synthesized = synthesizeProfileData(from: user)
            profileCache.save(profile: synthesized)
        }
    }
    
    func refreshTokenIfNeeded() {
        
    }
    
    func isTokenExpired(token: String? = nil) -> Bool {
        let tokenToCheck = token ?? jwtToken
        guard let tokenToCheck = tokenToCheck else { return true }
        
        let components = tokenToCheck.components(separatedBy: ".")
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

// MARK: - Empty Request Model
struct EmptyRequest: Codable {
    // Empty struct for requests that don't need a body
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

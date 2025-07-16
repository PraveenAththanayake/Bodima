import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AuthViewModel()
    
    // MARK: - Published Properties
    @Published var authState: AuthState = .idle
    @Published var isLoading = false
    @Published var alertMessage: AlertMessage?
    @Published var currentUser: User?
    
    // MARK: - Dependencies
    private let networkManager: NetworkManager
    private let storageManager: UserDefaultsManager
    private let validator: AuthValidator
    private let imageProcessor: ImageProcessor
    
    // MARK: - Initialization
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
    
    // MARK: - Computed Properties
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
        guard let user = currentUser else { return false }
        return user.hasCompletedProfile == false || user.firstName == nil || user.lastName == nil
    }
}

// MARK: - Auth Status Management
extension AuthViewModel {
    private func checkAuthStatus() {
        if let user = storageManager.getUser(),
           storageManager.getToken() != nil {
            print("🔍 DEBUG - Found existing user session")
            currentUser = user
            authState = .authenticated(user)
        } else {
            print("🔍 DEBUG - No existing user session found")
            authState = .unauthenticated
        }
    }
}

// MARK: - Authentication Operations
extension AuthViewModel {
    func signIn(email: String, password: String, rememberMe: Bool) {
        guard validator.validateSignInInput(email: email, password: password) else {
            showAlert(.error(validator.lastError))
            return
        }
        
        print("🔍 DEBUG - Starting sign in process")
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
        
        print("🔍 DEBUG - Starting sign up process")
        setLoading(true)
        
        let request = RegisterRequest(
            email: email,
            username: username,
            password: password,
            agreedToTerms: agreedToTerms
        )
        
        performSignUpRequest(request: request, email: email, password: password)
    }
    
    func createProfile(firstName: String, lastName: String, profileImage: UIImage?) {
        guard validator.validateProfileInput(firstName: firstName, lastName: lastName) else {
            showAlert(.error(validator.lastError))
            return
        }
        
        setLoading(true)
        
        let profileImageBase64 = imageProcessor.processProfileImage(profileImage)
        
        let request = CreateProfileRequest(
            firstName: firstName.trimmingCharacters(in: .whitespaces),
            lastName: lastName.trimmingCharacters(in: .whitespaces),
            profileImageBase64: profileImageBase64
        )
        
        performProfileRequest(request: request)
    }
    
    func signOut() {
        print("🔍 DEBUG - Signing out user")
        storageManager.clearAuthData()
        currentUser = nil
        authState = .unauthenticated
        clearAlert()
        showAlert(.info("You have been signed out successfully"))
    }
}

// MARK: - Network Request Handlers
private extension AuthViewModel {
    func performAuthRequest<T: Codable>(endpoint: APIEndpoint, request: T, isSignUp: Bool) {
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
    
    func performSignUpRequest(request: RegisterRequest, email: String, password: String) {
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
    
    func performProfileRequest(request: CreateProfileRequest) {
        networkManager.request(
            endpoint: .createProfile,
            body: request,
            responseType: AuthResponse.self
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.setLoading(false)
                self?.handleProfileResponse(result)
            }
        }
    }
}

// MARK: - Response Handlers
private extension AuthViewModel {
    func handleAuthResponse(_ result: Result<AuthResponse, Error>, isSignUp: Bool) {
        switch result {
        case .success(let response):
            print("🔍 DEBUG - Auth Response: Success=\(response.success), Message=\(response.message)")
            
            if response.success {
                if let userData = response.userData, let token = response.token {
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
            print("🔍 DEBUG - Network Error: \(error)")
            handleNetworkError(error)
        }
    }
    
    func handleSignUpResponse(_ result: Result<AuthResponse, Error>, email: String, password: String) {
        switch result {
        case .success(let response):
            print("🔍 DEBUG - Signup Response: Success=\(response.success), Message=\(response.message)")
            
            if response.success {
                print("🔍 DEBUG - Signup successful, attempting auto-login...")
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
            print("🔍 DEBUG - Signup Error: \(error)")
            handleNetworkError(error)
        }
    }
    
    func handleProfileResponse(_ result: Result<AuthResponse, Error>) {
        switch result {
        case .success(let response):
            print("🔍 DEBUG - Profile Response: Success=\(response.success), Message=\(response.message)")
            
            if response.success, let userData = response.userData {
                updateCurrentUser(userData)
                showAlert(.success("Profile created successfully"))
            } else {
                let message = response.message.isEmpty ? "Profile creation failed" : response.message
                showAlert(.error(message))
            }
            
        case .failure(let error):
            print("🔍 DEBUG - Profile Error: \(error)")
            handleNetworkError(error)
        }
    }
    
    func handleAuthSuccess(user: User, token: String, isSignUp: Bool) {
        print("🔍 DEBUG - Auth Success - User: \(user.username), IsSignUp: \(isSignUp)")
        
        // Save to storage
        storageManager.saveToken(token)
        storageManager.saveUser(user)
        
        // Update state
        currentUser = user
        authState = .authenticated(user)
        
        // Clear alerts and show success message
        clearAlert()
        let message = isSignUp ? "Welcome! Your account has been created." : "Welcome back!"
        showAlert(.success(message))
        
        print("🔍 DEBUG - Auth state updated to: \(authState)")
    }
    
    func handleNetworkError(_ error: Error) {
        print("🔍 DEBUG - Network Error: \(error)")
        
        let message = ErrorHandler.getErrorMessage(for: error)
        showAlert(.error(message))
        authState = .unauthenticated
    }
}

// MARK: - Auto Login Handler
private extension AuthViewModel {
    func performAutoLogin(email: String, password: String, retryCount: Int = 0) {
        print("🔍 DEBUG - Auto-login attempt \(retryCount + 1)")
        
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
    
    func handleAutoLoginResponse(_ result: Result<AuthResponse, Error>, email: String, password: String, retryCount: Int) {
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
    
    func retryAutoLoginIfNeeded(email: String, password: String, retryCount: Int) {
        if retryCount < AuthConstants.autoLoginRetryCount {
            print("🔍 DEBUG - Auto-login failed, retrying...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.performAutoLogin(email: email, password: password, retryCount: retryCount + 1)
            }
        } else {
            showSuccessAndRequireManualLogin()
        }
    }
    
    func shouldRetryAutoLogin(error: Error, retryCount: Int) -> Bool {
        if let nsError = error as NSError?, nsError.code == 401, retryCount < AuthConstants.autoLoginRetryCount {
            return true
        }
        return false
    }
    
    func showSuccessAndRequireManualLogin() {
        setLoading(false)
        showAlert(.success("Account created successfully! Please sign in."))
        authState = .unauthenticated
    }
}

// MARK: - Alert Management
extension AuthViewModel {
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
}

// MARK: - Helper Methods
private extension AuthViewModel {
    func setLoading(_ loading: Bool) {
        isLoading = loading
        if loading {
            clearAlert()
        }
    }
    
    func updateCurrentUser(_ user: User) {
        storageManager.saveUser(user)
        currentUser = user
        authState = .authenticated(user)
    }
}

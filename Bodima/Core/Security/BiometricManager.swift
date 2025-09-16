import Foundation
import LocalAuthentication

@MainActor
class BiometricManager: ObservableObject {
    static let shared = BiometricManager()
    
    @Published var biometricType: LABiometryType = .none
    @Published var isBiometricAvailable = false
    @Published var isBiometricEnabled = false
    
    private let keychainManager = KeychainManager.shared
    private var isInitialized = false
    
    private init() {
        print("🔐 BiometricManager: Initializing...")
        // Don't run async tasks in init - defer to first usage
        DispatchQueue.main.async {
            Task {
                await self.performInitialization()
            }
        }
    }
    
    private func performInitialization() async {
        guard !isInitialized else { return }
        
        await checkBiometricAvailability()
        await loadBiometricSettings()
        
        isInitialized = true
        print("🔐 BiometricManager: Initialization complete")
    }
    
    // MARK: - Biometric Availability Check
    private func checkBiometricAvailability() async {
        let shouldProceed = await MainActor.run { !isInitialized }
        guard shouldProceed else { return }
        
        await MainActor.run {
            let context = LAContext()
            var error: NSError?
            let isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            
            self.isBiometricAvailable = isAvailable
            self.biometricType = context.biometryType
            
            print("🔐 BiometricManager: Checking availability...")
            print("🔐 Available: \(isAvailable)")
            print("🔐 Type: \(self.biometricType.rawValue) (\(self.getBiometricTypeString()))")
            
            if !isAvailable {
                print("🔴 Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
            } else {
                print("🔴 Biometric authentication available: \(self.getBiometricTypeString())")
            }
        }
    }
    
    // MARK: - Public method to refresh availability
    func refreshBiometricAvailability() async {
        await performInitialization()
        await checkBiometricAvailability()
    }
    
    // MARK: - Biometric Settings
    private func loadBiometricSettings() async {
        await MainActor.run {
            self.isBiometricEnabled = UserDefaults.standard.bool(forKey: "biometricEnabled")
        }
    }
    
    func setBiometricEnabled(_ enabled: Bool) {
        Task {
            await performInitialization()
            
            await MainActor.run {
                self.isBiometricEnabled = enabled
                UserDefaults.standard.set(enabled, forKey: "biometricEnabled")
                
                if !enabled {
                    // Clear biometric-related data from keychain
                    self.keychainManager.deleteBiometricToken()
                    self.keychainManager.clearAllBiometricData()
                }
            }
        }
    }
    
    // MARK: - Biometric Authentication
    func authenticateWithBiometrics() async -> BiometricAuthResult {
        // Ensure initialization is complete
        await performInitialization()
        
        // Ensure we're on main thread for UI-related checks
        let (available, enabled) = await MainActor.run {
            return (self.isBiometricAvailable, self.isBiometricEnabled)
        }
        
        guard available else {
            print("🔴 Biometric authentication not available")
            return .failure(BiometricError.notAvailable)
        }
        
        guard enabled else {
            print("🔴 Biometric authentication not enabled")
            return .failure(BiometricError.notEnabled)
        }
        
        do {
            // Create a fresh context for each authentication attempt
            let context = LAContext()
            
            // Set localized fallback title (optional)
            context.localizedFallbackTitle = "Use Passcode"
            
            // Check if biometrics are still available with fresh context
            var error: NSError?
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                let errorMessage = error?.localizedDescription ?? "Biometric authentication not available"
                print("🔴 Biometric evaluation failed: \(errorMessage)")
                return .failure(BiometricError.systemError(errorMessage))
            }
            
            let reason = await MainActor.run { self.getBiometricPromptMessage() }
            print("🔐 Starting biometric authentication with reason: \(reason)")
            
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                print("🔐 Biometric authentication successful")
                // Retrieve stored token from keychain
                if let token = keychainManager.getBiometricToken(), !token.isEmpty {
                    print("🔐 Token retrieved successfully")
                    return .success(token)
                } else {
                    print("🔴 No valid token found in keychain")
                    return .failure(BiometricError.noStoredCredentials)
                }
            } else {
                print("🔴 Biometric authentication failed")
                return .failure(BiometricError.authenticationFailed)
            }
        } catch let authError {
            print("🔴 Biometric authentication error: \(authError.localizedDescription)")
            
            // Handle specific LocalAuthentication errors
            if let laError = authError as? LAError {
                switch laError.code {
                case .userCancel:
                    print("🔴 User cancelled authentication")
                    return .failure(BiometricError.userCancelled)
                case .userFallback:
                    print("🔴 User chose fallback authentication")
                    return .failure(BiometricError.systemError("User chose to use fallback authentication"))
                case .biometryNotAvailable:
                    print("🔴 Biometry not available")
                    return .failure(BiometricError.notAvailable)
                case .biometryNotEnrolled:
                    print("🔴 Biometry not enrolled")
                    return .failure(BiometricError.biometryNotEnrolled)
                case .biometryLockout:
                    print("🔴 Biometry locked out")
                    return .failure(BiometricError.biometryLockout)
                default:
                    print("🔴 Other LocalAuthentication error: \(laError.localizedDescription)")
                    return .failure(BiometricError.systemError(laError.localizedDescription))
                }
            }
            
            return .failure(BiometricError.systemError(authError.localizedDescription))
        }
    }
    
    // MARK: - Token Storage
    func storeBiometricToken(_ token: String) -> Bool {
        return keychainManager.saveBiometricToken(token)
    }
    
    func clearBiometricToken() {
        keychainManager.deleteBiometricToken()
    }
    
    // MARK: - Testing and Verification
    func testBiometricAvailability() -> (available: Bool, type: String, error: String?) {
        let context = LAContext()
        var error: NSError?
        let isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        let typeString: String
        switch context.biometryType {
        case .faceID:
            typeString = "Face ID"
        case .touchID:
            typeString = "Touch ID"
        case .opticID:
            typeString = "Optic ID"
        default:
            typeString = "None"
        }
        
        return (available: isAvailable, type: typeString, error: error?.localizedDescription)
    }
    
    // MARK: - Helper Methods
    private func getBiometricPromptMessage() -> String {
        switch biometricType {
        case .faceID:
            return "Use Face ID to sign in to Bodima"
        case .touchID:
            return "Use Touch ID to sign in to Bodima"
        case .opticID:
            return "Use Optic ID to sign in to Bodima"
        default:
            return "Use biometric authentication to sign in to Bodima"
        }
    }
    
    func getBiometricTypeString() -> String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        default:
            return "Biometric Authentication"
        }
    }
    
    func getBiometricIcon() -> String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        default:
            return "person.badge.key"
        }
    }
}

// MARK: - BiometricAuthResult
enum BiometricAuthResult {
    case success(String) // JWT token
    case failure(BiometricError)
}

// MARK: - BiometricError
enum BiometricError: Error, LocalizedError {
    case notAvailable
    case notEnabled
    case authenticationFailed
    case noStoredCredentials
    case userCancelled
    case biometryLockout
    case biometryNotEnrolled
    case systemError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnabled:
            return "Biometric authentication is not enabled. Please enable it in your profile settings"
        case .authenticationFailed:
            return "Biometric authentication failed. Please try again"
        case .noStoredCredentials:
            return "No stored credentials found. Please sign in with your email and password first"
        case .userCancelled:
            return "Authentication was cancelled"
        case .biometryLockout:
            return "Biometric authentication is temporarily locked. Please use your device passcode to unlock"
        case .biometryNotEnrolled:
            return "Biometric authentication is not set up. Please set up Face ID or Touch ID in device settings"
        case .systemError(let message):
            return "System error: \(message)"
        }
    }
}
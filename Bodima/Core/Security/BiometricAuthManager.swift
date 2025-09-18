import Foundation
import LocalAuthentication

/// Manages biometric authentication (Face ID / Touch ID)
/// Provides a simple async API to gate sensitive actions like payment confirmation
final class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    private init() {}
    
    /// Checks if device supports biometrics and has them enrolled
    func isBiometricAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return canEvaluate
    }
    
    /// Authenticates user with biometrics. Falls back to device passcode if available.
    /// Returns true on success, false otherwise.
    @MainActor
    func authenticateUser(reason: String = "Authenticate to proceed") async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"
        
        // Prefer biometrics; allow passcode fallback
        let policy: LAPolicy = .deviceOwnerAuthentication
        
        return await withCheckedContinuation { continuation in
            var authError: NSError?
            guard context.canEvaluatePolicy(policy, error: &authError) else {
                // If we can't evaluate, deny but don't crash the flow
                continuation.resume(returning: false)
                return
            }
            context.evaluatePolicy(policy, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}

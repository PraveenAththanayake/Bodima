import Foundation

struct AuthConstants {
    // Storage Keys
    static let tokenKey = "auth_token"
    static let userKey = "current_user"
    
    // Auth Settings
    static let autoLoginDelay: TimeInterval = 1.0
    static let autoLoginRetryCount = 2
    static let alertDismissDelay: TimeInterval = 3.0
    
    // Token Settings
    static let tokenRefreshThreshold = 300 // 5 minutes in seconds
    
    // Validation Settings
    static let minimumPasswordLength = 6
    static let minimumUsernameLength = 3
    static let maxPasswordLength = 128
    static let maxUsernameLength = 50
    static let maxEmailLength = 254
    
    // UI Settings
    static let profileImageSize = CGSize(width: 300, height: 300)
    static let imageCompressionQuality: CGFloat = 0.8
}

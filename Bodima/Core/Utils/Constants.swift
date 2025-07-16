import Foundation

struct AuthConstants {
    static let tokenKey = "auth_token"
    static let userKey = "current_user"
    static let minimumPasswordLength = 6
    static let minimumUsernameLength = 3
    static let profileImageSize = CGSize(width: 300, height: 300)
    static let imageCompressionQuality: CGFloat = 0.8
    static let autoLoginRetryCount = 2
    static let autoLoginDelay: TimeInterval = 1.0
    static let alertDismissDelay: TimeInterval = 3.0
}

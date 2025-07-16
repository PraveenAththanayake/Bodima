struct AuthResponse: Codable {
    let success: Bool
    let message: String
    let user: User?
    let data: User?
    let token: String?
    let isUserProfileAvailable: Bool?
    var userData: User? {
        return user ?? data
    }
}

struct LoginRequest: Codable {
    let email: String?
    let password: String
    let rememberMe: Bool
    let emailOrUsername: String?
    
    init(email: String, password: String, rememberMe: Bool) {
        self.email = nil
        self.emailOrUsername = email
        self.password = password
        self.rememberMe = rememberMe
    }
}

struct RegisterRequest: Codable {
    let email: String
    let username: String
    let password: String
    let agreedToTerms: Bool
}

struct CreateProfileRequest: Codable {
    let firstName: String
    let lastName: String
    let profileImageBase64: String?
}

struct ErrorResponse: Codable {
    let success: Bool
    let message: String
    let errors: [String]?
}

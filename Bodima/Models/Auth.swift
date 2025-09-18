struct ProfileResponse: Codable {
    let success: Bool
    let message: String?
    let data: ProfileData?
}

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

struct TokenVerificationResponse: Codable {
    let success: Bool
    let message: String
    let userData: User?
    let isValid: Bool?
    let isUserProfileAvailable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case userData = "userData"
        case isValid
        case isUserProfileAvailable
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
    let userId: String
    let firstName: String
    let lastName: String
    let profileImageURL: String?
    let bio: String?
    let phoneNumber: String
    let addressNo: String
    let addressLine1: String
    let addressLine2: String?
    let city: String
    let district: String
    
    init(
        userId: String,
        firstName: String,
        lastName: String,
        profileImageURL: String,
        bio: String = "",
        phoneNumber: String,
        addressNo: String,
        addressLine1: String,
        addressLine2: String = "",
        city: String,
        district: String
    ) {
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.profileImageURL = profileImageURL.isEmpty ? nil : profileImageURL
        self.bio = bio.isEmpty ? nil : bio
        self.phoneNumber = phoneNumber
        self.addressNo = addressNo
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2.isEmpty ? nil : addressLine2
        self.city = city
        self.district = district
    }
}

struct CreateProfileResponse: Codable {
    let success: Bool
    let message: String
    let data: CreatedProfileData?
}

struct CreatedProfileData: Codable {
    let id: String
    let auth: String  // This is just the auth ID reference
    let firstName: String?
    let lastName: String?
    let bio: String?
    let phoneNumber: String?
    let addressNo: String?
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let district: String?
    let profileImageURL: String?
    let createdAt: String?
    let updatedAt: String?
    let v: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case auth
        case firstName
        case lastName
        case bio
        case phoneNumber
        case addressNo
        case addressLine1
        case addressLine2
        case city
        case district
        case profileImageURL
        case createdAt
        case updatedAt
        case v = "__v"
    }
}

struct UpdateProfileRequest: Codable {
    let firstName: String
    let lastName: String
    let profileImageURL: String?
    let bio: String?
    let phoneNumber: String
    let addressNo: String
    let addressLine1: String
    let addressLine2: String?
    let city: String
    let district: String
    
    init(
        firstName: String,
        lastName: String,
        profileImageURL: String,
        bio: String = "",
        phoneNumber: String,
        addressNo: String,
        addressLine1: String,
        addressLine2: String = "",
        city: String,
        district: String
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.profileImageURL = profileImageURL.isEmpty ? nil : profileImageURL
        self.bio = bio.isEmpty ? nil : bio
        self.phoneNumber = phoneNumber
        self.addressNo = addressNo
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2.isEmpty ? nil : addressLine2
        self.city = city
        self.district = district
    }
}

struct UpdateProfileResponse: Codable {
    let success: Bool
    let message: String
    let data: ProfileData?
}




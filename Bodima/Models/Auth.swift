struct ProfileResponse: Codable {
    let success: Bool
    let message: String
    let data: ProfileData?
    
    struct ProfileData: Codable {
        let auth: String
        let firstName: String
        let lastName: String
        let bio: String?
        let phoneNumber: String
        let addressNo: String
        let addressLine1: String
        let addressLine2: String?
        let city: String
        let district: String
        let id: String
        let createdAt: String
        let updatedAt: String
        
        enum CodingKeys: String, CodingKey {
            case auth, firstName, lastName, bio, phoneNumber
            case addressNo, addressLine1, addressLine2, city, district
            case id = "_id"
            case createdAt, updatedAt
        }
    }
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


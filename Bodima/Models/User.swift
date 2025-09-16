import Foundation

struct User: Codable {
    var id: String?
    var email: String
    var username: String
    var fullName: String?
    var firstName: String?
    var lastName: String?
    var bio: String?
    var phoneNumber: String?
    var hasCompletedProfile: Bool?
    
    var profileImageUrl: String?
    var addressNo: String?
    var addressLine1: String?
    var addressLine2: String?
    var city: String?
    var district: String?
    var profileImageURL: String?
    var createdAt: String?
    var updatedAt: String?
    
    // Computed property for display name
    var displayName: String {
        if let firstName = firstName, !firstName.isEmpty,
           let lastName = lastName, !lastName.isEmpty {
            return "\(firstName) \(lastName)"
        }
        return fullName ?? username
    }
    
    // Computed property for full address
    var fullAddress: String {
        var addressComponents: [String] = []
        
        if let addressNo = addressNo, !addressNo.isEmpty {
            addressComponents.append(addressNo)
        }
        if let addressLine1 = addressLine1, !addressLine1.isEmpty {
            addressComponents.append(addressLine1)
        }
        if let addressLine2 = addressLine2, !addressLine2.isEmpty {
            addressComponents.append(addressLine2)
        }
        if let city = city, !city.isEmpty {
            addressComponents.append(city)
        }
        if let district = district, !district.isEmpty {
            addressComponents.append(district)
        }
        
        return addressComponents.joined(separator: ", ")
    }
    
    init(
        id: String? = nil,
        email: String,
        username: String,
        fullName: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        bio: String? = nil,
        phoneNumber: String? = nil,
        hasCompletedProfile: Bool? = nil,
        profileImageUrl: String? = nil,
        addressNo: String? = nil,
        addressLine1: String? = nil,
        addressLine2: String? = nil,
        city: String? = nil,
        district: String? = nil,
        profileImageURL: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.email = email
        self.username = username
        self.fullName = fullName
        self.firstName = firstName
        self.lastName = lastName
        self.bio = bio
        self.phoneNumber = phoneNumber
        self.hasCompletedProfile = hasCompletedProfile
        self.profileImageUrl = profileImageUrl
        self.addressNo = addressNo
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.city = city
        self.district = district
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// Update ProfileData struct to match API response
struct ProfileData: Codable {
    let id: String
    let auth: AuthData
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
    let profileImageUrl: String?
    let accessibilitySettings: AccessibilitySettings?
    
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
        case profileImageUrl
        case accessibilitySettings
    }
}

// MARK: - Accessibility Settings
struct AccessibilitySettings: Codable, Equatable {
    var largeText: Bool
    var highContrast: Bool
    var voiceOver: Bool
    var reduceMotion: Bool
    var screenReader: Bool
    var colorBlindAssist: Bool
    var hapticFeedback: Bool
    
    init(
        largeText: Bool = false,
        highContrast: Bool = false,
        voiceOver: Bool = false,
        reduceMotion: Bool = false,
        screenReader: Bool = false,
        colorBlindAssist: Bool = false,
        hapticFeedback: Bool = true
    ) {
        self.largeText = largeText
        self.highContrast = highContrast
        self.voiceOver = voiceOver
        self.reduceMotion = reduceMotion
        self.screenReader = screenReader
        self.colorBlindAssist = colorBlindAssist
        self.hapticFeedback = hapticFeedback
    }
}

struct AuthData: Codable {
    let id: String
    let email: String
    let username: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
        case username
        case createdAt
        case updatedAt
    }
}

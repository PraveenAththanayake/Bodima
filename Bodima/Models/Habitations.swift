import Foundation

// MARK: - Original Habitation Models (Updated with Price)
struct CreateHabitationRequest: Codable {
    let user: String
    let name: String
    let description: String
    let type: String
    let isReserved: Bool
    let price: Int
}

struct HabitationData: Codable, Identifiable {
    let id: String
    let user: String
    let name: String
    let description: String
    let type: String
    let isReserved: Bool
    let createdAt: String
    let updatedAt: String
    let v: Int
    let price: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user, name, description, type, isReserved, createdAt, updatedAt
        case v = "__v"
        case price
    }
}

struct CreateHabitationResponse: Codable {
    let success: Bool
    let message: String
    let data: HabitationData?
}

struct GetHabitationsResponse: Codable {
    let success: Bool
    let data: [HabitationData]?
    let message: String?
}

struct GetHabitationByIdResponse: Codable {
    let success: Bool
    let data: HabitationData?
    let message: String?
}

// MARK: - New Enhanced Models for Full API Response (Updated with Price)
struct EnhancedUserData: Codable {
    let id: String
    let auth: String
    let firstName: String
    let lastName: String
    let bio: String
    let phoneNumber: String
    let addressNo: String
    let addressLine1: String
    let addressLine2: String
    let city: String
    let district: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case auth, firstName, lastName, bio, phoneNumber, addressNo, addressLine1, addressLine2, city, district
    }
}

struct HabitationPicture: Codable, Identifiable {
    let id: String
    let habitation: String
    let pictureUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case habitation, pictureUrl
    }
}

struct EnhancedHabitationData: Codable, Identifiable {
    let id: String
    let user: EnhancedUserData
    let name: String
    let description: String
    let type: String
    let isReserved: Bool
    let createdAt: String
    let updatedAt: String
    let v: Int
    let price: Int
    let pictures: [HabitationPicture]?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user, name, description, type, isReserved, createdAt, updatedAt, pictures
        case v = "__v"
        case price
    }
    
    var userFullName: String {
        return "\(user.firstName) \(user.lastName)"
    }
    
    var mainPictureUrl: String? {
        return pictures?.first?.pictureUrl
    }
    
    var pictureUrls: [String] {
        return pictures?.map { $0.pictureUrl } ?? []
    }
    
    var userIdString: String {
        return user.id
    }
}

struct GetEnhancedHabitationsResponse: Codable {
    let success: Bool
    let data: [EnhancedHabitationData]?
    let message: String?
}

struct GetEnhancedHabitationByIdResponse: Codable {
    let success: Bool
    let data: EnhancedHabitationData?
    let message: String?
}

// MARK: - Habitation Types Enum
enum HabitationType: String, CaseIterable {
    case singleRoom = "SingleRoom"
    case doubleRoom = "DoubleRoom"
    case apartment = "Apartment"
    case house = "House"
    case dormitory = "Dormitory"
    
    var displayName: String {
        switch self {
        case .singleRoom:
            return "Single Room"
        case .doubleRoom:
            return "Double Room"
        case .apartment:
            return "Apartment"
        case .house:
            return "House"
        case .dormitory:
            return "Dormitory"
        }
    }
}

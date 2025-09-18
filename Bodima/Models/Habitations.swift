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
    let firstName: String
    let lastName: String
    let phoneNumber: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName, lastName, phoneNumber
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)"
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
    let user: EnhancedUserData?
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
    
    // MARK: - Custom Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        price = try container.decode(Int.self, forKey: .price)
        type = try container.decode(String.self, forKey: .type)
        isReserved = try container.decodeIfPresent(Bool.self, forKey: .isReserved) ?? false
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
        
        // Handle optional __v field
        v = try container.decodeIfPresent(Int.self, forKey: .v) ?? 0
        
        // Handle null user field
        user = try container.decodeIfPresent(EnhancedUserData.self, forKey: .user)
        
        // Handle pictures
        pictures = try container.decodeIfPresent([HabitationPicture].self, forKey: .pictures)
    }
    
    var userFullName: String {
        return user != nil ? "\(user!.firstName) \(user!.lastName)" : "Unknown User"
    }
    
    var mainPictureUrl: String? {
        return pictures?.first?.pictureUrl
    }
    
    var pictureUrls: [String] {
        return pictures?.map { $0.pictureUrl } ?? []
    }
    
    var userIdString: String {
        return user?.id ?? ""
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

// MARK: - Habitation Models
struct CreateHabitationRequest: Codable {
    let user: String
    let name: String
    let description: String
    let type: String
    let isReserved: Bool
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
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user, name, description, type, isReserved, createdAt, updatedAt
        case v = "__v"
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

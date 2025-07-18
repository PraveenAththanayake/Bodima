import Foundation

// MARK: - Habitation Models

struct Habitation: Codable, Identifiable {
    let id: String
    let user: String
    let name: String
    let description: String
    let type: String
    let isReserved: Bool
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user, name, description, type, isReserved, createdAt, updatedAt
    }
}

struct CreateHabitationRequest: Codable {
    let user: String
    let name: String
    let description: String
    let type: String
    let isReserved: Bool
}

struct CreateHabitationResponse: Codable {
    let success: Bool
    let message: String
    let data: Habitation?
}

// MARK: - Location Models

struct HabitationLocation: Codable, Identifiable {
    let id: String
    let habitation: String
    let addressNo: String
    let addressLine01: String
    let addressLine02: String
    let city: String
    let district: String
    let latitude: Double
    let longitude: Double
    let nearestHabitationLatitude: Double
    let nearestHabitationLongitude: Double
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case habitation, addressNo, addressLine01, addressLine02, city, district
        case latitude, longitude, nearestHabitationLatitude, nearestHabitationLongitude
        case createdAt, updatedAt
    }
}

struct CreateLocationRequest: Codable {
    let habitation: String
    let addressNo: String
    let addressLine01: String
    let addressLine02: String
    let city: String
    let district: String
    let latitude: Double
    let longitude: Double
    let nearestHabitationLatitude: Double
    let nearestHabitationLongitude: Double
}

struct CreateLocationResponse: Codable {
    let success: Bool
    let message: String
    let data: HabitationLocation?
}

// MARK: - Habitation Feature Models

struct HabitationFeature: Codable, Identifiable {
    let id: String
    let habitation: String
    let sqft: Int
    let familyType: String
    let windowsCount: Int
    let smallBedCount: Int
    let largeBedCount: Int
    let chairCount: Int
    let tableCount: Int
    let isElectricityAvailable: Bool
    let isWachineMachineAvailable: Bool
    let isWaterAvailable: Bool
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case habitation, sqft, familyType, windowsCount, smallBedCount, largeBedCount
        case chairCount, tableCount, isElectricityAvailable, isWachineMachineAvailable, isWaterAvailable
        case createdAt, updatedAt
    }
}

struct CreateHabitationFeatureRequest: Codable {
    let habitation: String
    let sqft: Int
    let familyType: String
    let windowsCount: Int
    let smallBedCount: Int
    let largeBedCount: Int
    let chairCount: Int
    let tableCount: Int
    let isElectricityAvailable: Bool
    let isWachineMachineAvailable: Bool
    let isWaterAvailable: Bool
}

struct CreateHabitationFeatureResponse: Codable {
    let success: Bool
    let message: String
    let data: HabitationFeature?
}

// MARK: - Complete Habitation Model

struct CompleteHabitation: Codable, Identifiable {
    let id: String
    let habitation: Habitation
    let location: HabitationLocation?
    let features: HabitationFeature?
    
    var name: String { habitation.name }
    var description: String { habitation.description }
    var type: String { habitation.type }
    var isReserved: Bool { habitation.isReserved }
}

// MARK: - Habitation Types Enum

enum HabitationType: String, CaseIterable {
    case singleRoom = "SingleRoom"
    case apartment = "Apartment"
    case house = "House"
    case studio = "Studio"
    case sharedRoom = "SharedRoom"
    
    var displayName: String {
        switch self {
        case .singleRoom: return "Single Room"
        case .apartment: return "Apartment"
        case .house: return "House"
        case .studio: return "Studio"
        case .sharedRoom: return "Shared Room"
        }
    }
}

// MARK: - Family Type Enum

enum FamilyType: String, CaseIterable {
    case oneStory = "One Story"
    case twoStory = "Two Story"
    case threeStory = "Three Story"
    case apartment = "Apartment"
    case penthouse = "Penthouse"
    
    var displayName: String { rawValue }
}

// MARK: - District Enum for Sri Lanka

enum District: String, CaseIterable {
    case colombo = "Colombo"
    case gampaha = "Gampaha"
    case kalutara = "Kalutara"
    case kandy = "Kandy"
    case matale = "Matale"
    case nuwaraEliya = "Nuwara Eliya"
    case galle = "Galle"
    case matara = "Matara"
    case hambantota = "Hambantota"
    case jaffna = "Jaffna"
    case kilinochchi = "Kilinochchi"
    case mannar = "Mannar"
    case mullaitivu = "Mullaitivu"
    case vavuniya = "Vavuniya"
    case puttalam = "Puttalam"
    case kurunegala = "Kurunegala"
    case anuradhapura = "Anuradhapura"
    case polonnaruwa = "Polonnaruwa"
    case badulla = "Badulla"
    case monaragala = "Monaragala"
    case ratnapura = "Ratnapura"
    case kegalle = "Kegalle"
    case ampara = "Ampara"
    case batticaloa = "Batticaloa"
    case trincomalee = "Trincomalee"
    
    var displayName: String { rawValue }
}

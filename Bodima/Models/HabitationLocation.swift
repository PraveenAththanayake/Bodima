import Foundation

/**
 * Data models for habitation location management in the Bodima application.
 * These models represent location data, address information, and geographical coordinates
 * for habitation properties with flexible habitation reference handling.
 */

// MARK: - Core Data Models

/**
 * Represents habitation data nested within location responses.
 * Contains basic habitation information for location context.
 */
struct LocationHabitation: Codable {
    /// Unique identifier for the habitation
    let id: String
    
    /// User ID who owns the habitation
    let user: String
    
    /// Name of the habitation property
    let name: String
    
    /// Description of the habitation
    let description: String
    
    /// Type of habitation (apartment, house, etc.)
    let type: String
    
    /// Current reservation status
    let isReserved: Bool
    
    /// Price per unit time
    let price: Int
    
    /// Timestamp when the habitation was created
    let createdAt: String
    
    /// Timestamp when the habitation was last updated
    let updatedAt: String
    
    /// Version field for database management
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case name
        case description
        case type
        case isReserved
        case price
        case createdAt
        case updatedAt
        case v = "__v"
    }
}

/**
 * Represents comprehensive location data for a habitation property.
 * Handles flexible habitation references (both String ID and Object).
 * Contains address information, coordinates, and nearest habitation data.
 */
struct LocationData: Codable, Identifiable {
    /// Unique identifier for the location record
    let id: String
    
    /// Associated habitation ID (always available)
    let habitationId: String
    
    /// Detailed habitation information (optional, depends on API response)
    let habitationDetails: LocationHabitation?
    
    /// Address number or building number
    let addressNo: String
    
    /// Primary address line
    let addressLine01: String
    
    /// Secondary address line
    let addressLine02: String
    
    /// City name
    let city: String
    
    /// District or region name
    let district: String
    
    /// Latitude coordinate
    let latitude: Double
    
    /// Longitude coordinate
    let longitude: Double
    
    /// Latitude of nearest habitation
    let nearestHabitationLatitude: Double
    
    /// Longitude of nearest habitation
    let nearestHabitationLongitude: Double
    
    /// Timestamp when the location was created
    let createdAt: String
    
    /// Timestamp when the location was last updated
    let updatedAt: String
    
    /// Version field for database management
    let v: Int
    
    /**
     * Computed property providing habitation details with fallback.
     * Returns actual details if available, otherwise creates a placeholder.
     */
    var habitation: LocationHabitation {
        return habitationDetails ?? LocationHabitation(
            id: habitationId,
            user: "",
            name: "Unknown",
            description: "",
            type: "Unknown",
            isReserved: false,
            price: 0,
            createdAt: createdAt,
            updatedAt: updatedAt,
            v: 0
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case habitation
        case addressNo
        case addressLine01
        case addressLine02
        case city
        case district
        case latitude
        case longitude
        case nearestHabitationLatitude
        case nearestHabitationLongitude
        case createdAt
        case updatedAt
        case v = "__v"
    }
    
    /**
     * Custom decoder to handle flexible habitation field format.
     * Supports both String ID and full LocationHabitation object.
     */
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        addressNo = try container.decode(String.self, forKey: .addressNo)
        addressLine01 = try container.decode(String.self, forKey: .addressLine01)
        addressLine02 = try container.decode(String.self, forKey: .addressLine02)
        city = try container.decode(String.self, forKey: .city)
        district = try container.decode(String.self, forKey: .district)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        nearestHabitationLatitude = try container.decode(Double.self, forKey: .nearestHabitationLatitude)
        nearestHabitationLongitude = try container.decode(Double.self, forKey: .nearestHabitationLongitude)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        v = try container.decode(Int.self, forKey: .v)
        
        // Handle flexible habitation field (String ID or Object)
        if let habitationString = try? container.decode(String.self, forKey: .habitation) {
            habitationId = habitationString
            habitationDetails = nil
            print("🔍 DEBUG - Decoded habitation as String ID: \(habitationString)")
        } else if let habitationObject = try? container.decode(LocationHabitation.self, forKey: .habitation) {
            habitationId = habitationObject.id
            habitationDetails = habitationObject
            print("🔍 DEBUG - Decoded habitation as Object with ID: \(habitationObject.id)")
        } else {
            let habitationValue = try container.decode(String.self, forKey: .habitation)
            habitationId = habitationValue
            habitationDetails = nil
            print("🔍 DEBUG - Fallback: Decoded habitation as String: \(habitationValue)")
        }
    }
    
    /**
     * Custom encoder to handle flexible habitation field format.
     * Encodes as object if details available, otherwise as string ID.
     */
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(addressNo, forKey: .addressNo)
        try container.encode(addressLine01, forKey: .addressLine01)
        try container.encode(addressLine02, forKey: .addressLine02)
        try container.encode(city, forKey: .city)
        try container.encode(district, forKey: .district)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(nearestHabitationLatitude, forKey: .nearestHabitationLatitude)
        try container.encode(nearestHabitationLongitude, forKey: .nearestHabitationLongitude)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(v, forKey: .v)
        
        // Encode based on available data
        if let details = habitationDetails {
            try container.encode(details, forKey: .habitation)
        } else {
            try container.encode(habitationId, forKey: .habitation)
        }
    }
}

// MARK: - Network Request Models

/**
 * Request payload for creating new location records.
 * Contains all required address and coordinate information.
 */
struct CreateLocationRequest: Codable {
    /// Associated habitation ID
    let habitation: String
    
    /// Address number or building number
    let addressNo: String
    
    /// Primary address line
    let addressLine01: String
    
    /// Secondary address line
    let addressLine02: String
    
    /// City name
    let city: String
    
    /// District or region name
    let district: String
    
    /// Latitude coordinate
    let latitude: Double
    
    /// Longitude coordinate
    let longitude: Double
    
    /// Latitude of nearest habitation
    let nearestHabitationLatitude: Double
    
    /// Longitude of nearest habitation
    let nearestHabitationLongitude: Double
}

// MARK: - Network Response Models

/**
 * Response wrapper for location retrieval operations.
 * Provides success status, message, and location data.
 */
struct GetLocationResponse: Codable {
    /// Operation success status
    let success: Bool
    
    /// Retrieved location data (if successful)
    let data: LocationData?
    
    /// Response message from server
    let message: String?
    
    /**
     * Custom decoder with error handling for location data.
     */
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        data = try container.decodeIfPresent(LocationData.self, forKey: .data)
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }
    
    enum CodingKeys: String, CodingKey {
        case success, data, message
    }
}

/**
 * Response wrapper for location creation operations.
 * Provides success status, message, and created location data.
 */
struct CreateLocationResponse: Codable {
    /// Operation success status
    let success: Bool
    
    /// Response message from server
    let message: String
    
    /// Created location data (if successful)
    let data: LocationData?
    
    /**
     * Custom decoder with comprehensive error handling.
     * Gracefully handles decoding errors for location data.
     */
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        message = try container.decode(String.self, forKey: .message)
        
        // Handle potential decoding errors for data
        do {
            data = try container.decodeIfPresent(LocationData.self, forKey: .data)
        } catch {
            print("🔍 DEBUG - Error decoding location data: \(error)")
            data = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case success, message, data
    }
}

// MARK: - Error Types

/**
 * Enumeration of specific errors that can occur during location operations.
 * Provides localized error descriptions for user-friendly error handling.
 */
enum LocationError: Error, LocalizedError {
    /// Invalid or missing habitation ID
    case invalidHabitationId
    
    /// Location not found for the specified criteria
    case locationNotFound
    
    /// Network communication error
    case networkError(String)
    
    /// Invalid coordinate values
    case invalidCoordinates
    
    /// Missing or incomplete address information
    case missingAddress
    
    /// Data decoding/parsing error
    case decodingError(String)
    
    /**
     * Localized error description for user display.
     */
    var errorDescription: String? {
        switch self {
        case .invalidHabitationId:
            return "Invalid habitation ID provided"
        case .locationNotFound:
            return "Location not found"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidCoordinates:
            return "Invalid coordinates provided"
        case .missingAddress:
            return "Address information is required"
        case .decodingError(let message):
            return "Data decoding error: \(message)"
        }
    }
}

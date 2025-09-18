import Foundation

/**
 * Data models for habitation feature management in the Bodima application.
 * These models represent the physical characteristics and amenities of habitations.
 */

// MARK: - Core Data Models

/**
 * Represents the complete feature set and amenities of a habitation property.
 * Contains detailed information about space, furniture, and utility availability.
 */
struct HabitationFeatureData: Codable, Identifiable {
    /// Unique identifier for the habitation feature record
    let id: String
    
    /// Associated habitation ID that these features belong to
    let habitation: String
    
    /// Total square footage of the habitation
    let sqft: Int
    
    /// Type of family accommodation (e.g., "One Story", "Apartment")
    let familyType: String
    
    /// Number of windows in the habitation
    let windowsCount: Int
    
    /// Number of small beds available
    let smallBedCount: Int
    
    /// Number of large beds available
    let largeBedCount: Int
    
    /// Number of chairs available
    let chairCount: Int
    
    /// Number of tables available
    let tableCount: Int
    
    /// Whether electricity is available
    let isElectricityAvailable: Bool
    
    /// Whether washing machine is available
    let isWachineMachineAvailable: Bool
    
    /// Whether water supply is available
    let isWaterAvailable: Bool
    
    /// Timestamp when the feature record was created
    let createdAt: String
    
    /// Timestamp when the feature record was last updated
    let updatedAt: String
    
    /// Version field for database management
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case habitation
        case sqft
        case familyType
        case windowsCount
        case smallBedCount
        case largeBedCount
        case chairCount
        case tableCount
        case isElectricityAvailable
        case isWachineMachineAvailable
        case isWaterAvailable
        case createdAt
        case updatedAt
        case v = "__v"
    }
}

// MARK: - Enumeration Types

/**
 * Enumeration of supported family accommodation types.
 * Defines the architectural style and structure of habitations.
 */
enum FamilyType: String, CaseIterable, Codable {
    case oneStory = "One Story"
    case twoStory = "Two Story"
    case threeStory = "Three Story"
    case apartment = "Apartment"
    case villa = "Villa"
    case cottage = "Cottage"
    case townhouse = "Townhouse"
    case duplex = "Duplex"
    
    /**
     * Human-readable display name for the family type.
     */
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Network Request Models

/**
 * Request payload for creating new habitation features.
 * Contains all necessary data to establish feature records for a habitation.
 */
struct CreateHabitationFeatureRequest: Codable {
    /// Associated habitation ID
    let habitation: String
    
    /// Total square footage
    let sqft: Int
    
    /// Family accommodation type
    let familyType: String
    
    /// Number of windows
    let windowsCount: Int
    
    /// Number of small beds
    let smallBedCount: Int
    
    /// Number of large beds
    let largeBedCount: Int
    
    /// Number of chairs
    let chairCount: Int
    
    /// Number of tables
    let tableCount: Int
    
    /// Electricity availability
    let isElectricityAvailable: Bool
    
    /// Washing machine availability
    let isWachineMachineAvailable: Bool
    
    /// Water supply availability
    let isWaterAvailable: Bool
}

// MARK: - Network Response Models

/**
 * Response wrapper for habitation feature creation operations.
 * Provides success status, message, and created feature data.
 */
struct CreateHabitationFeatureResponse: Codable {
    /// Operation success status
    let success: Bool
    
    /// Response message from server
    let message: String
    
    /// Created feature data (if successful)
    let data: HabitationFeatureData?
}

/**
 * Response wrapper for habitation feature retrieval operations.
 * Provides success status, message, and feature data.
 */
struct GetHabitationFeatureResponse: Codable {
    /// Operation success status
    let success: Bool
    
    /// Response message from server
    let message: String
    
    /// Retrieved feature data (if successful)
    let data: HabitationFeatureData?
}

/**
 * Response wrapper for multiple habitation features retrieval.
 * Used when fetching arrays of feature data.
 */
struct HabitationFeaturesArrayResponse: Codable {
    /// Operation success status
    let success: Bool
    
    /// Response message from server (optional)
    let message: String?
    
    /// Array of retrieved feature data
    let data: [HabitationFeatureData]
}

/**
 * Alternative response format for direct feature data retrieval.
 * Used when API returns feature data without wrapper structure.
 */
struct DirectHabitationFeatureResponse: Codable {
    /// Operation success status
    let success: Bool
    
    /// Direct feature data
    let data: HabitationFeatureData
}

// MARK: - Error Types

/**
 * Enumeration of specific errors that can occur during habitation feature operations.
 * Provides localized error descriptions for user-friendly error handling.
 */
enum HabitationFeatureError: Error, LocalizedError {
    /// Invalid or missing habitation ID
    case invalidHabitationId
    
    /// Feature record not found
    case featureNotFound
    
    /// Network communication error
    case networkError(String)
    
    /// Invalid square footage value
    case invalidSquareFootage
    
    /// Invalid count values (negative numbers)
    case invalidCountValues
    
    /// Required fields are missing
    case missingRequiredFields
    
    /**
     * Localized error description for user display.
     */
    var errorDescription: String? {
        switch self {
        case .invalidHabitationId:
            return "Invalid habitation ID provided"
        case .featureNotFound:
            return "Habitation features not found"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidSquareFootage:
            return "Invalid square footage provided"
        case .invalidCountValues:
            return "Count values must be non-negative"
        case .missingRequiredFields:
            return "Required fields are missing"
        }
    }
}

import Foundation

/**
 * Data models for habitation image management in the Bodima application.
 * These models represent image data and operations for habitation properties.
 */

// MARK: - Core Data Models

/**
 * Represents image data associated with a habitation property.
 * Contains image URL, metadata, and relationship information.
 */
struct HabitationImageData: Codable, Identifiable {
    /// Unique identifier for the image record
    let id: String
    
    /// Associated habitation ID that this image belongs to
    let habitation: String
    
    /// URL of the image file
    let pictureUrl: String
    
    /// Timestamp when the image record was created
    let createdAt: String
    
    /// Timestamp when the image record was last updated
    let updatedAt: String
    
    /// Version field for database management
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case habitation
        case pictureUrl
        case createdAt
        case updatedAt
        case v = "__v"
    }
}

// MARK: - Network Request Models

/**
 * Request payload for adding new images to a habitation.
 * Contains the habitation reference and image URL.
 */
struct AddHabitationImageRequest: Codable {
    /// Associated habitation ID
    let habitation: String
    
    /// URL of the image to add
    let pictureUrl: String
}

// MARK: - Network Response Models

/**
 * Response wrapper for habitation image addition operations.
 * Provides success status, message, and created image data.
 */
struct AddHabitationImageResponse: Codable {
    /// Operation success status
    let success: Bool
    
    /// Response message from server
    let message: String
    
    /// Created image data (if successful)
    let data: HabitationImageData?
}

/**
 * Response wrapper for habitation image retrieval operations.
 * Provides success status, message, and array of image data.
 */
struct GetHabitationImagesResponse: Codable {
    /// Operation success status
    let success: Bool
    
    /// Response message from server
    let message: String
    
    /// Array of retrieved image data
    let data: [HabitationImageData]?
}

// MARK: - Error Types

/**
 * Enumeration of specific errors that can occur during habitation image operations.
 * Provides localized error descriptions for user-friendly error handling.
 */
enum HabitationImageError: Error, LocalizedError {
    /// Invalid or missing habitation ID
    case invalidHabitationId
    
    /// Invalid or missing image URL
    case invalidImageUrl
    
    /// Image not found
    case imageNotFound
    
    /// Network communication error
    case networkError(String)
    
    /// Image upload failed
    case uploadFailed(String)
    
    /// Image format not supported
    case unsupportedFormat
    
    /// Required fields are missing
    case missingRequiredFields
    
    /**
     * Localized error description for user display.
     */
    var errorDescription: String? {
        switch self {
        case .invalidHabitationId:
            return "Invalid habitation ID provided"
        case .invalidImageUrl:
            return "Invalid image URL provided"
        case .imageNotFound:
            return "Image not found"
        case .networkError(let message):
            return "Network error: \(message)"
        case .uploadFailed(let message):
            return "Image upload failed: \(message)"
        case .unsupportedFormat:
            return "Image format not supported"
        case .missingRequiredFields:
            return "Required fields are missing"
        }
    }
}

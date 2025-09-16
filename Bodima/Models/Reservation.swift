import Foundation

// MARK: - API Response Models
struct APIResponse: Codable {
    let success: Bool
    let message: String
    let data: String?
}

// MARK: - Empty Body for POST requests without body
struct EmptyBody: Codable {
    // Empty struct for POST requests that don't need a body
}

// MARK: - Reservation Request Models
struct CreateReservationRequest: Codable {
    let user: String
    let habitation: String
    let reservedDateTime: String
    let reservationEndDateTime: String
}

// MARK: - Basic Reservation Response Models
struct ReservationData: Codable, Identifiable {
    let id: String
    let user: String
    let habitation: String
    let reservedDateTime: String
    let reservationEndDateTime: String
    let status: String
    let paymentDeadline: String
    let isPaymentCompleted: Bool
    let createdAt: String
    let updatedAt: String
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user, habitation, reservedDateTime, reservationEndDateTime, status, paymentDeadline, isPaymentCompleted, createdAt, updatedAt
        case v = "__v"
    }
}

struct CreateReservationResponse: Codable {
    let success: Bool
    let message: String
    let data: ReservationData?
}

struct GetReservationResponse: Codable {
    let success: Bool
    let data: ReservationData?
    let message: String?
}

// MARK: - Enhanced Reservation Models with Population
struct EnhancedReservationData: Codable, Identifiable {
    let id: String
    let user: EnhancedUserData?
    let habitation: EnhancedHabitationData?
    let reservedDateTime: String
    let reservationEndDateTime: String
    let status: String
    let paymentDeadline: String
    let isPaymentCompleted: Bool
    let createdAt: String
    let updatedAt: String
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user, habitation, reservedDateTime, reservationEndDateTime, status, paymentDeadline, isPaymentCompleted, createdAt, updatedAt
        case v = "__v"
    }
    
    // MARK: - Custom Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        reservedDateTime = try container.decode(String.self, forKey: .reservedDateTime)
        reservationEndDateTime = try container.decode(String.self, forKey: .reservationEndDateTime)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "pending"
        paymentDeadline = try container.decodeIfPresent(String.self, forKey: .paymentDeadline) ?? ""
        isPaymentCompleted = try container.decodeIfPresent(Bool.self, forKey: .isPaymentCompleted) ?? false
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        v = try container.decode(Int.self, forKey: .v)
        
        // Handle optional populated fields
        user = try container.decodeIfPresent(EnhancedUserData.self, forKey: .user)
        habitation = try container.decodeIfPresent(EnhancedHabitationData.self, forKey: .habitation)
    }
    
    // MARK: - Computed Properties
    var userFullName: String {
        guard let user = user else { return "Unknown User" }
        return "\(user.firstName) \(user.lastName)"
    }
    
    var userPhoneNumber: String {
        return user?.phoneNumber ?? "N/A"
    }
    
    var habitationName: String {
        return habitation?.name ?? "Unknown Property"
    }
    
    var habitationDescription: String {
        return habitation?.description ?? "No description available"
    }
    
    var habitationPrice: Int {
        return habitation?.price ?? 0
    }
    
    var habitationType: String {
        return habitation?.type ?? "Unknown Type"
    }
    
    var isHabitationReserved: Bool {
        return habitation?.isReserved ?? false
    }
    
    var reservationDuration: TimeInterval {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let startDate = formatter.date(from: reservedDateTime),
              let endDate = formatter.date(from: reservationEndDateTime) else {
            return 0
        }
        
        return endDate.timeIntervalSince(startDate)
    }
    
    var reservationDurationInDays: Int {
        return Int(reservationDuration / (24 * 60 * 60))
    }
}

// MARK: - Enhanced Response Models
struct GetEnhancedReservationResponse: Codable {
    let success: Bool
    let data: EnhancedReservationData?
    let message: String?
}

struct GetReservationsResponse: Codable {
    let success: Bool
    let data: [ReservationData]?
    let message: String?
}

struct GetEnhancedReservationsResponse: Codable {
    let success: Bool
    let data: [EnhancedReservationData]?
    let message: String?
}
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
    let checkInDate: String
    let checkOutDate: String
    let reservedDateTime: String
    let reservationEndDateTime: String
}

struct CheckAvailabilityRequest: Codable {
    let habitationId: String
    let checkInDate: String
    let checkOutDate: String
}

// MARK: - Basic Reservation Response Models
struct ReservationData: Codable, Identifiable {
    let id: String
    let user: String
    let habitation: String
    let checkInDate: String
    let checkOutDate: String
    let reservedDateTime: String
    let reservationEndDateTime: String
    let status: String
    let paymentDeadline: String
    let isPaymentCompleted: Bool
    let totalDays: Int
    let totalAmount: Int
    let createdAt: String
    let updatedAt: String
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user, habitation, checkInDate, checkOutDate, reservedDateTime, reservationEndDateTime, status, paymentDeadline, isPaymentCompleted, totalDays, totalAmount, createdAt, updatedAt
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
    let checkInDate: String
    let checkOutDate: String
    let reservedDateTime: String
    let reservationEndDateTime: String
    let status: String
    let paymentDeadline: String
    let isPaymentCompleted: Bool
    let totalDays: Int
    let totalAmount: Int
    let createdAt: String
    let updatedAt: String
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user, habitation, checkInDate, checkOutDate, reservedDateTime, reservationEndDateTime, status, paymentDeadline, isPaymentCompleted, totalDays, totalAmount, createdAt, updatedAt
        case v = "__v"
    }
    
    // MARK: - Custom Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        checkInDate = try container.decode(String.self, forKey: .checkInDate)
        checkOutDate = try container.decode(String.self, forKey: .checkOutDate)
        reservedDateTime = try container.decode(String.self, forKey: .reservedDateTime)
        reservationEndDateTime = try container.decode(String.self, forKey: .reservationEndDateTime)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "pending"
        paymentDeadline = try container.decodeIfPresent(String.self, forKey: .paymentDeadline) ?? ""
        isPaymentCompleted = try container.decodeIfPresent(Bool.self, forKey: .isPaymentCompleted) ?? false
        totalDays = try container.decodeIfPresent(Int.self, forKey: .totalDays) ?? 1
        totalAmount = try container.decodeIfPresent(Int.self, forKey: .totalAmount) ?? 0
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

// MARK: - User Reservation History Models
struct UserReservationHistory: Codable {
    let current: [EnhancedReservationData]
    let upcoming: [EnhancedReservationData]
    let past: [EnhancedReservationData]
    let total: Int
}

struct GetUserReservationHistoryResponse: Codable {
    let success: Bool
    let data: UserReservationHistory?
    let message: String?
}

// MARK: - Date Availability Models
struct ReservedDateRange: Codable, Identifiable {
    let id: String
    let checkInDate: String
    let checkOutDate: String
    let status: String
    let user: ReservationUser?
    
    enum CodingKeys: String, CodingKey {
        case id, checkInDate, checkOutDate, status, user
        case _id = "_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode id from either "id" or "_id" key
        if let idValue = try? container.decode(String.self, forKey: .id) {
            self.id = idValue
        } else if let idValue = try? container.decode(String.self, forKey: ._id) {
            self.id = idValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.id, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "No value found for id or _id"
            ))
        }
        
        self.checkInDate = try container.decode(String.self, forKey: .checkInDate)
        self.checkOutDate = try container.decode(String.self, forKey: .checkOutDate)
        self.status = try container.decode(String.self, forKey: .status)
        self.user = try container.decodeIfPresent(ReservationUser.self, forKey: .user)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(checkInDate, forKey: .checkInDate)
        try container.encode(checkOutDate, forKey: .checkOutDate)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(user, forKey: .user)
    }
}

struct ReservationUser: Codable {
    let id: String
    let firstName: String?
    let lastName: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case firstName, lastName
    }
    
    var fullName: String {
        let first = firstName ?? ""
        let last = lastName ?? ""
        return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
    }
}

struct AvailabilityData: Codable {
    let isAvailable: Bool
    let conflictingReservations: [ReservedDateRange]?
}

struct CheckAvailabilityResponse: Codable {
    let success: Bool
    let data: AvailabilityData?
    let message: String?
}

struct GetReservedDatesResponse: Codable {
    let success: Bool
    let data: [ReservedDateRange]?
    let message: String?
}

struct AvailableDateRange: Codable {
    let startDate: String
    let endDate: String
}

struct HabitationAvailabilityData: Codable {
    let availableDates: [AvailableDateRange]
    let reservedDates: [ReservedDateRange]
}

struct GetHabitationAvailabilityResponse: Codable {
    let success: Bool
    let data: HabitationAvailabilityData?
    let message: String?
}
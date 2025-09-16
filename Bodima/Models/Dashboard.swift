import Foundation

// MARK: - Dashboard Models

struct DashboardData: Codable {
    let user: DashboardUser
    let habitations: [DashboardHabitation]
    let statistics: DashboardStatistics
    let recentActivity: RecentActivity
}

struct DashboardUser: Codable {
    let id: String
}

struct DashboardHabitation: Codable, Identifiable {
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
    let reservationHistory: [DashboardReservation]
    let payments: [DashboardPayment]
    let activeReservation: DashboardReservation?
    let reservedUser: EnhancedUserData?
    let totalEarnings: Double
    let reservationCount: Int
    let paymentCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user, name, description, type, isReserved, createdAt, updatedAt, pictures
        case v = "__v"
        case price, reservationHistory, payments, activeReservation, reservedUser
        case totalEarnings, reservationCount, paymentCount
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
    
    var statusText: String {
        if isReserved {
            return "Reserved"
        } else {
            return "Available"
        }
    }
    
    var statusColor: String {
        if isReserved {
            return "red"
        } else {
            return "green"
        }
    }
}

struct DashboardReservation: Codable, Identifiable {
    let id: String
    let user: EnhancedUserData?
    let habitation: DashboardHabitationBasic?
    let reservedDateTime: String
    let reservationEndDateTime: String
    let status: String
    let paymentDeadline: String?
    let isPaymentCompleted: Bool
    let createdAt: String
    let updatedAt: String
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user, habitation, reservedDateTime, reservationEndDateTime, status
        case paymentDeadline, isPaymentCompleted, createdAt, updatedAt
        case v = "__v"
    }
    
    var userFullName: String {
        return user != nil ? "\(user!.firstName) \(user!.lastName)" : "Unknown User"
    }
    
    var statusText: String {
        switch status {
        case "pending":
            return "Pending Payment"
        case "confirmed":
            return "Confirmed"
        case "expired":
            return "Expired"
        case "cancelled":
            return "Cancelled"
        default:
            return status.capitalized
        }
    }
    
    var statusColor: String {
        switch status {
        case "pending":
            return "orange"
        case "confirmed":
            return "green"
        case "expired":
            return "red"
        case "cancelled":
            return "gray"
        default:
            return "blue"
        }
    }
    
    var formattedPaymentDeadline: String {
        guard let paymentDeadline = paymentDeadline else {
            return "No deadline set"
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: paymentDeadline) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return paymentDeadline
    }
}

struct DashboardHabitationBasic: Codable {
    let id: String
    let name: String
    let type: String
    let price: Int
    let user: String?
    let isReserved: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, type, price, user, isReserved
    }
}

struct DashboardPayment: Codable, Identifiable {
    let id: String
    let habitationOwnerId: String
    let reservation: DashboardReservationBasic?
    let amount: Double
    let currencyType: String
    let amountType: String
    let discount: Double
    let totalAmount: Double
    let createdAt: String
    let updatedAt: String
    let v: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case habitationOwnerId, reservation, amount, currencyType, amountType
        case discount, totalAmount, createdAt, updatedAt
        case v = "__v"
    }
    
    var formattedAmount: String {
        return "\(currencyType) \(String(format: "%.2f", totalAmount))"
    }
}

struct DashboardReservationBasic: Codable {
    let id: String
    let habitation: String
    let user: String
    let status: String?
    let isPaymentCompleted: Bool?
    let reservedDateTime: String?
    let reservationEndDateTime: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case habitation, user, status, isPaymentCompleted
        case reservedDateTime, reservationEndDateTime
    }
}

struct DashboardStatistics: Codable {
    let totalHabitations: Int
    let totalReservations: Int
    let totalPayments: Int
    let totalEarnings: Double
    let activeReservations: Int
    let completedReservations: Int
    let availableHabitations: Int
    let reservedHabitations: Int
}

struct RecentActivity: Codable {
    let recentReservations: [DashboardReservation]
    let recentPayments: [DashboardPayment]
}

// MARK: - Dashboard Summary Models

struct DashboardSummary: Codable {
    let habitations: HabitationSummary
    let reservations: ReservationSummary
    let payments: PaymentSummary
}

struct HabitationSummary: Codable {
    let total: Int
    let available: Int
    let reserved: Int
}

struct ReservationSummary: Codable {
    let total: Int
    let active: Int
    let completed: Int
}

struct PaymentSummary: Codable {
    let total: Int
    let totalEarnings: Double
}

// MARK: - API Response Models

struct GetDashboardResponse: Codable {
    let success: Bool
    let data: DashboardData?
    let message: String?
}

struct GetDashboardSummaryResponse: Codable {
    let success: Bool
    let data: DashboardSummary?
    let message: String?
}

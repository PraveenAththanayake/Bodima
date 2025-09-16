import Foundation

// MARK: - Payment Request Model
struct PaymentRequest: Codable {
    let habitationOwnerId: String
    let reservation: String
    let amount: Double
    let currencyType: String
    let amountType: String
    let discount: Double
    
    init(habitationOwnerId: String, reservationId: String, amount: Double, currencyType: String = "LKR", amountType: String = "rent", discount: Double = 0) {
        self.habitationOwnerId = habitationOwnerId
        self.reservation = reservationId
        self.amount = amount
        self.currencyType = currencyType
        self.amountType = amountType
        self.discount = discount
    }
}

// MARK: - Payment Response Model
struct PaymentResponse: Codable {
    let success: Bool
    let message: String
    let data: PaymentData?
}

struct PaymentData: Codable {
    let id: String
    let habitationOwnerId: String
    let reservation: String
    let amount: Double
    let currencyType: String
    let amountType: String
    let discount: Double
    let totalAmount: Double
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case habitationOwnerId, reservation, amount, currencyType, amountType, discount, totalAmount, createdAt, updatedAt
    }
}
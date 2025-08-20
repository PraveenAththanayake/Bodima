import Foundation

// MARK: - Message Model
struct ChatMessage: Identifiable, Codable {
    let id: String
    let sender: String?
    let receiver: String
    let message: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case sender
        case receiver
        case message
        case createdAt
        case updatedAt
    }
    
    func isFromCurrentUser(currentUserId: String) -> Bool {
        return sender == currentUserId
    }
    
    var timestamp: String {
        return createdAt
    }
}

// MARK: - Message Response Model
struct SendMessageResponse: Codable {
    let success: Bool
    let data: ChatMessage?
    let message: String?
} 
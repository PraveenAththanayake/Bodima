import Foundation

struct User: Codable, Identifiable {
    var id: String?
    var email: String
    var username: String
    var firstName: String?
    var lastName: String?
    var profileImageURL: String?
    var bio: String?
    var phoneNumber: String?
    var addressNo: String?
    var addressLine1: String?
    var addressLine2: String?
    var city: String?
    var district: String?
    var createdAt: String?
    var updatedAt: String?
    var hasCompletedProfile: Bool?
    
    var fullName: String? {
        guard let firstName = firstName, let lastName = lastName else {
            return username
        }
        return "\(firstName) \(lastName)"
    }
}


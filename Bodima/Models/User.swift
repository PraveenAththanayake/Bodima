struct User: Codable, Identifiable {
    var id: String?
    var email: String
    var username: String
    var firstName: String?
    var lastName: String?
    var profileImageURL: String?
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

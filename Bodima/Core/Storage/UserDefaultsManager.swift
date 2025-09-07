import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    
    func saveToken(_ token: String) {
        userDefaults.set(token, forKey: AuthConstants.tokenKey)
    }
    
    func getToken() -> String? {
        return userDefaults.string(forKey: AuthConstants.tokenKey)
    }
    
    func saveUser(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: AuthConstants.userKey)
        }
    }
    
    func getUser() -> User? {
        guard let userData = userDefaults.data(forKey: AuthConstants.userKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return nil
        }
        return user
    }
}

extension UserDefaultsManager {
    func updateUserProfileCompletion(_ completed: Bool) {
        if var user = getUser() {
            user.hasCompletedProfile = completed
            saveUser(user)
        }
    }
    
    func saveUserProfileAvailability(_ isAvailable: Bool) {
        UserDefaults.standard.set(isAvailable, forKey: "isUserProfileAvailable")
    }
    
    func getUserProfileAvailability() -> Bool {
        return UserDefaults.standard.bool(forKey: "isUserProfileAvailable")
    }
    
    func clearAuthData() {
        // Clear all auth related data
        UserDefaults.standard.removeObject(forKey: AuthConstants.userKey)
        UserDefaults.standard.removeObject(forKey: AuthConstants.tokenKey)
        UserDefaults.standard.removeObject(forKey: "isUserProfileAvailable")
        UserDefaults.standard.removeObject(forKey: "user_id")
    }
}

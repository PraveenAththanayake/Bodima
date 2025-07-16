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
    
    func clearAuthData() {
        userDefaults.removeObject(forKey: AuthConstants.tokenKey)
        userDefaults.removeObject(forKey: AuthConstants.userKey)
    }
}

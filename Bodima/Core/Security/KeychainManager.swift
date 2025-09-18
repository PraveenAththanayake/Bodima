import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.bodima.app"
    private let biometricTokenKey = "biometric_token"
    private let userCredentialsKey = "user_credentials"
    
    private init() {}
    
    // MARK: - Biometric Token Management
    func saveBiometricToken(_ token: String) -> Bool {
        print("🔐 KeychainManager: Attempting to save biometric token")
        print("🔐 Token length: \(token.count)")
        
        guard let tokenData = token.data(using: .utf8) else {
            print("🔴 Failed to convert token to data")
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: biometricTokenKey,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        let deleteStatus = SecItemDelete(query as CFDictionary)
        print("🔐 Delete existing token status: \(deleteStatus)")
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        let success = status == errSecSuccess
        
        if success {
            print("🔐 ✅ Biometric token saved successfully")
        } else {
            print("🔴 Failed to save biometric token. Status: \(status)")
        }
        
        return success
    }
    
    func getBiometricToken() -> String? {
        print("🔐 KeychainManager: Attempting to retrieve biometric token")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: biometricTokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        print("🔐 Keychain retrieval status: \(status)")
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let token = String(data: data, encoding: .utf8) else {
            print("🔴 No biometric token found in keychain or failed to retrieve")
            return nil
        }
        
        print("🔐 ✅ Biometric token retrieved successfully, length: \(token.count)")
        return token
    }
    
    func deleteBiometricToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: biometricTokenKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - User Credentials Management (for biometric access)
    func saveUserCredentialsForBiometric(email: String, hashedIdentifier: String) -> Bool {
        let credentials = BiometricCredentials(email: email, hashedIdentifier: hashedIdentifier)
        
        guard let credentialsData = try? JSONEncoder().encode(credentials) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: userCredentialsKey,
            kSecValueData as String: credentialsData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func getUserCredentialsForBiometric() -> BiometricCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: userCredentialsKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let credentials = try? JSONDecoder().decode(BiometricCredentials.self, from: data) else {
            return nil
        }
        
        return credentials
    }
    
    func deleteUserCredentialsForBiometric() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: userCredentialsKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Enhanced Token Storage with Biometric Protection
    func saveBiometricTokenWithBiometricProtection(_ token: String) -> Bool {
        guard let tokenData = token.data(using: .utf8) else {
            print("Failed to convert token to data")
            return false
        }
        
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryCurrentSet,
            nil
        ) else {
            print("Failed to create access control")
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(biometricTokenKey)_protected",
            kSecValueData as String: tokenData,
            kSecAttrAccessControl as String: access
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        let success = status == errSecSuccess
        
        if !success {
            print("Failed to save protected biometric token. Status: \(status)")
        }
        
        return success
    }
    
    func getBiometricTokenWithBiometricProtection() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(biometricTokenKey)_protected",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseOperationPrompt as String: "Use biometrics to access your saved login"
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    func deleteBiometricTokenWithBiometricProtection() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "\(biometricTokenKey)_protected"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Clear All Biometric Data
    func clearAllBiometricData() {
        deleteBiometricToken()
        deleteUserCredentialsForBiometric()
        deleteBiometricTokenWithBiometricProtection()
    }
}

// MARK: - BiometricCredentials Model
struct BiometricCredentials: Codable {
    let email: String
    let hashedIdentifier: String
    let createdAt: Date
    
    init(email: String, hashedIdentifier: String) {
        self.email = email
        self.hashedIdentifier = hashedIdentifier
        self.createdAt = Date()
    }
}
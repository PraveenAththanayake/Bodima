import Foundation

class AuthValidator {
    private(set) var lastError: String = ""
    
    func validateSignInInput(email: String, password: String) -> Bool {
        guard !email.isEmpty, !password.isEmpty else {
            lastError = "Please fill in all fields"
            return false
        }
        
        guard isValidEmail(email) else {
            lastError = "Please enter a valid email address"
            return false
        }
        
        return true
    }
    
    func validateSignUpInput(email: String, username: String, password: String, agreedToTerms: Bool) -> Bool {
        guard !email.isEmpty, !username.isEmpty, !password.isEmpty else {
            lastError = "Please fill in all fields"
            return false
        }
        
        guard isValidEmail(email) else {
            lastError = "Please enter a valid email address"
            return false
        }
        
        guard password.count >= AuthConstants.minimumPasswordLength else {
            lastError = "Password must be at least \(AuthConstants.minimumPasswordLength) characters long"
            return false
        }
        
        guard username.count >= AuthConstants.minimumUsernameLength else {
            lastError = "Username must be at least \(AuthConstants.minimumUsernameLength) characters long"
            return false
        }
        
        guard agreedToTerms else {
            lastError = "Please agree to the Terms of Service and Privacy Policy"
            return false
        }
        
        return true
    }
    
    func validateProfileInput(firstName: String, lastName: String) -> Bool {
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty,
              !lastName.trimmingCharacters(in: .whitespaces).isEmpty else {
            lastError = "Please enter your first and last name"
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

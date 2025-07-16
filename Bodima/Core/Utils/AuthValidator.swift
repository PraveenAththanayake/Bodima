import Foundation

class AuthValidator {
    var lastError: String = ""
    
    func validateSignInInput(email: String, password: String) -> Bool {
        lastError = ""
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        if trimmedEmail.isEmpty {
            lastError = "Email is required"
            return false
        }
        
        if !isValidEmail(trimmedEmail) {
            lastError = "Please enter a valid email address"
            return false
        }
        
        if password.isEmpty {
            lastError = "Password is required"
            return false
        }
        
        return true
    }
    
    func validateSignUpInput(email: String, username: String, password: String, agreedToTerms: Bool) -> Bool {
        lastError = ""
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        if trimmedEmail.isEmpty {
            lastError = "Email is required"
            return false
        }
        
        if !isValidEmail(trimmedEmail) {
            lastError = "Please enter a valid email address"
            return false
        }
        
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        if trimmedUsername.isEmpty {
            lastError = "Username is required"
            return false
        }
        
        if trimmedUsername.count < 3 {
            lastError = "Username must be at least 3 characters"
            return false
        }
        
        if password.isEmpty {
            lastError = "Password is required"
            return false
        }
        
        if password.count < 6 {
            lastError = "Password must be at least 6 characters"
            return false
        }
        
        if !agreedToTerms {
            lastError = "You must agree to the terms and conditions"
            return false
        }
        
        return true
    }
    
    func validateProfileInput(firstName: String, lastName: String) -> Bool {
        lastError = ""
        
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        if trimmedFirstName.isEmpty {
            lastError = "First name is required"
            return false
        }
        
        if trimmedFirstName.count < 2 {
            lastError = "First name must be at least 2 characters"
            return false
        }
        
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespaces)
        if trimmedLastName.isEmpty {
            lastError = "Last name is required"
            return false
        }
        
        if trimmedLastName.count < 2 {
            lastError = "Last name must be at least 2 characters"
            return false
        }
        
        return true
    }
    
    func validateCompleteProfileInput(
        firstName: String,
        lastName: String,
        phoneNumber: String,
        addressNo: String,
        addressLine1: String,
        city: String,
        district: String
    ) -> Bool {
        // Clear previous errors
        lastError = ""
        
        // Validate first name
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        if trimmedFirstName.isEmpty {
            lastError = "First name is required"
            return false
        }
        
        if trimmedFirstName.count < 2 {
            lastError = "First name must be at least 2 characters"
            return false
        }
        
        // Validate last name
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespaces)
        if trimmedLastName.isEmpty {
            lastError = "Last name is required"
            return false
        }
        
        if trimmedLastName.count < 2 {
            lastError = "Last name must be at least 2 characters"
            return false
        }
        
        // Validate phone number
        let trimmedPhoneNumber = phoneNumber.trimmingCharacters(in: .whitespaces)
        if trimmedPhoneNumber.isEmpty {
            lastError = "Phone number is required"
            return false
        }
        
        if trimmedPhoneNumber.count < 10 {
            lastError = "Please enter a valid phone number"
            return false
        }
        
        // Validate address fields
        if addressNo.trimmingCharacters(in: .whitespaces).isEmpty {
            lastError = "Address number is required"
            return false
        }
        
        if addressLine1.trimmingCharacters(in: .whitespaces).isEmpty {
            lastError = "Address Line 1 is required"
            return false
        }
        
        if city.trimmingCharacters(in: .whitespaces).isEmpty {
            lastError = "City is required"
            return false
        }
        
        if district.trimmingCharacters(in: .whitespaces).isEmpty {
            lastError = "District is required"
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}


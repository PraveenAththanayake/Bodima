import SwiftUI

struct SignUpView: View {
    @ObservedObject private var authViewModel = AuthViewModel.shared
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isSecureTextEntry = true
    @State private var agreedToTerms = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    
                    formSection
                    
                    createAccountButton
                    
                    alertSection
                    
                    Spacer(minLength: 50)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(AppColors.background)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Create Account")
                .font(.system(size: 34, weight: .bold, design: .default))
                .foregroundColor(AppColors.foreground)
                .padding(.top, 60)
            
            Text("Join thousands of users who trust our platform")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(AppColors.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 48)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 24) {
            emailField
            usernameField
            passwordField
            termsAgreementSection
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Form Fields
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.foreground)
            
            TextField("Enter your email", text: $email)
                .font(.system(size: 17))
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(inputFieldBackground)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
        }
    }
    
    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Username")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.foreground)
            
            TextField("Choose a username", text: $username)
                .font(.system(size: 17))
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(inputFieldBackground)
                .autocapitalization(.none)
                .textContentType(.username)
        }
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.foreground)
            
            HStack {
                Group {
                    if isSecureTextEntry {
                        SecureField("Create a password", text: $password)
                    } else {
                        TextField("Create a password", text: $password)
                    }
                }
                .font(.system(size: 17))
                .textContentType(.newPassword)
                
                passwordVisibilityToggle
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(inputFieldBackground)
        }
    }
    
    private var passwordVisibilityToggle: some View {
        Button(action: {
            isSecureTextEntry.toggle()
        }) {
            Image(systemName: isSecureTextEntry ? "eye.slash" : "eye")
                .foregroundColor(AppColors.mutedForeground)
                .font(.system(size: 16, weight: .medium))
        }
    }
    
    private var inputFieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppColors.input)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.border, lineWidth: 0.5)
            )
    }
    
    // MARK: - Terms Agreement Section
    private var termsAgreementSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: $agreedToTerms)
                .toggleStyle(CheckboxToggleStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("I agree to the Terms of Service and Privacy Policy")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.foreground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - Create Account Button
    private var createAccountButton: some View {
        Button(action: handleCreateAccount) {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryForeground))
                        .scaleEffect(0.9)
                        .padding(.trailing, 8)
                }
                
                Text(authViewModel.isLoading ? "Creating Account..." : "Create Account")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppColors.primaryForeground)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.primary)
            )
            .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(authViewModel.isLoading)
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }
    
    // MARK: - Alert Section
    private var alertSection: some View {
        Group {
            if let alertMessage = authViewModel.alertMessage {
                AlertView(alertMessage: alertMessage) {
                    authViewModel.clearAlert()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
    }
    
    // MARK: - Actions
    private func handleCreateAccount() {
        authViewModel.signUp(
            email: email,
            username: username,
            password: password,
            agreedToTerms: agreedToTerms
        )
    }
}

// MARK: - Alert View Component
struct AlertView: View {
    let alertMessage: AlertMessage
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            alertIcon
            
            Text(alertMessage.message)
                .font(.system(size: 15))
                .foregroundColor(alertTextColor)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            dismissButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(alertBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(alertBorderColor, lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: alertMessage.message)
    }
    
    private var alertIcon: some View {
        Image(systemName: iconName)
            .foregroundColor(alertIconColor)
            .font(.system(size: 14, weight: .medium))
    }
    
    private var dismissButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .foregroundColor(alertIconColor.opacity(0.7))
                .font(.system(size: 12, weight: .medium))
        }
    }
    
    private var iconName: String {
        switch alertMessage.type {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .warning:
            return "exclamationmark.triangle"
        case .info:
            return "info.circle.fill"
        }
    }
    
    private var alertIconColor: Color {
        switch alertMessage.type {
        case .success:
            return Color.green
        case .error:
            return Color.red
        case .warning:
            return Color.orange
        case .info:
            return Color.blue
        }
    }
    
    private var alertTextColor: Color {
        switch alertMessage.type {
        case .success:
            return Color.green.opacity(0.9)
        case .error:
            return Color.red.opacity(0.9)
        case .warning:
            return Color.orange.opacity(0.9)
        case .info:
            return Color.blue.opacity(0.9)
        }
    }
    
    private var alertBackgroundColor: Color {
        switch alertMessage.type {
        case .success:
            return Color.green.opacity(0.1)
        case .error:
            return Color.red.opacity(0.1)
        case .warning:
            return Color.orange.opacity(0.1)
        case .info:
            return Color.blue.opacity(0.1)
        }
    }
    
    private var alertBorderColor: Color {
        switch alertMessage.type {
        case .success:
            return Color.green.opacity(0.3)
        case .error:
            return Color.red.opacity(0.3)
        case .warning:
            return Color.orange.opacity(0.3)
        case .info:
            return Color.blue.opacity(0.3)
        }
    }
}

#Preview {
    SignUpView()
}

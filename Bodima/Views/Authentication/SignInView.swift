import SwiftUI
import LocalAuthentication

struct SignInView: View {
    @StateObject private var authViewModel = AuthViewModel.shared
    @StateObject private var biometricManager = BiometricManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSecureTextEntry = true
    @State private var rememberMe = false
    @State private var showingForgotPassword = false
    @State private var showingSignUp = false
    @State private var showingBiometricError = false
    @State private var biometricErrorMessage = ""
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 12) {
                        Text("Welcome Back")
                            .font(SwiftUI.Font.system(size: 34, weight: .bold, design: .default))
                            .foregroundColor(AppColors.foreground)
                            .padding(.top, 60)
                        
                        Text("Sign in to your account to continue")
                            .font(SwiftUI.Font.system(size: 17, weight: .regular))
                            .foregroundColor(AppColors.mutedForeground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 48)
                    
                    // Form Section
                    VStack(spacing: 24) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(SwiftUI.Font.system(size: 15, weight: .medium))
                                .foregroundColor(AppColors.foreground)
                            
                            TextField("Enter your email", text: $email)
                                .font(SwiftUI.Font.system(size: 17))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.input)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppColors.border, lineWidth: 0.5)
                                        )
                                )
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .disabled(authViewModel.isLoading)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(SwiftUI.Font.system(size: 15, weight: .medium))
                                .foregroundColor(AppColors.foreground)
                            
                            HStack {
                                Group {
                                    if isSecureTextEntry {
                                        SecureField("Enter your password", text: $password)
                                    } else {
                                        TextField("Enter your password", text: $password)
                                    }
                                }
                                .font(SwiftUI.Font.system(size: 17))
                                .textContentType(.password)
                                .disabled(authViewModel.isLoading)
                                
                                Button(action: {
                                    isSecureTextEntry.toggle()
                                }) {
                                    Image(systemName: isSecureTextEntry ? "eye.slash" : "eye")
                                        .foregroundColor(AppColors.mutedForeground)
                                        .font(SwiftUI.Font.system(size: 16, weight: .medium))
                                }
                                .disabled(authViewModel.isLoading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.input)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.border, lineWidth: 0.5)
                                    )
                            )
                        }
                        
                        // Remember Me & Forgot Password
                        HStack(alignment: .top, spacing: 12) {
                            Toggle("", isOn: $rememberMe)
                                .toggleStyle(CheckboxToggleStyle())
                                .disabled(authViewModel.isLoading)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Remember me")
                                    .font(SwiftUI.Font.system(size: 15))
                                    .foregroundColor(AppColors.foreground)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingForgotPassword = true
                            }) {
                                Text("Forgot Password?")
                                    .font(SwiftUI.Font.system(size: 15))
                                    .foregroundColor(AppColors.primary)
                            }
                            .disabled(authViewModel.isLoading)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    // Sign In Button
                    Button(action: {
                        handleSignIn()
                    }) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryForeground))
                                    .scaleEffect(0.9)
                                    .padding(.trailing, 8)
                            }
                            
                            Text(authViewModel.isLoading ? "Signing In..." : "Sign In")
                                .font(SwiftUI.Font.system(size: 17, weight: .semibold))
                                .foregroundColor(AppColors.primaryForeground)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(authViewModel.isLoading ? AppColors.primary.opacity(0.6) : AppColors.primary)
                        )
                        .shadow(
                            color: authViewModel.isLoading ? Color.clear : AppColors.primary.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                    .disabled(authViewModel.isLoading || !isFormValid)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    
                    // Alert Message Display
                    if let alertMessage = authViewModel.alertMessage {
                        AlertBanner(message: alertMessage) {
                            authViewModel.clearAlert()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    
                    // Biometric Authentication Section
                    if biometricManager.isBiometricAvailable && biometricManager.isBiometricEnabled {
                        BiometricSignInSection()
                            .onAppear {
                                // Perform a safety check when the biometric section appears
                                let testResult = biometricManager.testBiometricAvailability()
                                if !testResult.available {
                                    print("🔴 Biometric section appeared but biometric not available: \(testResult.error ?? "Unknown")")
                                }
                            }
                    }
                    
                    // Sign Up Navigation
                    HStack {
                        Text("Don't have an account?")
                            .font(SwiftUI.Font.system(size: 15))
                            .foregroundColor(AppColors.mutedForeground)
                        
                        Button("Sign Up") {
                            showingSignUp = true
                        }
                        .font(SwiftUI.Font.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.primary)
                    }
                    .padding(.top, 32)
                    
                    Spacer(minLength: 50)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(AppColors.background)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
        .fullScreenCover(isPresented: $showingSignUp) {
            SignUpView()
        }
        .onSubmit {
            handleSignIn()
        }
        .onAppear {
            // Check if biometric authentication is available and enabled
            if biometricManager.isBiometricAvailable && biometricManager.isBiometricEnabled {
                // Auto-trigger biometric authentication if conditions are met
                // This is optional - you can remove this if you want manual biometric login only
            }
        }
        .alert("Biometric Authentication Error", isPresented: $showingBiometricError) {
            Button("OK") {
                showingBiometricError = false
            }
        } message: {
            Text(biometricErrorMessage)
        }
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        return !email.trimmingCharacters(in: .whitespaces).isEmpty &&
               !password.isEmpty &&
               email.contains("@") &&
               password.count >= 6
    }
    
    // MARK: - Methods
    private func handleSignIn() {
        // Clear any existing alerts
        authViewModel.clearAlert()
        
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Trigger sign in through AuthViewModel
        authViewModel.signIn(
            email: email.trimmingCharacters(in: .whitespaces),
            password: password,
            rememberMe: rememberMe
        )
    }
}

#Preview {
    NavigationView {
        SignInView()
    }
}

// MARK: - Biometric Sign In Section
struct BiometricSignInSection: View {
    @StateObject private var biometricManager = BiometricManager.shared
    @StateObject private var authViewModel = AuthViewModel.shared
    @State private var showingBiometricError = false
    @State private var biometricErrorMessage = ""
    @State private var isBiometricLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Divider with "OR" text
            HStack {
                Rectangle()
                    .fill(AppColors.border)
                    .frame(height: 1)
                
                Text("OR")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(AppColors.border)
                    .frame(height: 1)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // Biometric Sign In Button
            Button(action: {
                handleBiometricSignIn()
            }) {
                HStack(spacing: 12) {
                    if isBiometricLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: biometricManager.getBiometricIcon())
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    Text(isBiometricLoading ? "Authenticating..." : "Sign in with \(biometricManager.getBiometricTypeString())")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isBiometricLoading ? AppColors.primary.opacity(0.6) : AppColors.primary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColors.primary.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(isBiometricLoading)
            .padding(.horizontal, 24)
            
            // Biometric Info Text
            Text("Use your \(biometricManager.getBiometricTypeString().lowercased()) to sign in securely")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .alert("Biometric Authentication", isPresented: $showingBiometricError) {
            Button("OK") {
                showingBiometricError = false
            }
        } message: {
            Text(biometricErrorMessage)
        }
    }
    
    private func handleBiometricSignIn() {
        // Check if biometric authentication is properly available
        let testResult = biometricManager.testBiometricAvailability()
        guard testResult.available else {
            biometricErrorMessage = testResult.error ?? "Biometric authentication not available"
            showingBiometricError = true
            return
        }
        
        guard biometricManager.isBiometricEnabled else {
            biometricErrorMessage = "Biometric authentication is not enabled. Please enable it in your profile settings."
            showingBiometricError = true
            return
        }
        
        isBiometricLoading = true
        
        Task {
            do {
                let result = await biometricManager.authenticateWithBiometrics()
                
                await MainActor.run {
                    self.isBiometricLoading = false
                    
                    switch result {
                    case .success(let token):
                        guard !token.isEmpty else {
                            self.biometricErrorMessage = "Invalid authentication token received"
                            self.showingBiometricError = true
                            return
                        }
                        // Verify token with backend and sign in
                        self.authViewModel.signInWithBiometric(token: token)
                        
                    case .failure(let error):
                        self.biometricErrorMessage = error.localizedDescription
                        self.showingBiometricError = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isBiometricLoading = false
                    self.biometricErrorMessage = "Authentication failed: \(error.localizedDescription)"
                    self.showingBiometricError = true
                }
            }
        }
    }
}

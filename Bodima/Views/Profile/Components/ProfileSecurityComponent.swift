import SwiftUI
import LocalAuthentication

// Profile security settings component with biometric authentication management
// Handles biometric toggle, availability checking, and security information display
struct ProfileSecurityComponent: View {
    @StateObject private var biometricManager = BiometricManager.shared
    @StateObject private var authViewModel = AuthViewModel.shared
    @State private var showingBiometricAlert = false
    @State private var biometricAlertMessage = ""
    @State private var showingConfirmationAlert = false
    
    var body: some View {
        ProfileCardComponent(title: "Security Settings") {
            VStack(spacing: 16) {
                if biometricManager.isBiometricAvailable {
                    BiometricToggleComponent(
                        biometricManager: biometricManager,
                        showingAlert: $showingBiometricAlert,
                        alertMessage: $biometricAlertMessage,
                        showingConfirmation: $showingConfirmationAlert
                    )
                } else {
                    BiometricUnavailableComponent(biometricManager: biometricManager)
                }
                
                Divider()
                    .background(AppColors.border)
                
                SecurityInfoComponent()
            }
        }
        .alert("Biometric Authentication", isPresented: $showingBiometricAlert) {
            Button("OK") {
                showingBiometricAlert = false
            }
        } message: {
            Text(biometricAlertMessage)
        }
        .alert("Disable Biometric Authentication?", isPresented: $showingConfirmationAlert) {
            Button("Cancel", role: .cancel) {
                showingConfirmationAlert = false
            }
            Button("Disable", role: .destructive) {
                disableBiometric()
                showingConfirmationAlert = false
            }
        } message: {
            Text("This will remove your saved biometric login. You'll need to enable it again and sign in with your password.")
        }
    }
    
    // Disable biometric authentication and clear stored tokens
    private func disableBiometric() {
        biometricManager.setBiometricEnabled(false)
        biometricManager.clearBiometricToken()
    }
}

// Biometric toggle component with interactive switch and status display
// Manages biometric authentication enabling/disabling with proper feedback
struct BiometricToggleComponent: View {
    @ObservedObject var biometricManager: BiometricManager
    @Binding var showingAlert: Bool
    @Binding var alertMessage: String
    @Binding var showingConfirmation: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Biometric type icon with state-based styling
            ZStack {
                Circle()
                    .fill(biometricManager.isBiometricEnabled ? AppColors.primary.opacity(0.1) : AppColors.input)
                    .frame(width: 40, height: 40)
                
                Image(systemName: biometricManager.getBiometricIcon())
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(biometricManager.isBiometricEnabled ? AppColors.primary : AppColors.mutedForeground)
            }
            
            // Biometric status and description text
            VStack(alignment: .leading, spacing: 2) {
                Text(biometricManager.getBiometricTypeString())
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                Text(biometricManager.isBiometricEnabled ? "Enabled" : "Sign in with \(biometricManager.getBiometricTypeString().lowercased())")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
            
            // Interactive toggle switch
            Toggle("", isOn: .init(
                get: { biometricManager.isBiometricEnabled },
                set: { _ in toggleBiometric() }
            ))
            .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(biometricManager.getBiometricTypeString()) authentication")
        .accessibilityValue(biometricManager.isBiometricEnabled ? "Enabled" : "Disabled")
        .accessibilityHint("Double tap to toggle biometric authentication")
    }
    
    // Handle biometric toggle with confirmation for disabling
    private func toggleBiometric() {
        if biometricManager.isBiometricEnabled {
            showingConfirmation = true
        } else {
            enableBiometric()
        }
    }
    
    // Enable biometric authentication with token storage
    private func enableBiometric() {
        guard let token = AuthViewModel.shared.jwtToken, !token.isEmpty else {
            alertMessage = "No valid session found. Please sign in again."
            showingAlert = true
            return
        }
        
        Task {
            do {
                let success = biometricManager.storeBiometricToken(token)
                
                await MainActor.run {
                    if success {
                        biometricManager.setBiometricEnabled(true)
                        alertMessage = "\(biometricManager.getBiometricTypeString()) has been enabled successfully!"
                    } else {
                        alertMessage = "Failed to store authentication data. Please try again."
                    }
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Error enabling biometric authentication: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// Biometric unavailable component for devices without biometric support
// Displays informative message when biometric authentication is not available
struct BiometricUnavailableComponent: View {
    @ObservedObject var biometricManager: BiometricManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Warning icon for unavailable state
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            // Unavailability message
            VStack(alignment: .leading, spacing: 2) {
                Text("Biometric Authentication")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                Text("Not available on this device")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Biometric authentication not available on this device")
    }
}

// Security information component with privacy details
// Provides user education about biometric data security and privacy
struct SecurityInfoComponent: View {
    var body: some View {
        HStack(spacing: 12) {
            // Information icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.primary)
            }
            
            // Security information text
            VStack(alignment: .leading, spacing: 2) {
                Text("Security Information")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                Text("Your biometric data is stored securely on your device and never shared")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Security information: Your biometric data is stored securely on your device and never shared")
    }
}

#Preview {
    ProfileSecurityComponent()
}

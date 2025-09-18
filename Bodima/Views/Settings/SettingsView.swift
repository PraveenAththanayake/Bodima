import SwiftUI

struct AccessibilitySettingsView: View {
    // Settings state management
    @StateObject private var accessibilityViewModel: AccessibilityViewModel = AccessibilityViewModel()
    @StateObject private var authViewModel = AuthViewModel.shared
    @Environment(\.dismiss) private var dismiss
    
    // Main view body orchestrating modular components
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with app branding and context
                    SettingsHeaderComponent()
                    
                    // Accessibility settings with comprehensive options
                    SettingsAccessibilityComponent(accessibilityViewModel: accessibilityViewModel)
                    
                    // Account management and privacy settings
                    SettingsAccountComponent()
                    
                    // App preferences and customization options
                    SettingsPreferencesComponent()
                    
                    // Support information and legal documents
                    SettingsSupportComponent()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                }
            }
            .onAppear {
                loadAccessibilitySettings()
            }
            .alert("Error", isPresented: $accessibilityViewModel.hasError) {
                Button("OK") {
                    accessibilityViewModel.hasError = false
                }
            } message: {
                Text(accessibilityViewModel.errorMessage ?? "An error occurred")
            }
            .overlay(
                // Success message overlay with animation
                Group {
                    if accessibilityViewModel.showSaveSuccess {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(accessibilityViewModel.saveSuccessMessage ?? "Settings saved!")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.8))
                            )
                            .padding(.bottom, 100)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: accessibilityViewModel.showSaveSuccess)
                    }
                }
            )
        }
    }
    
    // Settings loading and persistence functions
    // Handles local and server-side settings synchronization
    private func loadAccessibilitySettings() {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        accessibilityViewModel.loadLocalSettings()
        accessibilityViewModel.fetchAccessibilitySettings(userId: userId)
    }
    
    // Settings save functionality with user authentication
    private func saveAccessibilitySettings() {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        accessibilityViewModel.updateAccessibilitySettings(userId: userId)
    }
}

// Accessibility toggle row component with state management
// Provides interactive toggle with visual feedback and accessibility support
struct AccessibilityToggleRow: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with state-based styling
            ZStack {
                Circle()
                    .fill(isOn ? AppColors.primary.opacity(0.1) : AppColors.input)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isOn ? AppColors.primary : AppColors.mutedForeground)
            }
            
            // Text content with accessibility support
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.foreground)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.mutedForeground)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Toggle switch with callback action
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { _ in action() }
            ))
            .toggleStyle(SwitchToggleStyle(tint: AppColors.primary))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint("Double tap to toggle")
    }
}

// Settings card container component with consistent styling
// Provides reusable card layout for settings sections
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.primary)
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.foreground)
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        )
        .shadow(color: AppColors.border.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// Settings row component for navigation and actions
// Provides consistent row layout with icon, text, and navigation arrow
struct SettingsRow: View {
    let title: String
    let description: String
    let icon: String
    let showArrow: Bool
    let action: () -> Void
    
    init(
        title: String,
        description: String,
        icon: String,
        showArrow: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.showArrow = showArrow
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon with consistent styling
                ZStack {
                    Circle()
                        .fill(AppColors.input)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                // Text content with proper spacing
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.foreground)
                    
                    Text(description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Navigation arrow when applicable
                if showArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
        .accessibilityHint("Double tap to open")
    }
}

#Preview {
    AccessibilitySettingsView()
}

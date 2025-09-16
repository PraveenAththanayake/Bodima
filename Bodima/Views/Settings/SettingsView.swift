import SwiftUI

struct AccessibilitySettingsView: View {
    @StateObject private var accessibilityViewModel: AccessibilityViewModel = AccessibilityViewModel()
    @StateObject private var authViewModel = AuthViewModel.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    SettingsHeaderView()
                    AccessibilitySettingsSection(accessibilityViewModel: accessibilityViewModel)
                    AccountSettingsSection()
                    AppSettingsSection()
                    AboutSection()
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
                // Success message overlay
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
    
    private func loadAccessibilitySettings() {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        // Load local settings first for immediate UI update
        accessibilityViewModel.loadLocalSettings()
        
        // Then fetch from server
        accessibilityViewModel.fetchAccessibilitySettings(userId: userId)
    }
    
    private func saveAccessibilitySettings() {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        accessibilityViewModel.updateAccessibilitySettings(userId: userId)
    }
}

// MARK: - Settings Header
struct SettingsHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(AppColors.primary)
            
            Text("App Settings")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.foreground)
            
            Text("Customize your experience")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.mutedForeground)
        }
        .padding(.top, 20)
    }
}

// MARK: - Accessibility Settings Section
struct AccessibilitySettingsSection: View {
    @ObservedObject var accessibilityViewModel: AccessibilityViewModel
    @StateObject private var authViewModel = AuthViewModel.shared
    
    var body: some View {
        AccessibilityCard {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    AccessibilityImage(systemName: "accessibility", size: 18, accessibilityLabel: "Accessibility")
                    AccessibilityText("Accessibility", size: 18, weight: .bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                AccessibilityToggle(
                    isOn: $accessibilityViewModel.accessibilitySettings.largeText,
                    title: "Large Text",
                    description: "Increase text size throughout the app",
                    icon: "textformat.size"
                )
                
                AccessibilityDivider()
                
                AccessibilityToggle(
                    isOn: $accessibilityViewModel.accessibilitySettings.highContrast,
                    title: "High Contrast",
                    description: "Enhance visual contrast for better readability",
                    icon: "circle.lefthalf.filled"
                )
                
                AccessibilityDivider()
                
                AccessibilityToggle(
                    isOn: $accessibilityViewModel.accessibilitySettings.reduceMotion,
                    title: "Reduce Motion",
                    description: "Minimize animations and transitions",
                    icon: "tortoise"
                )
                
                AccessibilityDivider()
                
                AccessibilityToggle(
                    isOn: $accessibilityViewModel.accessibilitySettings.voiceOver,
                    title: "VoiceOver Support",
                    description: "Enhanced screen reader compatibility",
                    icon: "speaker.wave.3"
                )
                
                AccessibilityDivider()
                
                AccessibilityToggle(
                    isOn: $accessibilityViewModel.accessibilitySettings.screenReader,
                    title: "Screen Reader",
                    description: "Optimize for screen reading software",
                    icon: "text.cursor"
                )
                
                AccessibilityDivider()
                
                AccessibilityToggle(
                    isOn: $accessibilityViewModel.accessibilitySettings.colorBlindAssist,
                    title: "Color Blind Assist",
                    description: "Enhanced color differentiation",
                    icon: "eyedropper.halffull"
                )
                
                AccessibilityDivider()
                
                AccessibilityToggle(
                    isOn: $accessibilityViewModel.accessibilitySettings.hapticFeedback,
                    title: "Haptic Feedback",
                    description: "Vibration feedback for interactions",
                    icon: "iphone.radiowaves.left.and.right"
                )
                
                // Reset button
                Button(action: {
                    accessibilityViewModel.resetToDefaults()
                }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .medium))
                        Text("Reset to Defaults")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColors.primary, lineWidth: 1)
                    )
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func saveSettings() {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        accessibilityViewModel.updateAccessibilitySettings(userId: userId)
    }
}

// MARK: - Accessibility Toggle Row
struct AccessibilityToggleRow: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isOn ? AppColors.primary.opacity(0.1) : AppColors.input)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isOn ? AppColors.primary : AppColors.mutedForeground)
            }
            
            // Text Content
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
            
            // Toggle Switch
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

// MARK: - Account Settings Section
struct AccountSettingsSection: View {
    var body: some View {
        SettingsCard(title: "Account", icon: "person.circle") {
            VStack(spacing: 16) {
                SettingsRow(
                    title: "Edit Profile",
                    description: "Update your personal information",
                    icon: "pencil",
                    action: {
                        // Navigate to edit profile
                    }
                )
                
                Divider().background(AppColors.border)
                
                SettingsRow(
                    title: "Privacy Settings",
                    description: "Manage your privacy preferences",
                    icon: "lock.shield",
                    action: {
                        // Navigate to privacy settings
                    }
                )
                
                Divider().background(AppColors.border)
                
                SettingsRow(
                    title: "Notification Settings",
                    description: "Configure push notifications",
                    icon: "bell",
                    action: {
                        // Navigate to notification settings
                    }
                )
            }
        }
    }
}

// MARK: - App Settings Section
struct AppSettingsSection: View {
    var body: some View {
        SettingsCard(title: "App Preferences", icon: "slider.horizontal.3") {
            VStack(spacing: 16) {
                SettingsRow(
                    title: "Language",
                    description: "Change app language",
                    icon: "globe",
                    action: {
                        // Navigate to language settings
                    }
                )
                
                Divider().background(AppColors.border)
                
                SettingsRow(
                    title: "Theme",
                    description: "Light or dark mode",
                    icon: "paintbrush",
                    action: {
                        // Navigate to theme settings
                    }
                )
                
                Divider().background(AppColors.border)
                
                SettingsRow(
                    title: "Data & Storage",
                    description: "Manage app data and cache",
                    icon: "externaldrive",
                    action: {
                        // Navigate to data settings
                    }
                )
            }
        }
    }
}

// MARK: - About Section
struct AboutSection: View {
    var body: some View {
        SettingsCard(title: "About", icon: "info.circle") {
            VStack(spacing: 16) {
                SettingsRow(
                    title: "App Version",
                    description: "1.0.0 (Build 1)",
                    icon: "app.badge",
                    showArrow: false,
                    action: {}
                )
                
                Divider().background(AppColors.border)
                
                SettingsRow(
                    title: "Terms of Service",
                    description: "Read our terms and conditions",
                    icon: "doc.text",
                    action: {
                        // Navigate to terms
                    }
                )
                
                Divider().background(AppColors.border)
                
                SettingsRow(
                    title: "Privacy Policy",
                    description: "Learn about our privacy practices",
                    icon: "hand.raised",
                    action: {
                        // Navigate to privacy policy
                    }
                )
                
                Divider().background(AppColors.border)
                
                SettingsRow(
                    title: "Contact Support",
                    description: "Get help with the app",
                    icon: "questionmark.circle",
                    action: {
                        // Navigate to support
                    }
                )
            }
        }
    }
}

// MARK: - Settings Card
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

// MARK: - Settings Row
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
                // Icon
                ZStack {
                    Circle()
                        .fill(AppColors.input)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.mutedForeground)
                }
                
                // Text Content
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
                
                // Arrow
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

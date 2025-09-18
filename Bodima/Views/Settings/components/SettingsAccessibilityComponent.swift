import SwiftUI

// Accessibility settings component with toggle options
// Manages accessibility preferences and provides reset functionality
struct SettingsAccessibilityComponent: View {
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
                
                // Reset to defaults button
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
    
    // Settings save functionality with user authentication
    private func saveSettings() {
        guard let userId = authViewModel.currentUser?.id ?? UserDefaults.standard.string(forKey: "user_id") else {
            return
        }
        
        accessibilityViewModel.updateAccessibilitySettings(userId: userId)
    }
}

import SwiftUI

// Support and about component with app information and help options
// Provides version information, legal documents, and support access
struct SettingsSupportComponent: View {
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

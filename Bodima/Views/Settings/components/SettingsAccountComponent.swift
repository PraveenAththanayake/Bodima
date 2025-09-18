import SwiftUI

// Account settings component with profile and privacy options
// Handles user account management and privacy preferences
struct SettingsAccountComponent: View {
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

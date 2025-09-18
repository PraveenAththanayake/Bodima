import SwiftUI

// App preferences component with language, theme, and data settings
// Manages application-wide preferences and customization options
struct SettingsPreferencesComponent: View {
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

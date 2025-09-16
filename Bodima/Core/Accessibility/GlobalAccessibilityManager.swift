import SwiftUI
import UIKit

// MARK: - Global Accessibility Manager
@MainActor
class GlobalAccessibilityManager: ObservableObject {
    @Published var settings = AccessibilitySettings() {
        didSet {
            applySystemWideSettings()
            saveSettingsLocally()
        }
    }
    
    static let shared = GlobalAccessibilityManager()
    
    private init() {
        loadLocalSettings()
        setupSystemObservers()
    }
    
    // MARK: - Apply System-Wide Settings
    private func applySystemWideSettings() {
        // Apply Large Text
        applyLargeTextSetting()
        
        // Apply High Contrast
        applyHighContrastSetting()
        
        // Apply Reduce Motion
        applyReduceMotionSetting()
        
        // Apply Haptic Feedback
        applyHapticFeedbackSetting()
        
        // Apply VoiceOver optimizations
        applyVoiceOverSetting()
        
        // Apply Color Blind Assist
        applyColorBlindAssistSetting()
        
        // Notify all views to update
        NotificationCenter.default.post(name: .accessibilitySettingsChanged, object: settings)
    }
    
    // MARK: - Individual Setting Applications
    private func applyLargeTextSetting() {
        // Note: UIApplication.preferredContentSizeCategory is read-only
        // We'll handle large text through our custom modifiers and environment values
        if settings.largeText {
            print("📱 Large text enabled - will be applied through view modifiers")
        } else {
            print("📱 Large text disabled - using standard text sizes")
        }
    }
    
    private func applyHighContrastSetting() {
        if settings.highContrast {
            // Apply high contrast theme
            AppTheme.shared.enableHighContrast()
        } else {
            AppTheme.shared.disableHighContrast()
        }
    }
    
    private func applyReduceMotionSetting() {
        if settings.reduceMotion {
            // Disable animations system-wide
            UIView.setAnimationsEnabled(false)
            AnimationManager.shared.disableAnimations()
        } else {
            UIView.setAnimationsEnabled(true)
            AnimationManager.shared.enableAnimations()
        }
    }
    
    private func applyHapticFeedbackSetting() {
        HapticManager.shared.isEnabled = settings.hapticFeedback
    }
    
    private func applyVoiceOverSetting() {
        if settings.voiceOver {
            // Optimize for VoiceOver
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
    }
    
    private func applyColorBlindAssistSetting() {
        ColorManager.shared.colorBlindAssistEnabled = settings.colorBlindAssist
    }
    
    // MARK: - System Observers
    private func setupSystemObservers() {
        // Listen for system accessibility changes
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncWithSystemAccessibility()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncWithSystemAccessibility()
        }
    }
    
    private func syncWithSystemAccessibility() {
        // Sync with iOS system accessibility settings
        if UIAccessibility.isVoiceOverRunning && !settings.voiceOver {
            settings.voiceOver = true
        }
        
        if UIAccessibility.isReduceMotionEnabled && !settings.reduceMotion {
            settings.reduceMotion = true
        }
    }
    
    // MARK: - Settings Management
    func updateSettings(_ newSettings: AccessibilitySettings) {
        settings = newSettings
    }
    
    private func saveSettingsLocally() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "global_accessibility_settings")
        }
    }
    
    func loadLocalSettings() {
        if let data = UserDefaults.standard.data(forKey: "global_accessibility_settings"),
           let loadedSettings = try? JSONDecoder().decode(AccessibilitySettings.self, from: data) {
            settings = loadedSettings
        }
    }
}

// MARK: - App Theme Manager
@MainActor
class AppTheme: ObservableObject {
    @Published var isHighContrastEnabled = false
    @Published var currentColorScheme: ColorScheme = .light
    
    static let shared = AppTheme()
    
    private init() {}
    
    func enableHighContrast() {
        isHighContrastEnabled = true
        currentColorScheme = .dark
        updateAppColors()
    }
    
    func disableHighContrast() {
        isHighContrastEnabled = false
        currentColorScheme = .light
        updateAppColors()
    }
    
    private func updateAppColors() {
        // Update app-wide color scheme
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = isHighContrastEnabled ? .dark : .unspecified
            }
        }
    }
    
    // High contrast color variants
    var primaryColor: Color {
        isHighContrastEnabled ? Color.white : AppColors.primary
    }
    
    var backgroundColor: Color {
        isHighContrastEnabled ? Color.black : AppColors.background
    }
    
    var foregroundColor: Color {
        isHighContrastEnabled ? Color.white : AppColors.foreground
    }
    
    var borderColor: Color {
        isHighContrastEnabled ? Color.white : AppColors.border
    }
}

// MARK: - Animation Manager
class AnimationManager: ObservableObject {
    @Published var animationsEnabled = true
    
    static let shared = AnimationManager()
    
    private init() {}
    
    func enableAnimations() {
        animationsEnabled = true
    }
    
    func disableAnimations() {
        animationsEnabled = false
    }
    
    var defaultAnimation: Animation? {
        animationsEnabled ? .easeInOut(duration: 0.3) : .none
    }
    
    var springAnimation: Animation? {
        animationsEnabled ? .spring(response: 0.5, dampingFraction: 0.8) : .none
    }
}

// MARK: - Haptic Manager
class HapticManager: ObservableObject {
    @Published var isEnabled = true
    
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Color Manager
class ColorManager: ObservableObject {
    @Published var colorBlindAssistEnabled = false
    
    static let shared = ColorManager()
    
    private init() {}
    
    func accessibleColor(for color: Color) -> Color {
        guard colorBlindAssistEnabled else { return color }
        
        // Enhanced color differentiation for color blind users
        switch color {
        case AppColors.primary:
            return Color(red: 0.0, green: 0.3, blue: 0.8) // Strong blue
        case .red:
            return Color(red: 0.8, green: 0.0, blue: 0.0) // Strong red
        case .green:
            return Color(red: 0.0, green: 0.6, blue: 0.0) // Strong green
        case .orange:
            return Color(red: 1.0, green: 0.5, blue: 0.0) // Strong orange
        default:
            return color
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let accessibilitySettingsChanged = Notification.Name("accessibilitySettingsChanged")
}

// MARK: - Global Accessibility View Modifier
struct GlobalAccessibilityModifier: ViewModifier {
    @StateObject private var accessibilityManager = GlobalAccessibilityManager.shared
    @StateObject private var appTheme = AppTheme.shared
    @StateObject private var animationManager = AnimationManager.shared
    @StateObject private var colorManager = ColorManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(appTheme.currentColorScheme)
            .dynamicTypeSize(accessibilityManager.settings.largeText ? .accessibility3 : .medium)
            .animation(animationManager.defaultAnimation, value: accessibilityManager.settings)
            .onReceive(NotificationCenter.default.publisher(for: .accessibilitySettingsChanged)) { _ in
                // React to accessibility changes
            }
    }
}

// MARK: - View Extension
extension View {
    func globalAccessibility() -> some View {
        self.modifier(GlobalAccessibilityModifier())
    }
}

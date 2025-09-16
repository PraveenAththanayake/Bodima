import SwiftUI

// MARK: - Accessibility Aware Modifier
struct AccessibilityAwareModifier: ViewModifier {
    let settings: AccessibilitySettings
    
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(settings.largeText ? .accessibility3 : .medium)
            .environment(\.colorScheme, settings.highContrast ? .dark : .light)
            .animation(settings.reduceMotion ? .none : .default, value: settings.reduceMotion)
            .accessibilityElement(children: settings.screenReader ? .contain : .combine)
            .onAppear {
                if settings.hapticFeedback {
                    // Enable haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.prepare()
                }
            }
    }
}

// MARK: - Accessibility Button Style
struct AccessibilityButtonStyle: ButtonStyle {
    let settings: AccessibilitySettings
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(settings.reduceMotion ? .none : .easeInOut(duration: 0.1), value: configuration.isPressed)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(settings.highContrast ? Color.primary : Color.clear)
                    .opacity(configuration.isPressed ? 0.1 : 0)
            )
            .onTapGesture {
                if settings.hapticFeedback {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            }
    }
}

// MARK: - Accessibility Text Style
struct AccessibilityTextStyle: ViewModifier {
    let settings: AccessibilitySettings
    let baseSize: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: settings.largeText ? baseSize * 1.3 : baseSize))
            .foregroundColor(settings.highContrast ? .primary : .primary)
            .accessibilityAddTraits(settings.voiceOver ? .isStaticText : [])
    }
}

// MARK: - Accessibility Card Style
struct AccessibilityCardStyle: ViewModifier {
    let settings: AccessibilitySettings
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(settings.highContrast ? Color.primary.opacity(0.05) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                settings.highContrast ? Color.primary : Color.gray.opacity(0.3),
                                lineWidth: settings.highContrast ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: settings.highContrast ? .clear : .gray.opacity(0.1),
                radius: settings.highContrast ? 0 : 8,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Color Blind Assist Colors
extension Color {
    static func accessibleColor(for originalColor: Color, settings: AccessibilitySettings) -> Color {
        if settings.colorBlindAssist {
            // Provide high contrast alternatives for common colors
            switch originalColor {
            case .red:
                return Color(red: 0.8, green: 0.1, blue: 0.1) // Darker red
            case .green:
                return Color(red: 0.1, green: 0.6, blue: 0.1) // Darker green
            case .blue:
                return Color(red: 0.1, green: 0.1, blue: 0.8) // Darker blue
            case .orange:
                return Color(red: 0.9, green: 0.5, blue: 0.1) // More distinct orange
            default:
                return originalColor
            }
        }
        return originalColor
    }
}

// MARK: - Haptic Feedback Helper
struct HapticFeedbackHelper {
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light, enabled: Bool) {
        guard enabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType, enabled: Bool) {
        guard enabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
    
    static func selection(enabled: Bool) {
        guard enabled else { return }
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}

// MARK: - View Extensions
extension View {
    func accessibilityAware(settings: AccessibilitySettings) -> some View {
        self.modifier(AccessibilityAwareModifier(settings: settings))
    }
    
    func accessibilityText(settings: AccessibilitySettings, baseSize: CGFloat = 16) -> some View {
        self.modifier(AccessibilityTextStyle(settings: settings, baseSize: baseSize))
    }
    
    func accessibilityCard(settings: AccessibilitySettings) -> some View {
        self.modifier(AccessibilityCardStyle(settings: settings))
    }
    
    func accessibilityButton(settings: AccessibilitySettings, action: @escaping () -> Void = {}) -> some View {
        self.buttonStyle(AccessibilityButtonStyle(settings: settings))
            .onTapGesture {
                HapticFeedbackHelper.impact(enabled: settings.hapticFeedback)
                action()
            }
    }
}

// MARK: - Accessibility Manager
@MainActor
class AccessibilityManager: ObservableObject {
    @Published var currentSettings = AccessibilitySettings()
    static let shared = AccessibilityManager()
    
    private init() {
        loadSettings()
    }
    
    func updateSettings(_ settings: AccessibilitySettings) {
        currentSettings = settings
        saveSettings()
        applySystemSettings()
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "accessibility_settings"),
           let settings = try? JSONDecoder().decode(AccessibilitySettings.self, from: data) {
            currentSettings = settings
            applySystemSettings()
        }
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(currentSettings) {
            UserDefaults.standard.set(encoded, forKey: "accessibility_settings")
        }
    }
    
    private func applySystemSettings() {
        // Apply system-level accessibility settings
        if currentSettings.reduceMotion {
            UIView.setAnimationsEnabled(false)
        } else {
            UIView.setAnimationsEnabled(true)
        }
    }
}

// MARK: - Accessibility Constants
struct AccessibilityConstants {
    static let minimumTouchTarget: CGFloat = 44
    static let recommendedTouchTarget: CGFloat = 48
    static let largeTextMultiplier: CGFloat = 1.3
    static let highContrastBorderWidth: CGFloat = 2
    static let standardBorderWidth: CGFloat = 1
    
    struct Colors {
        static let highContrastBackground = Color.black
        static let highContrastForeground = Color.white
        static let standardBackground = Color.white
        static let standardForeground = Color.black
    }
}

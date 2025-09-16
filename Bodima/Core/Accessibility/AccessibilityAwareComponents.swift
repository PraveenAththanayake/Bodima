import SwiftUI

// MARK: - Accessibility-Aware Text
struct AccessibilityText: View {
    let text: String
    let baseSize: CGFloat
    let weight: Font.Weight
    
    @StateObject private var globalManager = GlobalAccessibilityManager.shared
    @StateObject private var appTheme = AppTheme.shared
    
    init(_ text: String, size: CGFloat = 16, weight: Font.Weight = .regular) {
        self.text = text
        self.baseSize = size
        self.weight = weight
    }
    
    var body: some View {
        Text(text)
            .font(.system(
                size: globalManager.settings.largeText ? baseSize * 1.4 : baseSize,
                weight: weight
            ))
            .foregroundColor(appTheme.foregroundColor)
            .accessibilityLabel(text)
            .accessibilityAddTraits(globalManager.settings.screenReader ? .isStaticText : [])
    }
}

// MARK: - Accessibility-Aware Button
struct AccessibilityButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    
    @StateObject private var globalManager = GlobalAccessibilityManager.shared
    @StateObject private var appTheme = AppTheme.shared
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var animationManager = AnimationManager.shared
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: {
            hapticManager.impact(.light)
            action()
        }) {
            content
                .frame(minHeight: globalManager.settings.largeText ? 56 : 44) // Larger touch targets
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(appTheme.isHighContrastEnabled ? Color.clear : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    appTheme.borderColor,
                                    lineWidth: appTheme.isHighContrastEnabled ? 2 : 1
                                )
                        )
                )
        }
        .scaleEffect(globalManager.settings.largeText ? 1.1 : 1.0)
        .animation(animationManager.defaultAnimation, value: globalManager.settings)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Accessibility-Aware Card
struct AccessibilityCard<Content: View>: View {
    let content: Content
    
    @StateObject private var globalManager = GlobalAccessibilityManager.shared
    @StateObject private var appTheme = AppTheme.shared
    @StateObject private var animationManager = AnimationManager.shared
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(globalManager.settings.largeText ? 24 : 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(appTheme.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                appTheme.borderColor,
                                lineWidth: appTheme.isHighContrastEnabled ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: appTheme.isHighContrastEnabled ? .clear : .gray.opacity(0.1),
                radius: appTheme.isHighContrastEnabled ? 0 : 8,
                x: 0,
                y: 4
            )
            .animation(animationManager.defaultAnimation, value: globalManager.settings)
    }
}

// MARK: - Accessibility-Aware Toggle
struct AccessibilityToggle: View {
    @Binding var isOn: Bool
    let title: String
    let description: String
    let icon: String
    
    @StateObject private var globalManager = GlobalAccessibilityManager.shared
    @StateObject private var appTheme = AppTheme.shared
    @StateObject private var hapticManager = HapticManager.shared
    @StateObject private var colorManager = ColorManager.shared
    
    var body: some View {
        HStack(spacing: globalManager.settings.largeText ? 16 : 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isOn ? colorManager.accessibleColor(for: AppColors.primary).opacity(0.1) : appTheme.backgroundColor)
                    .frame(
                        width: globalManager.settings.largeText ? 48 : 40,
                        height: globalManager.settings.largeText ? 48 : 40
                    )
                
                Image(systemName: icon)
                    .font(.system(
                        size: globalManager.settings.largeText ? 22 : 18,
                        weight: .medium
                    ))
                    .foregroundColor(isOn ? colorManager.accessibleColor(for: AppColors.primary) : appTheme.foregroundColor)
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 2) {
                AccessibilityText(title, size: 16, weight: .semibold)
                
                AccessibilityText(description, size: 14, weight: .medium)
                    .foregroundColor(appTheme.foregroundColor.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Toggle Switch
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    hapticManager.selection()
                    isOn = newValue
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: colorManager.accessibleColor(for: AppColors.primary)))
            .scaleEffect(globalManager.settings.largeText ? 1.2 : 1.0)
        }
        .padding(globalManager.settings.largeText ? 20 : 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint("Double tap to toggle")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Accessibility-Aware Navigation Link
struct AccessibilityNavigationLink<Destination: View, Label: View>: View {
    let destination: Destination
    let label: Label
    
    @StateObject private var globalManager = GlobalAccessibilityManager.shared
    @StateObject private var hapticManager = HapticManager.shared
    
    init(destination: Destination, @ViewBuilder label: () -> Label) {
        self.destination = destination
        self.label = label()
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            label
                .frame(minHeight: globalManager.settings.largeText ? 56 : 44)
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                hapticManager.selection()
            }
        )
    }
}

// MARK: - Accessibility-Aware Image
struct AccessibilityImage: View {
    let systemName: String
    let size: CGFloat
    let accessibilityLabel: String
    
    @StateObject private var globalManager = GlobalAccessibilityManager.shared
    @StateObject private var appTheme = AppTheme.shared
    @StateObject private var colorManager = ColorManager.shared
    
    init(systemName: String, size: CGFloat = 18, accessibilityLabel: String = "") {
        self.systemName = systemName
        self.size = size
        self.accessibilityLabel = accessibilityLabel
    }
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(
                size: globalManager.settings.largeText ? size * 1.3 : size,
                weight: .medium
            ))
            .foregroundColor(colorManager.accessibleColor(for: appTheme.foregroundColor))
            .accessibilityLabel(accessibilityLabel.isEmpty ? systemName : accessibilityLabel)
    }
}

// MARK: - Accessibility-Aware Divider
struct AccessibilityDivider: View {
    @StateObject private var appTheme = AppTheme.shared
    
    var body: some View {
        Divider()
            .background(appTheme.borderColor)
            .frame(height: appTheme.isHighContrastEnabled ? 2 : 1)
    }
}

// MARK: - Global Accessibility Environment
struct AccessibilityEnvironment: ViewModifier {
    @StateObject private var globalManager = GlobalAccessibilityManager.shared
    @StateObject private var appTheme = AppTheme.shared
    
    func body(content: Content) -> some View {
        content
            .environment(\.dynamicTypeSize, globalManager.settings.largeText ? .accessibility3 : .medium)
            .environment(\.colorScheme, appTheme.currentColorScheme)
            .preferredColorScheme(appTheme.currentColorScheme)
    }
}

// MARK: - View Extensions
extension View {
    func accessibilityEnvironment() -> some View {
        self.modifier(AccessibilityEnvironment())
    }
}

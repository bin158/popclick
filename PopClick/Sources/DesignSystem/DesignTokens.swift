import SwiftUI
import AppKit

/// Centralized design tokens for consistent, high-end Apple-native visual language
enum DesignTokens {
    // MARK: - Corner Radius
    enum CornerRadius {
        static let xs: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
        static let capsule: CGFloat = 24
        static let toolbar: CGFloat = 14
        static let popover: CGFloat = 16
        static let panel: CGFloat = 18
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let xxl: CGFloat = 20
        static let xxxl: CGFloat = 28
    }

    // MARK: - Typography
    enum Typography {
        static let toolbarLabel: Font = .system(size: 11, weight: .medium, design: .default)
        static let toolbarIconSize: CGFloat = 14
        static let captionFont: Font = .system(size: 11, weight: .regular)
        static let bodyFont: Font = .system(size: 13, weight: .regular)
        static let bodyMedium: Font = .system(size: 13, weight: .medium)
        static let headlineFont: Font = .system(size: 14, weight: .semibold)
        static let titleFont: Font = .system(size: 16, weight: .semibold)
        static let monoBody: Font = .system(size: 12, weight: .regular, design: .monospaced)
        static let shortcutFont: Font = .system(size: 11, weight: .medium, design: .monospaced)
    }

    // MARK: - Icon
    enum Icon {
        static let toolbarSize: CGFloat = 14
        static let menuSize: CGFloat = 13
        static let settingsSize: CGFloat = 16
        static let weight: Font.Weight = .medium
    }

    // MARK: - Animation
    enum Animation {
        static let fast: Double = 0.10
        static let hoverDuration: Double = 0.12
        static let appearDuration: Double = 0.15
        static let disappearDuration: Double = 0.12
        static let popoverDuration: Double = 0.16

        static let appearScale: CGFloat = 0.96
        static let disappearScale: CGFloat = 0.98

        static let springResponse: Double = 0.28
        static let springDamping: Double = 0.82
    }

    // MARK: - Shadow
    enum Shadow {
        static let toolbarColor = Color.black.opacity(0.14)
        static let toolbarRadius: CGFloat = 16
        static let toolbarY: CGFloat = 6

        static let popoverColor = Color.black.opacity(0.18)
        static let popoverRadius: CGFloat = 24
        static let popoverY: CGFloat = 10

        static let subtleColor = Color.black.opacity(0.06)
        static let subtleRadius: CGFloat = 4
        static let subtleY: CGFloat = 2
    }

    // MARK: - Toolbar Geometry
    enum Toolbar {
        static let height: CGFloat = 40
        static let buttonWidth: CGFloat = 46
        static let buttonHeight: CGFloat = 36
        static let buttonSpacing: CGFloat = 2
        static let horizontalPadding: CGFloat = 5
        static let verticalPadding: CGFloat = 4
        static let offsetFromSelection: CGFloat = 10
    }

    // MARK: - Colors
    enum Colors {
        static let toolbarBorder = Color.primary.opacity(0.09)
        static let toolbarBorderDark = Color.white.opacity(0.14)
        static let innerSpecularLight = Color.white.opacity(0.40)
        static let innerSpecularDark = Color.white.opacity(0.06)

        static let buttonHover = Color.primary.opacity(0.07)
        static let buttonPress = Color.primary.opacity(0.13)
        static let separator = Color.primary.opacity(0.08)
        static let menuHover = Color.primary.opacity(0.08)

        static let accent = Color.accentColor
    }

    // MARK: - Haptics
    static func performHapticFeedback(pattern: NSHapticFeedbackManager.FeedbackPattern = .alignment) {
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .default)
    }
}

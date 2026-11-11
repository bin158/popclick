import SwiftUI
import AppKit

/// Reusable NSVisualEffectView wrapper for glass materials
struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    let state: NSVisualEffectView.State
    let cornerRadius: CGFloat

    init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.toolbar
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
        self.cornerRadius = cornerRadius
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.cornerCurve = .continuous
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        nsView.layer?.cornerRadius = cornerRadius
    }
}

/// Glass capsule background modifier with specular edge lighting
struct GlassCapsuleStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = DesignTokens.CornerRadius.toolbar

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    VisualEffectBackground(
                        material: .hudWindow,
                        blendingMode: .behindWindow,
                        state: .active,
                        cornerRadius: cornerRadius
                    )

                    // Subtle inner specular gradient for Apple-native glass depth
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .dark
                                    ? [Color.white.opacity(0.08), Color.white.opacity(0.02)]
                                    : [Color.white.opacity(0.45), Color.white.opacity(0.18)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                // Crisp 0.5pt Apple-style outer border
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        colorScheme == .dark
                            ? DesignTokens.Colors.toolbarBorderDark
                            : DesignTokens.Colors.toolbarBorder,
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: DesignTokens.Shadow.toolbarColor,
                radius: DesignTokens.Shadow.toolbarRadius,
                y: DesignTokens.Shadow.toolbarY
            )
            .shadow(
                color: DesignTokens.Shadow.subtleColor,
                radius: DesignTokens.Shadow.subtleRadius,
                y: DesignTokens.Shadow.subtleY
            )
    }
}

/// Glass card style for larger popovers and AI panels
struct GlassCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var cornerRadius: CGFloat = DesignTokens.CornerRadius.panel

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    VisualEffectBackground(
                        material: .popover,
                        blendingMode: .behindWindow,
                        state: .active,
                        cornerRadius: cornerRadius
                    )

                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            colorScheme == .dark
                                ? Color.white.opacity(0.04)
                                : Color.white.opacity(0.35)
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.12)
                            : Color.black.opacity(0.08),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: DesignTokens.Shadow.popoverColor,
                radius: DesignTokens.Shadow.popoverRadius,
                y: DesignTokens.Shadow.popoverY
            )
    }
}

extension View {
    func glassCapsuleStyle(cornerRadius: CGFloat = DesignTokens.CornerRadius.toolbar) -> some View {
        modifier(GlassCapsuleStyle(cornerRadius: cornerRadius))
    }

    func glassCardStyle(cornerRadius: CGFloat = DesignTokens.CornerRadius.panel) -> some View {
        modifier(GlassCardStyle(cornerRadius: cornerRadius))
    }
}

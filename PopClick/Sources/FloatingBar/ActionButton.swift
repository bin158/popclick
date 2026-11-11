import SwiftUI
import Combine

/// View model for an individual action button in the toolbar
final class ActionButtonViewModel: ObservableObject {
    let action: ActionType
    let onTap: () -> Void

    @Published var isHovered: Bool = false
    @Published var isPressed: Bool = false

    init(action: ActionType, onTap: @escaping () -> Void) {
        self.action = action
        self.onTap = onTap
    }
}

/// An individual action button in the floating glass capsule
struct ActionButton: View {
    @ObservedObject var viewModel: ActionButtonViewModel

    var body: some View {
        Button(action: {
            DesignTokens.performHapticFeedback()
            viewModel.onTap()
        }) {
            VStack(spacing: 2) {
                Image(systemName: viewModel.action.iconName)
                    .font(.system(size: DesignTokens.Icon.toolbarSize, weight: DesignTokens.Icon.weight))
                    .foregroundStyle(iconColor)
                    .frame(width: DesignTokens.Icon.toolbarSize, height: DesignTokens.Icon.toolbarSize)

                Text(viewModel.action.title)
                    .font(DesignTokens.Typography.toolbarLabel)
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
            }
            .frame(width: DesignTokens.Toolbar.buttonWidth, height: DesignTokens.Toolbar.buttonHeight)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous))
            .scaleEffect(viewModel.isPressed ? 0.94 : (viewModel.isHovered ? 1.03 : 1.0))
            .animation(.easeInOut(duration: DesignTokens.Animation.hoverDuration), value: viewModel.isHovered)
            .animation(.easeInOut(duration: 0.08), value: viewModel.isPressed)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            viewModel.isHovered = hovering
        }
    }

    private var iconColor: Color {
        if viewModel.action == .ai {
            return Color.accentColor
        }
        if viewModel.isPressed {
            return .primary.opacity(0.95)
        } else if viewModel.isHovered {
            return .primary.opacity(0.90)
        }
        return .primary.opacity(0.70)
    }

    private var labelColor: Color {
        if viewModel.isHovered {
            return .primary.opacity(0.85)
        }
        return .secondary.opacity(0.9)
    }

    @ViewBuilder
    private var buttonBackground: some View {
        if viewModel.isPressed {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                .fill(DesignTokens.Colors.buttonPress)
        } else if viewModel.isHovered {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                .fill(DesignTokens.Colors.buttonHover)
        } else {
            Color.clear
        }
    }
}

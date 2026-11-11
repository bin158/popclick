import SwiftUI
import Combine

/// View model for the More Menu Popover
final class MoreMenuViewModel: ObservableObject {
    let text: String
    let onAction: (ActionType) -> Void
    let onPlugin: (Plugin) -> Void
    let onOpenAI: () -> Void
    let onDismiss: () -> Void

    @Published var hoveredId: String? = nil

    init(
        text: String,
        onAction: @escaping (ActionType) -> Void,
        onPlugin: @escaping (Plugin) -> Void,
        onOpenAI: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.text = text
        self.onAction = onAction
        self.onPlugin = onPlugin
        self.onOpenAI = onOpenAI
        self.onDismiss = onDismiss
    }
}

/// A macOS native glass popover menu presenting expanded actions and plugins
struct MoreMenuView: View {
    @ObservedObject var viewModel: MoreMenuViewModel
    @ObservedObject var pluginManager = PluginManager.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Actions Section
                sectionHeader("ACTIONS")
                menuRow(action: .copy, shortcut: "⌘C")
                menuRow(action: .search, shortcut: "⌘F")
                menuRow(action: .translate)
                menuRow(action: .define)
                menuRow(action: .speak)
                menuRow(action: .share)

                Divider().opacity(0.12).padding(.vertical, 2)

                // AI Section
                sectionHeader("AI ACTIONS")
                Button(action: {
                    viewModel.onOpenAI()
                }) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: DesignTokens.Icon.menuSize))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 18)

                        Text("PopClick AI Agent...")
                            .font(DesignTokens.Typography.bodyFont)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("⌘J")
                            .font(DesignTokens.Typography.shortcutFont)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xs, style: .continuous)
                            .fill(viewModel.hoveredId == "ai_panel" ? DesignTokens.Colors.menuHover : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    viewModel.hoveredId = hovering ? "ai_panel" : nil
                }

                Divider().opacity(0.12).padding(.vertical, 2)

                // Utilities Section
                sectionHeader("TEXT UTILITIES")
                menuRow(action: .uppercase)
                menuRow(action: .lowercase)
                menuRow(action: .capitalize)
                menuRow(action: .formatJSON)
                menuRow(action: .removeLineBreaks)
                menuRow(action: .trimSpaces)
                menuRow(action: .urlEncode)
                menuRow(action: .base64Encode)

                // Plugins Section
                let activePlugins = pluginManager.plugins.filter { $0.isEnabled }
                if !activePlugins.isEmpty {
                    Divider().opacity(0.12).padding(.vertical, 2)
                    sectionHeader("PLUGINS")
                    ForEach(activePlugins) { plugin in
                        pluginRow(plugin)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .frame(width: 230, height: 360)
        .glassCardStyle(cornerRadius: DesignTokens.CornerRadius.popover)
    }

    // MARK: - Subviews

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary.opacity(0.8))
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, 2)
    }

    private func menuRow(action: ActionType, shortcut: String? = nil) -> some View {
        Button(action: {
            viewModel.onAction(action)
        }) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: action.iconName)
                    .font(.system(size: DesignTokens.Icon.menuSize))
                    .foregroundStyle(.primary.opacity(0.75))
                    .frame(width: 18)

                Text(action.title)
                    .font(DesignTokens.Typography.bodyFont)
                    .foregroundStyle(.primary)

                Spacer()

                if let shortcut = shortcut ?? action.shortcutHint {
                    Text(shortcut)
                        .font(DesignTokens.Typography.shortcutFont)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xs, style: .continuous)
                    .fill(viewModel.hoveredId == action.id ? DesignTokens.Colors.menuHover : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            viewModel.hoveredId = hovering ? action.id : nil
        }
    }

    private func pluginRow(_ plugin: Plugin) -> some View {
        Button(action: {
            viewModel.onPlugin(plugin)
        }) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: plugin.icon)
                    .font(.system(size: DesignTokens.Icon.menuSize))
                    .foregroundStyle(.primary.opacity(0.75))
                    .frame(width: 18)

                Text(plugin.name)
                    .font(DesignTokens.Typography.bodyFont)
                    .foregroundStyle(.primary)

                Spacer()

                if let shortcut = plugin.shortcut {
                    Text(shortcut)
                        .font(DesignTokens.Typography.shortcutFont)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xs, style: .continuous)
                    .fill(viewModel.hoveredId == plugin.id ? DesignTokens.Colors.menuHover : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            viewModel.hoveredId = hovering ? plugin.id : nil
        }
    }
}

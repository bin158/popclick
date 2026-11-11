import SwiftUI
import Combine

/// View model for the AI Panel UI
final class AIPanelViewModel: ObservableObject {
    enum State {
        case promptSelection
        case loading
        case result(output: String, providerName: String)
    }

    let originalText: String
    let onDismiss: () -> Void

    @Published var state: State = .promptSelection
    @Published var customInput: String = ""
    @Published var lastAction: AIService.AIAction = .rewrite
    @Published var hoveredActionId: String? = nil
    @Published var isExpanded: Bool = UserDefaults.standard.bool(forKey: "AIPanel_isExpanded")

    var onSizeChanged: (() -> Void)?

    init(originalText: String, onDismiss: @escaping () -> Void) {
        self.originalText = originalText
        self.onDismiss = onDismiss
    }

    func toggleExpanded() {
        isExpanded.toggle()
        UserDefaults.standard.set(isExpanded, forKey: "AIPanel_isExpanded")
        DesignTokens.performHapticFeedback()
        DispatchQueue.main.async { [weak self] in
            self?.onSizeChanged?()
        }
    }

    func selectAction(_ action: AIService.AIAction) {
        lastAction = action
        executeAI(action: action, customPrompt: nil)
    }

    func submitCustomPrompt() {
        guard !customInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        lastAction = .custom
        executeAI(action: .custom, customPrompt: customInput)
    }

    func retry() {
        executeAI(action: lastAction, customPrompt: lastAction == .custom ? customInput : nil)
    }

    private func executeAI(action: AIService.AIAction, customPrompt: String?) {
        state = .loading
        DesignTokens.performHapticFeedback()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.onSizeChanged?()
        }

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let res = await AIService.shared.process(
                action: action,
                text: self.originalText,
                customPrompt: customPrompt
            )
            let trimmed = res.output.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalOutput = !trimmed.isEmpty
                ? trimmed
                : "No response was generated. Please check your API key settings or verify your network connection."

            withAnimation(.easeOut(duration: DesignTokens.Animation.fast)) {
                self.state = .result(output: finalOutput, providerName: res.providerName)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
                self?.onSizeChanged?()
            }
        }
    }
}

/// The Apple-native minimalist AI panel view
struct AIPanelView: View {
    @ObservedObject var viewModel: AIPanelViewModel
    @Environment(\.colorScheme) private var colorScheme

    private var panelWidth: CGFloat {
        switch viewModel.state {
        case .promptSelection, .loading:
            return viewModel.isExpanded ? 640 : 500
        case .result:
            return viewModel.isExpanded ? 760 : 580
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar

            Divider()
                .opacity(0.12)

            switch viewModel.state {
            case .promptSelection:
                promptSelectionView
            case .loading:
                loadingView
            case .result(let output, let providerName):
                resultView(output: output, providerName: providerName)
            }
        }
        .frame(width: panelWidth)
        .glassCardStyle(cornerRadius: DesignTokens.CornerRadius.panel)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.accentColor)

            Text("PopClick AI")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundStyle(.primary)

            Spacer()

            // Expand / Collapse toggle button
            Button(action: viewModel.toggleExpanded) {
                Image(systemName: viewModel.isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.85))
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                    )
            }
            .buttonStyle(.plain)
            .help(viewModel.isExpanded ? "Collapse panel (收起窗口)" : "Expand panel (放大窗口)")

            Button(action: viewModel.onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary.opacity(0.6))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Close (关闭)")
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.md)
    }

    // MARK: - Prompt Selection

    private var promptSelectionView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Text preview
            Text(viewModel.originalText)
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(.secondary)
                .lineLimit(viewModel.isExpanded ? 5 : 2)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.top, DesignTokens.Spacing.xs)

            // Preset action pills
            VStack(spacing: 2) {
                ForEach(AIService.AIAction.allCases.filter { $0 != .custom }) { action in
                    Button(action: {
                        viewModel.selectAction(action)
                    }) {
                        HStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: action.iconName)
                                .font(.system(size: 13, weight: .medium))
                                .frame(width: 18)
                                .foregroundStyle(.primary.opacity(0.75))

                            Text(action.rawValue)
                                .font(DesignTokens.Typography.bodyFont)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary.opacity(0.5))
                        }
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xs, style: .continuous)
                                .fill(viewModel.hoveredActionId == action.id ? DesignTokens.Colors.menuHover : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        viewModel.hoveredActionId = hovering ? action.id : nil
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)

            Divider()
                .opacity(0.12)

            // Custom prompt input
            HStack(spacing: DesignTokens.Spacing.sm) {
                TextField("Ask anything or give instructions...", text: $viewModel.customInput)
                    .textFieldStyle(.plain)
                    .font(DesignTokens.Typography.bodyFont)
                    .onSubmit {
                        viewModel.submitCustomPrompt()
                    }

                if !viewModel.customInput.isEmpty {
                    Button(action: viewModel.submitCustomPrompt) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.md)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .scaleEffect(0.9)
                .progressViewStyle(.circular)

            Text("Querying AI providers…")
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xxxl)
    }

    // MARK: - Result View

    private func resultView(output: String, providerName: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Original snippet
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text("ORIGINAL")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary.opacity(0.8))

                Text(viewModel.originalText)
                    .font(DesignTokens.Typography.captionFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(viewModel.isExpanded ? 6 : 3)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, DesignTokens.Spacing.sm)

            Divider()
                .opacity(0.10)

            // Result
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                HStack {
                    Text("RESULT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.accentColor)

                    Spacer()

                    // Provider indicator badge
                    Text("✦ \(providerName)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                ScrollView(.vertical, showsIndicators: true) {
                    MarkdownContentView(markdown: output)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 120, maxHeight: viewModel.isExpanded ? 680 : 480)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)

            Divider()
                .opacity(0.12)

            // Bottom action buttons
            HStack(spacing: DesignTokens.Spacing.sm) {
                Button(action: {
                    ClipboardManager.copy(output)
                    viewModel.onDismiss()
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(DesignTokens.Typography.captionFont)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    TextReplacer.replaceSelectedText(with: output)
                    viewModel.onDismiss()
                }) {
                    Label("Replace", systemImage: "arrow.triangle.2.circlepath")
                        .font(DesignTokens.Typography.captionFont)
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    TextReplacer.insertText(output)
                    viewModel.onDismiss()
                }) {
                    Label("Insert", systemImage: "arrow.down.to.line")
                        .font(DesignTokens.Typography.captionFont)
                }
                .buttonStyle(.bordered)

                Spacer()

                // Expand / Standard size switcher in footer
                Button(action: viewModel.toggleExpanded) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 10, weight: .medium))
                        Text(viewModel.isExpanded ? "Standard" : "Expand")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.primary.opacity(0.05))
                    )
                }
                .buttonStyle(.plain)
                .help(viewModel.isExpanded ? "Collapse to standard size" : "Expand to large reader view")

                Button(action: viewModel.retry) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Retry")
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.md)
        }
    }
}

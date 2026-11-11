import SwiftUI
import Combine

/// View model for the AI Panel UI with full Code Intelligence and Diff support
@MainActor
final class AIPanelViewModel: ObservableObject {
    enum State {
        case promptSelection
        case loading
        case result(output: String, providerName: String)
    }

    enum ViewMode: String, CaseIterable, Identifiable {
        case markdown = "Markdown"
        case code = "Code"
        case diff = "Diff"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .markdown: return "doc.richtext"
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .diff: return "arrow.triangle.branch"
            }
        }
    }

    let originalText: String
    let onDismiss: () -> Void

    @Published var state: State = .promptSelection
    @Published var customInput: String = ""
    @Published var lastAction: AIService.AIAction = .rewrite
    @Published var hoveredActionId: String? = nil
    @Published var isExpanded: Bool = UserDefaults.standard.bool(forKey: "AIPanel_isExpanded")
    @Published var viewMode: ViewMode = .markdown
    @Published var contextMode: CodeContext.ContextMode = .selectionOnly
    @Published var codeContext: CodeContext?
    @Published var extractedCode: String = ""
    @Published var hasCodeChanges: Bool = false
    @Published var isWordWrapEnabled: Bool = false

    var onSizeChanged: (() -> Void)?

    init(
        originalText: String,
        codeContext: CodeContext? = nil,
        initialAction: AIService.AIAction? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.originalText = originalText
        self.codeContext = codeContext
        self.onDismiss = onDismiss

        if let action = initialAction {
            self.lastAction = action
            // Auto execute if initial action is provided (e.g. from Toolbar)
            DispatchQueue.main.async { [weak self] in
                self?.executeAI(action: action, customPrompt: nil)
            }
        } else if codeContext?.isLikelyCode == true {
            self.lastAction = .explain
        }
    }

    var detectedLanguage: CodeLanguage {
        codeContext?.detectedLanguage ?? .generic
    }

    var isCodeContent: Bool {
        codeContext?.isLikelyCode == true || !extractedCode.isEmpty
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

    func switchContextMode(_ mode: CodeContext.ContextMode) {
        guard contextMode != mode else { return }
        contextMode = mode
        codeContext?.contextMode = mode
        executeAI(action: lastAction, customPrompt: lastAction == .custom ? customInput : nil)
    }

    // MARK: - Action Execution

    private func executeAI(action: AIService.AIAction, customPrompt: String?) {
        state = .loading
        DesignTokens.performHapticFeedback()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.onSizeChanged?()
        }

        // Determine input text based on context mode
        var activeText = originalText
        if var ctx = codeContext {
            ctx.contextMode = contextMode
            self.codeContext = ctx
            activeText = ctx.buildPromptContext()
        }

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let res = await AIService.shared.process(
                action: action,
                text: activeText,
                codeContext: self.codeContext,
                customPrompt: customPrompt
            )
            let trimmed = res.output.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalOutput = !trimmed.isEmpty
                ? trimmed
                : "No response was generated. Please check your API key settings or verify your network connection."

            // Extract pure code block if present
            let extracted = DiffEngine.extractCode(from: finalOutput)
            self.extractedCode = extracted
            let cleanOrig = self.originalText.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanExtracted = extracted.trimmingCharacters(in: .whitespacesAndNewlines)
            self.hasCodeChanges = !cleanExtracted.isEmpty && cleanExtracted != cleanOrig

            // Smart default view mode based on action and result
            if self.hasCodeChanges && (action == .fix || action == .refactor || action == .comment || action == .format || action == .optimize) {
                self.viewMode = .diff
            } else if !extracted.isEmpty && (action == .generateTest || action == .format) {
                self.viewMode = .code
            } else {
                self.viewMode = .markdown
            }

            withAnimation(.easeOut(duration: DesignTokens.Animation.fast)) {
                self.state = .result(output: finalOutput, providerName: res.providerName)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
                self?.onSizeChanged?()
            }
        }
    }

    // MARK: - Output Actions

    func copyResult(output: String) {
        let textToCopy: String
        if (viewMode == .code || viewMode == .diff) && !extractedCode.isEmpty {
            textToCopy = extractedCode
        } else {
            textToCopy = output
        }
        ClipboardManager.copy(textToCopy)
        onDismiss()
    }

    func replaceSelection(output: String) {
        // ONLY replaces the text selected by the user
        let textToReplace = !extractedCode.isEmpty ? extractedCode : output
        TextReplacer.replaceSelectedText(with: textToReplace)
        onDismiss()
    }

    func insertResult(output: String) {
        let textToInsert = !extractedCode.isEmpty ? extractedCode : output
        TextReplacer.insertText(textToInsert)
        onDismiss()
    }
}

/// The Apple-native minimalist AI panel view supporting Markdown, Code, and Diff modes
struct AIPanelView: View {
    @ObservedObject var viewModel: AIPanelViewModel
    @Environment(\.colorScheme) private var colorScheme

    private var panelWidth: CGFloat {
        switch viewModel.state {
        case .promptSelection, .loading:
            return viewModel.isExpanded ? 640 : 520
        case .result:
            return viewModel.isExpanded ? 800 : 620
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

            Text("NOVA AI")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundStyle(.primary)

            // Context badge (Language & App)
            if let ctx = viewModel.codeContext, ctx.isLikelyCode {
                HStack(spacing: 4) {
                    Text(ctx.detectedLanguage.displayName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.accentColor)

                    if let app = ctx.appName, !app.isEmpty {
                        Text("• \(app)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(Capsule())
            }

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

            // Actions list
            let availableActions: [AIService.AIAction] = viewModel.codeContext?.isLikelyCode == true
                ? [.explain, .comment, .documentation, .fix, .refactor, .optimize, .generateTest, .securityReview, .format]
                : [.rewrite, .summarize, .translate, .fixGrammar, .explain, .professional]

            VStack(spacing: 2) {
                ForEach(availableActions) { action in
                    Button(action: {
                        viewModel.selectAction(action)
                    }) {
                        HStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: action.iconName)
                                .font(.system(size: 13, weight: .medium))
                                .frame(width: 18)
                                .foregroundStyle(Color.accentColor)

                            Text(action.rawValue)
                                .font(DesignTokens.Typography.bodyFont)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary.opacity(0.5))
                        }
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.vertical, 7)
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
                TextField(
                    viewModel.codeContext?.isLikelyCode == true ? "Ask anything about this code or give instructions..." : "Ask anything or give instructions...",
                    text: $viewModel.customInput
                )
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

            Text("Processing \(viewModel.lastAction.rawValue)...")
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.xxxl)
    }

    // MARK: - Result View

    private func resultView(output: String, providerName: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Context Bar & Mode Switcher
            HStack(alignment: .center, spacing: 8) {
                // View Mode Picker (Markdown | Code | Diff)
                HStack(spacing: 2) {
                    viewModeButton(mode: .markdown, label: "Markdown", icon: "doc.richtext")

                    if !viewModel.extractedCode.isEmpty {
                        viewModeButton(mode: .code, label: "Code", icon: "chevron.left.forwardslash.chevron.right")
                    }

                    if viewModel.hasCodeChanges {
                        viewModeButton(mode: .diff, label: "Diff", icon: "arrow.triangle.branch")
                    }
                }
                .padding(2)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Spacer()

                // Context scope selector if surroundings available
                if let ctx = viewModel.codeContext, ctx.surroundingBefore != nil || ctx.surroundingAfter != nil {
                    Menu {
                        Button("Selection Only") { viewModel.switchContextMode(.selectionOnly) }
                        Button("+ Surrounding Code") { viewModel.switchContextMode(.selectionWithSurroundings) }
                        if ctx.fullFileContent != nil {
                            Button("Full File") { viewModel.switchContextMode(.fullFile) }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "scope")
                                .font(.system(size: 10))
                            Text(viewModel.contextMode.rawValue)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    .menuStyle(.borderlessButton)
                }

                // Provider badge
                Text("✦ \(providerName)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, DesignTokens.Spacing.xs)

            Divider()
                .opacity(0.10)

            // Content Body based on ViewMode
            Group {
                switch viewModel.viewMode {
                case .markdown:
                    ScrollView(.vertical, showsIndicators: true) {
                        MarkdownContentView(markdown: output)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 140, maxHeight: viewModel.isExpanded ? 680 : 460)

                case .code:
                    codeContentView

                case .diff:
                    DiffView(
                        originalCode: viewModel.originalText,
                        modifiedCode: viewModel.extractedCode,
                        language: viewModel.detectedLanguage,
                        onReplace: {
                            viewModel.replaceSelection(output: output)
                        },
                        onCopy: {
                            viewModel.copyResult(output: output)
                        }
                    )
                    .frame(minHeight: 140, maxHeight: viewModel.isExpanded ? 680 : 460)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)

            Divider()
                .opacity(0.12)

            // Bottom Action Bar
            HStack(spacing: DesignTokens.Spacing.sm) {
                // Copy Button
                Button(action: {
                    viewModel.copyResult(output: output)
                }) {
                    Label(
                        (viewModel.viewMode == .code || viewModel.viewMode == .diff) ? "Copy Code" : "Copy",
                        systemImage: "doc.on.doc"
                    )
                    .font(DesignTokens.Typography.captionFont)
                }
                .buttonStyle(.bordered)

                // Replace Selection Button (Highlighted)
                Button(action: {
                    viewModel.replaceSelection(output: output)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Replace Selection")
                    }
                    .font(DesignTokens.Typography.captionFont)
                }
                .buttonStyle(.borderedProminent)
                .help("Replace ONLY the currently selected code in your editor")

                // Insert Button
                Button(action: {
                    viewModel.insertResult(output: output)
                }) {
                    Label("Insert", systemImage: "arrow.down.to.line")
                        .font(DesignTokens.Typography.captionFont)
                }
                .buttonStyle(.bordered)

                Spacer()

                // Expand / Collapse
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

                // Retry Button
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

    // MARK: - View Mode Button Helper

    private func viewModeButton(mode: AIPanelViewModel.ViewMode, label: String, icon: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.viewMode = mode
            }
        }) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(label)
                    .font(.system(size: 11, weight: viewModel.viewMode == mode ? .semibold : .regular))
            }
            .foregroundStyle(viewModel.viewMode == mode ? Color.accentColor : Color.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(viewModel.viewMode == mode ? Color(nsColor: .textBackgroundColor) : Color.clear)
                    .shadow(color: Color.black.opacity(viewModel.viewMode == mode ? 0.08 : 0), radius: 1, y: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pure Code Content View

    private var codeContentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Code header
            HStack {
                Text(viewModel.detectedLanguage.displayName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.accentColor)

                Spacer()

                Button(action: {
                    viewModel.isWordWrapEnabled.toggle()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "text.wrap")
                            .font(.system(size: 9))
                        Text(viewModel.isWordWrapEnabled ? "Unwrap" : "Wrap")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.04))

            Divider().opacity(0.1)

            // Code lines with line numbers
            let lines = viewModel.extractedCode.components(separatedBy: .newlines)
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                HStack(alignment: .top, spacing: 10) {
                    // Line numbers
                    VStack(alignment: .trailing, spacing: 2) {
                        ForEach(0..<lines.count, id: \.self) { idx in
                            Text("\(idx + 1)")
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundStyle(Color.secondary.opacity(0.5))
                                .frame(minWidth: 24, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.leading, 6)

                    // Code text
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(0..<lines.count, id: \.self) { idx in
                            Text(lines[idx].isEmpty ? " " : lines[idx])
                                .font(.system(size: 11.5, weight: .regular, design: .monospaced))
                                .foregroundStyle(Color.primary)
                                .lineLimit(viewModel.isWordWrapEnabled ? nil : 1)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.trailing, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .textBackgroundColor).opacity(0.4))
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .frame(minHeight: 140, maxHeight: viewModel.isExpanded ? 680 : 460)
    }
}

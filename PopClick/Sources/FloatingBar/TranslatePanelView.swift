import SwiftUI
import Combine

/// View model for the floating translation block
@MainActor
final class TranslatePanelViewModel: ObservableObject {
    let originalText: String
    let onDismiss: () -> Void

    @Published var isLoading: Bool = true
    @Published var translatedText: String = ""
    @Published var sourceLanguage: TranslateLanguage = TranslateLanguage.from(code: "en")
    @Published var targetLanguage: TranslateLanguage = TranslateLanguage.from(code: "zh-CN")
    @Published var showCopiedBadge: Bool = false
    @Published var isExpanded: Bool = false

    var onSizeChanged: ((CGSize) -> Void)?

    init(originalText: String, onDismiss: @escaping () -> Void) {
        self.originalText = originalText
        self.onDismiss = onDismiss

        let isChinese = TranslationService.shared.isChineseText(originalText)
        let savedTarget = UserDefaults.standard.string(forKey: "preferredTranslateLanguage")

        if let savedCode = savedTarget, !savedCode.isEmpty {
            self.targetLanguage = TranslateLanguage.from(code: savedCode)
            self.sourceLanguage = isChinese ? TranslateLanguage.from(code: "zh-CN") : TranslateLanguage.from(code: "en")
        } else {
            self.targetLanguage = isChinese ? TranslateLanguage.from(code: "en") : TranslateLanguage.from(code: "zh-CN")
            self.sourceLanguage = isChinese ? TranslateLanguage.from(code: "zh-CN") : TranslateLanguage.from(code: "en")
        }

        startTranslation()
    }

    func selectTargetLanguage(_ lang: TranslateLanguage) {
        guard lang.code != targetLanguage.code else { return }
        targetLanguage = lang
        UserDefaults.standard.set(lang.code, forKey: "preferredTranslateLanguage")
        startTranslation()
    }

    func startTranslation() {
        isLoading = true
        DesignTokens.performHapticFeedback()

        Task { @MainActor in
            let res = await TranslationService.shared.translate(
                text: self.originalText,
                fromSourceLanguage: "auto",
                toTargetLanguage: self.targetLanguage.code
            )
            self.translatedText = res.translatedText
            self.sourceLanguage = res.sourceLanguage
            self.targetLanguage = res.targetLanguage
            self.isLoading = false
        }
    }

    func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
        UserDefaults.standard.set(targetLanguage.code, forKey: "preferredTranslateLanguage")
        startTranslation()
    }

    func toggleExpanded() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            isExpanded.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.onSizeChanged?(CGSize.zero)
        }
    }

    func copyResult() {
        ClipboardManager.copy(translatedText)
        DesignTokens.performHapticFeedback()
        withAnimation(.easeOut(duration: 0.12)) {
            showCopiedBadge = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            withAnimation(.easeIn(duration: 0.12)) {
                self?.showCopiedBadge = false
            }
        }
    }

    func replaceSelection() {
        DesignTokens.performHapticFeedback()
        TextReplacer.replaceSelectedText(with: translatedText)
        onDismiss()
    }

    func speak() {
        let synthesizer = NSSpeechSynthesizer()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking()
        } else {
            synthesizer.startSpeaking(translatedText)
        }
    }

    func openInBrowser() {
        guard let encoded = originalText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://translate.google.com/?sl=auto&tl=\(targetLanguage.code)&text=\(encoded)") else { return }
        NSWorkspace.shared.open(url)
        onDismiss()
    }

    var charCountText: String {
        let chars = translatedText.count
        let words = translatedText.split { $0.isWhitespace }.count
        if words > 1 {
            return "\(chars) chars · \(words) words"
        }
        return "\(chars) chars"
    }
}

/// An ultra-modern, flexible glass card for instant multi-language translation
struct TranslatePanelView: View {
    @ObservedObject var viewModel: TranslatePanelViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Bar: Source → Target Language Menu & Controls
            headerBar

            Divider()
                .opacity(0.12)

            // Content Area: Original preview + Translated output
            if viewModel.isLoading {
                loadingView
            } else {
                resultContent
            }

            Divider()
                .opacity(0.12)

            // Bottom Actions Bar
            footerBar
        }
        .frame(width: viewModel.isExpanded ? 640 : 480)
        .glassCardStyle(cornerRadius: DesignTokens.CornerRadius.panel)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.accentColor)

            // Source language badge
            Text("\(viewModel.sourceLanguage.flag) \(viewModel.sourceLanguage.name)")
                .font(DesignTokens.Typography.toolbarLabel)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                )

            // Single clean swap icon
            Button(action: viewModel.swapLanguages) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 2)
            }
            .buttonStyle(.plain)
            .help("Swap languages (交换语言)")

            // Target language selection dropdown menu
            Menu {
                ForEach(TranslateLanguage.all) { lang in
                    Button {
                        viewModel.selectTargetLanguage(lang)
                    } label: {
                        HStack {
                            Text("\(lang.flag) \(lang.name)")
                            if viewModel.targetLanguage.code == lang.code {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("\(viewModel.targetLanguage.flag) \(viewModel.targetLanguage.name)")
                        .font(DesignTokens.Typography.toolbarLabel)
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary.opacity(0.7))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
            }
            .menuStyle(.borderlessButton)
            .help("Choose target language (选择翻译目标语言)")

            Spacer()

            // Expand / Collapse panel size button
            Button(action: viewModel.toggleExpanded) {
                Image(systemName: viewModel.isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(viewModel.isExpanded ? "Collapse panel (收起面板)" : "Expand panel (放大面板)")
            .padding(.trailing, 4)

            // Close button
            Button(action: viewModel.onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, 9)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .scaleEffect(0.7)
                .progressViewStyle(.circular)

            Text("Translating with Google…")
                .font(DesignTokens.Typography.bodyFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, DesignTokens.Spacing.xxl)
    }

    // MARK: - Result Content

    private var resultContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Original snippet (truncated with subtle style)
            Text(viewModel.originalText)
                .font(DesignTokens.Typography.captionFont)
                .foregroundStyle(.secondary.opacity(0.85))
                .lineLimit(viewModel.isExpanded ? 4 : 2)
                .padding(.top, 2)

            Divider()
                .opacity(0.08)

            // Translated text output with comfortable line height
            ScrollView(.vertical, showsIndicators: true) {
                MarkdownContentView(markdown: viewModel.translatedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: viewModel.isExpanded ? 460 : 260)
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, 12)
    }

    // MARK: - Footer Bar

    private var footerBar: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // Copy button
            Button(action: viewModel.copyResult) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.showCopiedBadge ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                    Text(viewModel.showCopiedBadge ? "Copied" : "Copy")
                        .font(DesignTokens.Typography.captionFont)
                }
            }
            .buttonStyle(.bordered)
            .tint(viewModel.showCopiedBadge ? .green : nil)

            // In-place Replace button
            Button(action: viewModel.replaceSelection) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .medium))
                    Text("Replace")
                        .font(DesignTokens.Typography.captionFont)
                }
            }
            .buttonStyle(.borderedProminent)

            // Read aloud button
            Button(action: viewModel.speak) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.borderless)
            .help("Read aloud (朗读)")

            Spacer()

            // Character count
            if !viewModel.translatedText.isEmpty {
                Text(viewModel.charCountText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary.opacity(0.7))
            }

            // Open in Google Translate Web
            Button(action: viewModel.openInBrowser) {
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Open in Google Translate (在网页中打开)")
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.vertical, 9)
    }
}

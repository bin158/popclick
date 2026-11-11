import AppKit

/// Executes actions on selected text
@MainActor
struct ActionExecutor {

    static func execute(_ action: ActionType, with text: String, anchorView: NSView? = nil) {
        DesignTokens.performHapticFeedback()

        switch action {
        case .copy:
            ClipboardManager.copy(text)

        case .search:
            searchInBrowser(text)

        case .translate:
            openInTranslate(text)

        case .define:
            lookupInDictionary(text)

        case .speak:
            speak(text)

        case .share:
            showSharePicker(for: text, anchorView: anchorView)

        case .openURL:
            openURL(text)

        case .email:
            composeEmail(to: text)

        case .uppercase:
            let transformed = TextTransformer.transform(text, kind: .uppercase)
            TextReplacer.replaceSelectedText(with: transformed)

        case .lowercase:
            let transformed = TextTransformer.transform(text, kind: .lowercase)
            TextReplacer.replaceSelectedText(with: transformed)

        case .capitalize:
            let transformed = TextTransformer.transform(text, kind: .capitalize)
            TextReplacer.replaceSelectedText(with: transformed)

        case .formatJSON:
            let transformed = TextTransformer.transform(text, kind: .formatJSON)
            ClipboardManager.copy(transformed)
            TextReplacer.replaceSelectedText(with: transformed, keepOnClipboard: true)

        case .removeLineBreaks:
            let transformed = TextTransformer.transform(text, kind: .removeLineBreaks)
            TextReplacer.replaceSelectedText(with: transformed)

        case .trimSpaces:
            let transformed = TextTransformer.transform(text, kind: .trimSpaces)
            TextReplacer.replaceSelectedText(with: transformed)

        case .urlEncode:
            let transformed = TextTransformer.transform(text, kind: .urlEncode)
            TextReplacer.replaceSelectedText(with: transformed)

        case .base64Encode:
            let transformed = TextTransformer.transform(text, kind: .base64Encode)
            TextReplacer.replaceSelectedText(with: transformed)

        case .ai, .more:
            // Intercepted and handled by FloatingBarController UI
            break
        }
    }

    // MARK: - Action Handlers

    private static func searchInBrowser(_ text: String) {
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.google.com/search?q=\(encoded)") else { return }
        NSWorkspace.shared.open(url)
    }

    private static func openInTranslate(_ text: String) {
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://translate.google.com/?text=\(encoded)") else { return }
        NSWorkspace.shared.open(url)
    }

    private static func lookupInDictionary(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "dict://\(encoded)") {
            NSWorkspace.shared.open(url)
        }
    }

    private static func speak(_ text: String) {
        let synthesizer = NSSpeechSynthesizer()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking()
        } else {
            synthesizer.startSpeaking(text)
        }
    }

    private static func openURL(_ text: String) {
        var urlString = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://\(urlString)"
        }
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    private static func composeEmail(to email: String) {
        guard let url = URL(string: "mailto:\(email)") else { return }
        NSWorkspace.shared.open(url)
    }

    private static func showSharePicker(for text: String, anchorView: NSView?) {
        guard let view = anchorView ?? NSApp.keyWindow?.contentView else { return }
        let picker = NSSharingServicePicker(items: [text])
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .maxY)
    }
}

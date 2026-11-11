import AppKit

/// Manages clipboard operations
struct ClipboardManager {
    /// Copy text to clipboard
    static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Get current clipboard text
    static func currentText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }
}

import AppKit

/// Seamlessly replaces or inserts text into the frontmost application
@MainActor
struct TextReplacer {

    /// Replaces the currently selected text in the frontmost app with `newText`
    static func replaceSelectedText(with newText: String, keepOnClipboard: Bool = true) {
        let pasteboard = NSPasteboard.general
        let oldString = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(newText, forType: .string)

        // Small delay to allow the mouse click event to finish and target window focus to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            simulatePaste()
        }

        // Only restore old clipboard if explicitly requested and NOT keepOnClipboard
        if !keepOnClipboard, let original = oldString {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                // If user hasn't copied anything new in between, restore old clipboard
                if pasteboard.string(forType: .string) == newText {
                    pasteboard.clearContents()
                    pasteboard.setString(original, forType: .string)
                }
            }
        }
    }

    /// Inserts text after the current selection
    static func insertText(_ textToInsert: String) {
        // Place on clipboard and paste
        replaceSelectedText(with: textToInsert)
    }

    // MARK: - Private

    private static func simulatePaste() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKeyCode: CGKeyCode = 0x09 // 'v' key in QWERTY layout

        guard let cmdVDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let cmdVUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return
        }

        cmdVDown.flags = .maskCommand
        cmdVUp.flags = .maskCommand

        cmdVDown.post(tap: .cghidEventTap)
        cmdVUp.post(tap: .cghidEventTap)
    }
}

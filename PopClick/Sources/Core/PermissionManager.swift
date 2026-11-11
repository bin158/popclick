import AppKit
import ApplicationServices

/// Manages macOS Accessibility permission
@MainActor
final class PermissionManager {
    static let shared = PermissionManager()

    private init() {}

    /// Whether the app has accessibility permission
    var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Request accessibility permission if not already granted
    func requestAccessibilityIfNeeded() {
        guard !hasAccessibilityPermission else { return }

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}

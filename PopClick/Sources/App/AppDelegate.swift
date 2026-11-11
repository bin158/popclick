import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var selectionManager: SelectionManager?
    private var floatingBarController: FloatingBarController?

    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            await self.setup()
        }
    }

    private func setup() async {
        // Hide dock icon — accessory menu bar resident
        NSApp.setActivationPolicy(.accessory)

        // Initialize global state
        _ = AppState.shared

        // Initialize controllers
        let floatingController = FloatingBarController()
        self.floatingBarController = floatingController

        let selManager = SelectionManager(
            onSelection: { [weak self] selection in
                Task { @MainActor in
                    self?.handleSelection(selection)
                }
            },
            onDeselect: { [weak floatingController] in
                Task { @MainActor in
                    floatingController?.dismiss(animated: true)
                }
            }
        )
        self.selectionManager = selManager

        // When toolbar dismisses, reset selection state so the same text can be re-triggered
        floatingController.onDismissCallback = { [weak selManager] in
            selManager?.resetLastSelection()
        }

        // Initialize status bar
        statusBarController = StatusBarController()

        // Check accessibility permission
        PermissionManager.shared.requestAccessibilityIfNeeded()

        // Configure Launch at Login
        if AppState.shared.launchAtLogin {
            LaunchAtLoginManager.shared.setEnabled(true)
        }

        // Start monitoring
        selManager.startMonitoring()
    }

    nonisolated func applicationWillTerminate(_ notification: Notification) {
        // Clean up
    }

    private func handleSelection(_ selection: TextSelection) {
        guard AppState.shared.isEnabled else { return }
        guard AppState.shared.showToolbar else { return }
        floatingBarController?.show(for: selection)
    }
}

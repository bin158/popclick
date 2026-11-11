import Foundation
import ServiceManagement

/// Manages macOS Launch at Login using SMAppService (macOS 13+)
@MainActor
final class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    @Published var isEnabled: Bool = false

    private init() {
        checkStatus()
    }

    /// Checks the current system registration status
    func checkStatus() {
        if #available(macOS 13.0, *) {
            isEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }

    /// Sets launch at login state
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if enabled {
                    if service.status != .enabled {
                        try service.register()
                    }
                } else {
                    if service.status == .enabled {
                        try service.unregister()
                    }
                }
                checkStatus()
                return true
            } catch {
                print("Failed to update Launch at Login: \(error.localizedDescription)")
                checkStatus()
                return false
            }
        }
        return false
    }
}

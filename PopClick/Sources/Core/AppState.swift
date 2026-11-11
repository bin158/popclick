import Foundation
import Combine

/// Global application state
@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isEnabled: Bool = true
    @Published var launchAtLogin: Bool = true
    @Published var showToolbar: Bool = true
    @Published var animationsEnabled: Bool = true
    @Published var hapticsEnabled: Bool = true
    @Published var selectionDelay: Double = 0.15
    @Published var toolbarStyle: ToolbarStyle = .glass
    @Published var appearance: AppearanceMode = .auto

    enum ToolbarStyle: String, CaseIterable {
        case glass
        case compact
    }

    enum AppearanceMode: String, CaseIterable {
        case auto
        case light
        case dark
    }

    private init() {
        loadDefaults()
    }

    func loadDefaults() {
        let defaults = UserDefaults.standard
        isEnabled = defaults.object(forKey: "isEnabled") as? Bool ?? true
        launchAtLogin = defaults.object(forKey: "launchAtLogin") as? Bool ?? true
        showToolbar = defaults.object(forKey: "showToolbar") as? Bool ?? true
        animationsEnabled = defaults.object(forKey: "animationsEnabled") as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: "hapticsEnabled") as? Bool ?? true
        selectionDelay = defaults.object(forKey: "selectionDelay") as? Double ?? 0.15

        if let style = defaults.string(forKey: "toolbarStyle") {
            toolbarStyle = ToolbarStyle(rawValue: style) ?? .glass
        }
        if let mode = defaults.string(forKey: "appearance") {
            appearance = AppearanceMode(rawValue: mode) ?? .auto
        }
    }

    func save() {
        let defaults = UserDefaults.standard
        defaults.set(isEnabled, forKey: "isEnabled")
        defaults.set(launchAtLogin, forKey: "launchAtLogin")
        defaults.set(showToolbar, forKey: "showToolbar")
        defaults.set(animationsEnabled, forKey: "animationsEnabled")
        defaults.set(hapticsEnabled, forKey: "hapticsEnabled")
        defaults.set(selectionDelay, forKey: "selectionDelay")
        defaults.set(toolbarStyle.rawValue, forKey: "toolbarStyle")
        defaults.set(appearance.rawValue, forKey: "appearance")
    }

    func resetDefaults() {
        isEnabled = true
        launchAtLogin = true
        showToolbar = true
        animationsEnabled = true
        hapticsEnabled = true
        selectionDelay = 0.15
        toolbarStyle = .glass
        appearance = .auto
        save()
        LaunchAtLoginManager.shared.setEnabled(true)
    }
}

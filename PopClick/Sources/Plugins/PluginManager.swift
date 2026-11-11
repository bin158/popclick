import Foundation
import AppKit
import Combine

/// Manages built-in and user-defined custom plugins
@MainActor
final class PluginManager: ObservableObject {
    static let shared = PluginManager()

    @Published var plugins: [Plugin] = []

    private let pluginsDirectory: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.pluginsDirectory = appSupport.appendingPathComponent("PopClick/Plugins", isDirectory: true)

        createPluginsDirectoryIfNeeded()
        loadPlugins()
    }

    /// Loads built-in plugins plus any custom JSON plugins found on disk
    func loadPlugins() {
        var result = defaultBuiltInPlugins()

        // Load custom JSON plugins from disk
        if let files = try? FileManager.default.contentsOfDirectory(at: pluginsDirectory, includingPropertiesForKeys: nil) {
            let decoder = JSONDecoder()
            for file in files where file.pathExtension == "json" {
                if let data = try? Data(contentsOf: file),
                   let customPlugin = try? decoder.decode(Plugin.self, from: data) {
                    if let index = result.firstIndex(where: { $0.id == customPlugin.id }) {
                        result[index] = customPlugin
                    } else {
                        result.append(customPlugin)
                    }
                }
            }
        }

        // Apply enabled states stored in UserDefaults
        let disabledIds = UserDefaults.standard.stringArray(forKey: "disabledPluginIds") ?? []
        for i in 0..<result.count {
            if disabledIds.contains(result[i].id) {
                result[i].isEnabled = false
            }
        }

        self.plugins = result
    }

    /// Toggles a plugin's enabled status and persists state
    func togglePlugin(_ plugin: Plugin) {
        guard let index = plugins.firstIndex(where: { $0.id == plugin.id }) else { return }
        plugins[index].isEnabled.toggle()

        let disabledIds = plugins.filter { !$0.isEnabled }.map { $0.id }
        UserDefaults.standard.set(disabledIds, forKey: "disabledPluginIds")
    }

    /// Executes the specified plugin with text input
    func execute(_ plugin: Plugin, with text: String) {
        switch plugin.actionType {
        case .urlTemplate:
            guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
            let urlString = plugin.payload.replacingOccurrences(of: "{query}", with: encoded)
                                         .replacingOccurrences(of: "{text}", with: encoded)
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }

        case .markdownTransform:
            if plugin.payload == "quote" {
                let lines = text.components(separatedBy: .newlines)
                let quoted = lines.map { "> " + $0 }.joined(separator: "\n")
                TextReplacer.replaceSelectedText(with: quoted)
            }

        case .shellScript:
            runShellScript(plugin.payload, input: text)

        case .aiPrompt:
            // Forwarded to AIService
            break
        }
    }

    /// Opens the plugins directory in Finder
    func openPluginsFolder() {
        createPluginsDirectoryIfNeeded()
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: pluginsDirectory.path)
    }

    // MARK: - Private

    private func createPluginsDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(at: pluginsDirectory, withIntermediateDirectories: true)
    }

    private func runShellScript(_ script: String, input: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", script]

            let inputPipe = Pipe()
            let outputPipe = Pipe()
            process.standardInput = inputPipe
            process.standardOutput = outputPipe

            do {
                try process.run()
                if let inputData = input.data(using: .utf8) {
                    inputPipe.fileHandleForWriting.write(inputData)
                    inputPipe.fileHandleForWriting.closeFile()
                }
                process.waitUntilExit()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .newlines),
                   !output.isEmpty {
                    DispatchQueue.main.async {
                        TextReplacer.replaceSelectedText(with: output)
                    }
                }
            } catch {
                print("Failed to run plugin script: \(error)")
            }
        }
    }

    private func defaultBuiltInPlugins() -> [Plugin] {
        return [
            Plugin(
                id: "builtin.github",
                name: "Search GitHub",
                icon: "chevron.left.forwardslash.chevron.right",
                description: "Search repositories and code on GitHub",
                shortcut: "⌘G",
                category: .developer,
                actionType: .urlTemplate,
                payload: "https://github.com/search?q={query}",
                isEnabled: true
            ),
            Plugin(
                id: "builtin.youtube",
                name: "Search YouTube",
                icon: "play.rectangle",
                description: "Search videos on YouTube",
                shortcut: nil,
                category: .web,
                actionType: .urlTemplate,
                payload: "https://www.youtube.com/results?search_query={query}",
                isEnabled: true
            ),
            Plugin(
                id: "builtin.x",
                name: "Search X",
                icon: "bubble.left.and.bubble.right",
                description: "Search posts on X / Twitter",
                shortcut: nil,
                category: .web,
                actionType: .urlTemplate,
                payload: "https://twitter.com/search?q={query}",
                isEnabled: true
            ),
            Plugin(
                id: "builtin.duckduckgo",
                name: "DuckDuckGo",
                icon: "magnifyingglass.circle",
                description: "Private web search with DuckDuckGo",
                shortcut: nil,
                category: .web,
                actionType: .urlTemplate,
                payload: "https://duckduckgo.com/?q={query}",
                isEnabled: true
            ),
            Plugin(
                id: "builtin.markdown_quote",
                name: "Markdown Quote",
                icon: "quote.opening",
                description: "Transform selected text into Markdown blockquote",
                shortcut: nil,
                category: .utilities,
                actionType: .markdownTransform,
                payload: "quote",
                isEnabled: true
            )
        ]
    }
}

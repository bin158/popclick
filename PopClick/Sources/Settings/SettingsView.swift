import SwiftUI

/// Top-tier macOS native Settings window with standard Apple HIG navigation and styling
struct SettingsView: View {
    @ObservedObject var appState = AppState.shared
    @ObservedObject var aiService = AIService.shared
    @ObservedObject var pluginManager = PluginManager.shared
    @ObservedObject var loc = LocalizationManager.shared

    var body: some View {
        TabView {
            GeneralSettingsTab(appState: appState, loc: loc)
                .tabItem {
                    Label(loc.localized("General", "通用"), systemImage: "gearshape")
                }

            AppearanceSettingsTab(appState: appState, loc: loc)
                .tabItem {
                    Label(loc.localized("Appearance", "外观"), systemImage: "paintbrush")
                }

            ActionsSettingsTab(appState: appState, loc: loc)
                .tabItem {
                    Label(loc.localized("Actions", "动作"), systemImage: "bolt.horizontal")
                }

            AISettingsTab(aiService: aiService, loc: loc)
                .tabItem {
                    Label(loc.localized("AI", "AI 助手"), systemImage: "sparkles")
                }

            PluginsSettingsTab(pluginManager: pluginManager, loc: loc)
                .tabItem {
                    Label(loc.localized("Plugins", "扩展插件"), systemImage: "puzzlepiece.extension")
                }

            ShortcutsSettingsTab(loc: loc)
                .tabItem {
                    Label(loc.localized("Shortcuts", "快捷键"), systemImage: "command")
                }

            AdvancedSettingsTab(appState: appState, loc: loc)
                .tabItem {
                    Label(loc.localized("Advanced", "高级"), systemImage: "slider.horizontal.3")
                }
        }
        .frame(minWidth: 560, minHeight: 440)
        .padding(16)
    }
}

// MARK: - General Tab

struct GeneralSettingsTab: View {
    @ObservedObject var appState: AppState
    @ObservedObject var loc: LocalizationManager

    var body: some View {
        Form {
            Section {
                Toggle(loc.localized("Enable PopClick", "启用 PopClick"), isOn: $appState.isEnabled)
                    .onChange(of: appState.isEnabled) { _ in appState.save() }

                Toggle(loc.localized("Launch at Login", "开机自启动"), isOn: $appState.launchAtLogin)
                    .onChange(of: appState.launchAtLogin) { val in
                        appState.save()
                        LaunchAtLoginManager.shared.setEnabled(val)
                    }

                Toggle(loc.localized("Show Toolbar Automatically", "划词时自动浮出工具栏"), isOn: $appState.showToolbar)
                    .onChange(of: appState.showToolbar) { _ in appState.save() }

                Toggle(loc.localized("Haptic Feedback", "触感震动反馈"), isOn: $appState.hapticsEnabled)
                    .onChange(of: appState.hapticsEnabled) { _ in appState.save() }
            } header: {
                Text(loc.localized("Behavior", "行为模式"))
            }

            Section {
                Picker(loc.localized("Language", "界面语言"), selection: $loc.currentLanguage) {
                    ForEach(LocalizationManager.Language.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text(loc.localized("Language", "多语言"))
            }

            Section {
                HStack {
                    Text(loc.localized("Accessibility Permission", "辅助功能权限"))
                    Spacer()
                    if PermissionManager.shared.hasAccessibilityPermission {
                        Label(loc.localized("Authorized", "已授权"), systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 13))
                    } else {
                        Button(loc.localized("Grant Access…", "授予权限…")) {
                            PermissionManager.shared.requestAccessibilityIfNeeded()
                        }
                    }
                }
            } header: {
                Text(loc.localized("Permissions", "系统权限"))
            } footer: {
                Text(loc.localized("PopClick uses the macOS Accessibility API to silently read selected text without intrusive clipboard polling.", "PopClick 采用 macOS 原生 Accessibility API 优雅读取选区文字，零剪贴板轮询，安全低功耗。"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Appearance Tab

struct AppearanceSettingsTab: View {
    @ObservedObject var appState: AppState
    @ObservedObject var loc: LocalizationManager

    var body: some View {
        Form {
            Section {
                Picker(loc.localized("Theme", "主题外观"), selection: $appState.appearance) {
                    Text(loc.localized("Automatic", "跟随系统")).tag(AppState.AppearanceMode.auto)
                    Text(loc.localized("Light Glass", "浅色毛玻璃")).tag(AppState.AppearanceMode.light)
                    Text(loc.localized("Dark Glass", "深色毛玻璃")).tag(AppState.AppearanceMode.dark)
                }
                .pickerStyle(.segmented)
                .onChange(of: appState.appearance) { _ in appState.save() }

                Picker(loc.localized("Capsule Style", "工具栏样式"), selection: $appState.toolbarStyle) {
                    Text(loc.localized("Floating Glass", "悬浮半透明玻璃")).tag(AppState.ToolbarStyle.glass)
                    Text(loc.localized("Compact Minimal", "紧凑极简")).tag(AppState.ToolbarStyle.compact)
                }
                .pickerStyle(.segmented)
                .onChange(of: appState.toolbarStyle) { _ in appState.save() }

                Toggle(loc.localized("Fluid Animations (120ms)", "流畅微动效 (120ms)"), isOn: $appState.animationsEnabled)
                    .onChange(of: appState.animationsEnabled) { _ in appState.save() }
            } header: {
                Text(loc.localized("Visual Style", "视觉风格"))
            }

            Section {
                Slider(value: $appState.selectionDelay, in: 0.05...0.40, step: 0.05) {
                    Text(loc.localized("Selection Detection Delay", "选区触发延迟"))
                } minimumValueLabel: {
                    Text("50ms")
                } maximumValueLabel: {
                    Text("400ms")
                }
                .onChange(of: appState.selectionDelay) { _ in appState.save() }

                Text(String(format: loc.localized("Current delay: %.0f ms", "当前延迟: %.0f 毫秒"), appState.selectionDelay * 1000))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } header: {
                Text(loc.localized("Timing", "时钟与响应速度"))
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Actions Tab

struct ActionsSettingsTab: View {
    @ObservedObject var appState: AppState
    @ObservedObject var loc: LocalizationManager

    var body: some View {
        Form {
            Section {
                ForEach(ActionType.allCases.filter { $0 != .more }) { action in
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: action.iconName)
                            .frame(width: 20)
                            .foregroundStyle(action == .ai ? Color.accentColor : Color.primary.opacity(0.8))

                        Text(action.title)
                            .font(DesignTokens.Typography.bodyFont)

                        Spacer()

                        if let shortcut = action.shortcutHint {
                            Text(shortcut)
                                .font(DesignTokens.Typography.shortcutFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text(loc.localized("Available Toolbar Actions", "工具栏动作列表"))
            } footer: {
                Text(loc.localized("Actions are dynamically prioritized based on content semantics (URLs, Emails, Code snippets, Numbers).", "工具栏动作会根据选区内容语义（链接、邮箱、代码片段、纯文本等）自动动态优先排布。"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - AI Settings Tab

struct AISettingsTab: View {
    @ObservedObject var aiService: AIService
    @ObservedObject var loc: LocalizationManager

    var body: some View {
        Form {
            Section {
                Toggle(loc.localized("Auto Failover across Providers", "额度耗尽自动轮换到下一个平台"), isOn: $aiService.autoFailoverEnabled)
                    .onChange(of: aiService.autoFailoverEnabled) { _ in aiService.saveSettings() }
            } header: {
                Text(loc.localized("Quota Failover Engine", "智能故障转移与额度轮换"))
            } footer: {
                Text(loc.localized("When an API key reaches its rate limit or daily free quota, PopClick automatically fails over to the next configured provider without interrupting your flow.", "当某个平台的免费额度用光或触发限流时，PopClick 会自动无缝轮换到列表中的下一个平台继续处理，完全无需人工干预。"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Section {
                ForEach(aiService.providers) { provider in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(provider.name)
                                .font(DesignTokens.Typography.bodyMedium)

                            Spacer()

                            Button(loc.localized("Get Free Key ↗", "获取免费 Key ↗")) {
                                if let url = URL(string: provider.freeKeyURL) {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .font(.system(size: 11))
                            .buttonStyle(.borderless)

                            Toggle("", isOn: Binding(
                                get: { provider.isEnabled },
                                set: { _ in aiService.toggleProvider(id: provider.id) }
                            ))
                            .labelsHidden()
                        }

                        Text(provider.freeQuotaDescription)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)

                        if provider.id != "ollama" {
                            SecureField(loc.localized("Paste API Key here…", "在此粘贴 API 密钥…"), text: Binding(
                                get: { provider.apiKey },
                                set: { newKey in aiService.updateProviderApiKey(id: provider.id, key: newKey) }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }

                        HStack(spacing: 8) {
                            Text(loc.localized("Model:", "模型:"))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)

                            TextField("Model identifier", text: Binding(
                                get: { provider.model },
                                set: { newModel in aiService.updateProviderModel(id: provider.id, model: newModel) }
                            ))
                            .font(.system(size: 11, design: .monospaced))
                            .textFieldStyle(.roundedBorder)

                            Button(action: {
                                aiService.testConnectionForProvider(id: provider.id)
                            }) {
                                if aiService.isTesting[provider.id] == true {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .frame(width: 14, height: 14)
                                } else {
                                    Text(loc.localized("Test Connection", "测试连接"))
                                }
                            }
                            .font(.system(size: 11))
                            .buttonStyle(.bordered)
                            .disabled(aiService.isTesting[provider.id] == true)
                        }

                        if let msg = aiService.testStatuses[provider.id] {
                            Text(msg)
                                .font(.system(size: 10))
                                .foregroundStyle(msg.contains("Connected") ? Color.green : Color.red)
                                .lineLimit(2)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                HStack {
                    Text(loc.localized("Free AI Providers Pool (Priority Order)", "免费模型服务商池（按优先级排列）"))
                    Spacer()
                    Button(loc.localized("Restore Default Models", "恢复推荐模型")) {
                        aiService.loadSettings()
                    }
                    .font(.system(size: 10))
                }
            } footer: {
                Text(loc.localized("If all keys are empty or offline, PopClick seamlessly uses its built-in smart simulation engine.", "若未配置任何 Key 或处于离线状态，PopClick 会自动启动内置智能离线引擎，随时可用。"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Plugins Tab

struct PluginsSettingsTab: View {
    @ObservedObject var pluginManager: PluginManager
    @ObservedObject var loc: LocalizationManager

    var body: some View {
        Form {
            Section {
                ForEach(pluginManager.plugins) { plugin in
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: plugin.icon)
                            .frame(width: 22)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.primary.opacity(0.85))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(plugin.name)
                                .font(DesignTokens.Typography.bodyMedium)
                            Text(plugin.description)
                                .font(DesignTokens.Typography.captionFont)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { plugin.isEnabled },
                            set: { _ in pluginManager.togglePlugin(plugin) }
                        ))
                        .labelsHidden()
                    }
                    .padding(.vertical, 3)
                }
            } header: {
                HStack {
                    Text(loc.localized("Installed Extensions", "已安装插件"))
                    Spacer()
                    Button(loc.localized("Open Plugins Folder", "打开插件目录…")) {
                        pluginManager.openPluginsFolder()
                    }
                    .font(.system(size: 11))
                }
            } footer: {
                Text(loc.localized("You can create custom JSON plugins in the Application Support directory to add your own search engines, AI workflows, or shell scripts.", "你可在插件目录中直接编写 JSON 配置文件，快速扩展自定义网页搜索、脚本工具或 AI 提示词。"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Shortcuts Tab

struct ShortcutsSettingsTab: View {
    @ObservedObject var loc: LocalizationManager

    var body: some View {
        Form {
            Section {
                shortcutRow(label: loc.localized("Quick Copy", "极速复制"), shortcut: "⌘ C")
                shortcutRow(label: loc.localized("Web Search", "网页搜索"), shortcut: "⌘ F")
                shortcutRow(label: loc.localized("Open PopClick AI Agent", "打开 PopClick AI Agent"), shortcut: "⌘ J")
                shortcutRow(label: loc.localized("Dismiss Toolbar", "关闭浮窗"), shortcut: "Esc")
            } header: {
                Text(loc.localized("System Shortcuts", "常用快捷键"))
            } footer: {
                Text(loc.localized("When the PopClick toolbar is displayed, you can press these keys directly.", "当 PopClick 浮动工具栏处于显示状态时，可直接按下快捷键触发对应动作。"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func shortcutRow(label: String, shortcut: String) -> some View {
        HStack {
            Text(label)
                .font(DesignTokens.Typography.bodyFont)
            Spacer()
            Text(shortcut)
                .font(DesignTokens.Typography.shortcutFont)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
        }
    }
}

// MARK: - Advanced Tab

struct AdvancedSettingsTab: View {
    @ObservedObject var appState: AppState
    @ObservedObject var loc: LocalizationManager

    var body: some View {
        Form {
            Section {
                HStack {
                    Text(loc.localized("Reset All Settings", "恢复所有默认设置"))
                    Spacer()
                    Button(loc.localized("Reset…", "重置…")) {
                        appState.resetDefaults()
                    }
                }
            } header: {
                Text(loc.localized("Maintenance", "重置与维护"))
            }

            Section {
                HStack {
                    Text("PopClick")
                        .font(DesignTokens.Typography.headlineFont)
                    Spacer()
                    Text("Version 1.0.0 (Native Sequoia Edition)")
                        .font(DesignTokens.Typography.captionFont)
                        .foregroundStyle(.secondary)
                }

                Text(loc.localized("Handcrafted with AppKit, SwiftUI & Swift Concurrency.\nDesigned strictly for macOS.", "以纯原生 AppKit、SwiftUI 与 Swift Concurrency 匠心雕琢。\n只为极致的 macOS 原生体验。"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } header: {
                Text(loc.localized("About", "关于"))
            }
        }
        .formStyle(.grouped)
    }
}

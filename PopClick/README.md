# ✦ PopClick (PopClick AI Agent)
> **A high-end, ultra-modern macOS text action launcher.**
> Handcrafted with native AppKit, SwiftUI & Swift Concurrency. Strictly following Apple Human Interface Guidelines.

---

## 🌟 Overview & Product Philosophy

PopClick is a native macOS productivity tool that elevates text selection into an immediate, fluid, and delightful experience.

```text
Select Text in ANY App ──> Floating Glass Capsule ──> Instant Action / PopClick AI Agent ──> Seamless Replace or Copy
```

### Core Tenets
- **Visual Design > Interaction Experience > Animation Details > Feature Completeness**
- **Native Sequoia / Tahoe Aesthetics**: True `NSVisualEffectView` HUD glass material with specular light border highlights, micro-drop shadows, and SF Pro typography.
- **Zero Pollution & Zero Polling**: Relies exclusively on `NSEvent.addGlobalMonitorForEvents` and macOS Accessibility APIs. **0% idle CPU footprint**, no battery drain.
- **Non-Activating Panels**: Uses non-activating borderless `NSPanel` floating windows (`.nonactivatingPanel`). Clicking actions will **never** steal focus or drop the active text selection highlight from the frontmost app.

---

## 📂 Architecture & Directory Structure

```text
PopClick/
├── Package.swift                     # Swift Package Manager manifest
├── build.sh                          # High-performance native compilation & ad-hoc code-signing
├── Resources/
│   └── Info.plist                    # LSUIElement=true (accessory menu-bar resident)
└── Sources/
    ├── App/
    │   ├── PopClickApp.swift         # @main entry point
    │   ├── AppDelegate.swift         # Activation policy, system wiring, lifecycle
    │   └── StatusBarController.swift # Menu Bar controller (status, quick toggle, settings window)
    ├── Core/
    │   ├── AppState.swift            # Global reactive state machine & UserDefaults persistence
    │   ├── EventManager.swift        # Global low-overhead mouse/keyboard event interception
    │   └── PermissionManager.swift   # Accessibility (AX) permission checks & OS dialog triggering
    ├── Selection/
    │   ├── AccessibilityManager.swift# High-precision AX text & bounds extraction + coordinate conversions
    │   ├── ClipboardManager.swift    # Safe clipboard read/write/restore
    │   ├── SelectionManager.swift    # Debounced selection tracking (configurable 50-400ms delay)
    │   └── TextSelection.swift       # Semantic analyzer (PlainText, URL, Email, Code, Number)
    ├── FloatingBar/
    │   ├── FloatingBarController.swift# NSPanel lifecycle, popover positioning & dismissal
    │   ├── FloatingBarView.swift     # Glass capsule SwiftUI view, copy feedback badge
    │   ├── ActionButton.swift        # SF Symbol micro-interaction buttons (120ms hover & press)
    │   ├── PositionCalculator.swift  # Smart screen edge detection, menu bar & dock collision avoidance
    │   └── MoreMenuView.swift        # Expanded glass popover (All Actions, Utilities, Plugins)
    ├── Actions/
    │   ├── ActionType.swift          # Complete catalog of actions with semantic icons & shortcuts
    │   └── ActionExecutor.swift      # Immediate action execution (Search, Translate, Dict, TTS, Share)
    ├── AI/
    │   ├── AIService.swift           # OpenAI, Claude, Ollama & Custom endpoint support + local fallback
    │   ├── AIPanelController.swift   # Floating AI modal panel coordinator
    │   ├── AIPanelViewModel.swift    # Prompt selection, loading, and result state handling
    │   └── AIPanelView.swift         # Clean Apple-native AI panel (Original vs Result, Diff, Replace)
    ├── Plugins/
    │   ├── Plugin.swift              # Extensible plugin data model (URL templates, scripts, prompts)
    │   └── PluginManager.swift       # Built-in plugins + dynamic JSON loader from Application Support
    ├── Utilities/
    │   ├── TextTransformer.swift     # UPPER, lower, Title Case, Format JSON, Unwrap, Trim, Base64, URL
    │   └── TextReplacer.swift        # Synthesizes Cmd+V to replace selection in active application
    ├── DesignSystem/
    │   ├── DesignTokens.swift        # Master tokens (radii, spacing, shadows, typography, haptics)
    │   └── GlassEffect.swift         # Multi-layer HUD glass with continuous corners & inner light gradients
    ├── Settings/
    │   └── SettingsView.swift        # Full macOS 7-tab Settings window
    └── Localization/
        └── LocalizationManager.swift # English & 简体中文 dual-language runtime switcher
```

---

## 🛠️ Complete Feature Matrix (Phases 1 – 7)

### 1. Floating Glass Capsule (Toolbar)
- **Glass Material**: Dynamic macOS dark/light mode vibrant glass with subtle specular borders.
- **Micro-Animations**:
  - Pop-in: `opacity: 0 -> 1`, `scale: 0.96 -> 1.0`, `offsetY: 4 -> 0` (150ms).
  - Hover: `scale: 1.0 -> 1.03` + subtle illumination (120ms).
  - Press: `scale: 0.94` + haptic feedback.
- **Copy Feedback**: Smooth inline checkmark pill ("✓ Copied") that appears and gracefully fades out.
- **Smart Collision Avoidance**: Automatically calculates selection center. If near screen top or menu bar, automatically flips to display below the text. Clamps gracefully to display margins.

### 2. Context-Aware Action Engine
PopClick analyzes the selected string in real-time and surfaces the most relevant actions:
- **Plain Text**: `Copy`, `Search`, `Translate`, `AI (PopClick AI Agent)`, `More (⋯)`
- **Code**: `Copy`, `Explain`, `Comment`, `Fix`, `Refactor`, `AI`, `More (⋯)`
- **JSON**: `Copy`, `Format`, `Validate`, `Explain`, `AI`
- **SQL**: `Copy`, `Format`, `Explain`, `Optimize`, `AI`
- **URLs**: `Open`, `Copy`, `Share`, `AI`, `More (⋯)`
- **Email Addresses**: `Email`, `Copy`, `AI`, `More (⋯)`
- **Numbers**: `Copy`, `Search`, `AI`, `More (⋯)`

### 3. Native Text Utilities
Access instantly via the `⋯ More` glass popover:
- `UPPERCASE` / `lowercase` / `Capitalize (Title Case)`
- `Format JSON` (auto-indents valid JSON strings)
- `Remove Line Breaks (Unwrap)`
- `Trim Spaces`
- `URL Encode` / `URL Decode`
- `Base64 Encode` / `Base64 Decode`
- Native dictionary lookup (`dict://`)
- Native speech synthesis (`NSSpeechSynthesizer`)
- Native system share sheet (`NSSharingServicePicker`)

### 4. Apple-Native PopClick AI Agent & In-Place Replacement
Clicking the `✦ AI` button or code action opens the minimalist **PopClick AI Agent** modal:
- **Preset Actions**: Rewrite, Summarize, Translate, Fix Grammar, Explain, Professional Tone.
- **Code Intelligence Actions**: Explain, Comment, Documentation, Fix, Refactor, Optimize, Generate Test, Security Review, Format.
- **Diff & Code Viewers**: Unified LCS line-by-line diff with line numbers and word wrap toggle (`Wrap / Scroll`).
- **Custom Instructions**: Free-form natural language prompt ("Make this sound like a polite email" or "Refactor to async/await").
- **Multi-Provider Engine**:
  - Google Gemini (`gemini-flash-lite-latest`)
  - OpenAI (`gpt-4o-mini`, `gpt-4o`)
  - Anthropic Claude (`claude-3-5-sonnet`)
  - Local Ollama (`llama3.2`, etc.)
  - Custom API compatible endpoints
  - **Zero-Config Intelligent Fallback**: Functions immediately out-of-the-box with built-in smart simulation.
- **PopClick AI Agent Output Actions**:
  - **Copy**: Places output or clean code onto clipboard.
  - **Replace Selection**: Strictly replaces the selected code or text directly in the active app without altering surrounding code.
  - **Insert**: Appends output after current selection.
  - **Retry**: Re-runs prompt with modified parameters.

### 5. Plugin Architecture
Users can extend PopClick by dropping `.json` files into:
`~/Library/Application Support/PopClick/Plugins/`

Example plugin (`search_github.json`):
```json
{
  "id": "custom.github",
  "name": "Search GitHub",
  "icon": "chevron.left.forwardslash.chevron.right",
  "description": "Search code on GitHub",
  "category": "Developer",
  "actionType": "urlTemplate",
  "payload": "https://github.com/search?q={query}",
  "isEnabled": true
}
```

### 6. Full macOS Native Settings
Includes 7 distinct tabs following macOS Sequoia design conventions:
1. **General**: App activation, auto-show on selection, haptic feedback, accessibility permission verification, language selector.
2. **Appearance**: Theme selection (Auto / Light / Dark), capsule styles, fluid animations toggle, response delay slider (50ms – 400ms).
3. **Actions**: Visual catalog of all built-in actions and keyboard shortcuts.
4. **AI**: Provider picker, API key, model configuration, and custom endpoints.
5. **Plugins**: Toggles for all active plugins, with an "Open Plugins Folder" button.
6. **Shortcuts**: Shortcut reference card (`⌘C`, `⌘F`, `⌘J`, `Esc`).
7. **Advanced**: Reset to defaults, version info.

---

## 🚀 How to Build & Run

```bash
# 1. Navigate to project directory
cd /Users/binye/Documents/01_Projects/popclick/PopClick

# 2. Build and sign the application bundle
bash build.sh

# 3. Launch PopClick
open .build/direct/PopClick.app
```

### Granting Accessibility Permissions
Because PopClick reads selected text from other applications, macOS requires one-time Accessibility authorization:
1. Launch PopClick.
2. If prompted, open **System Settings -> Privacy & Security -> Accessibility**.
3. Toggle **PopClick** ON.

import AppKit
import SwiftUI

/// Controls the floating toolbar panel window, AI panel, Translate block, and more popover
@MainActor
final class FloatingBarController {
    private var panel: NSPanel?
    private var popoverPanel: NSPanel?
    private var aiPanelController = AIPanelController()
    private var translatePanelController = TranslatePanelController()

    private var currentSelection: TextSelection?
    private var currentViewModel: FloatingBarViewModel?
    private var dismissMonitor: Any?
    private var escapeMonitor: Any?

    var onDismissCallback: (() -> Void)?

    /// Show the floating toolbar for a given text selection
    func show(for selection: TextSelection) {
        // Dismiss any existing popups immediately without animation
        dismiss(animated: false)

        currentSelection = selection
        let actions = selection.contentType.suggestedActions

        // Create view model
        let viewModel = FloatingBarViewModel(
            actions: actions,
            onAction: { [weak self] action in
                self?.handleAction(action)
            },
            onDismiss: { [weak self] in
                self?.dismiss(animated: true)
            }
        )
        currentViewModel = viewModel

        // Create the SwiftUI view
        let floatingView = FloatingBarView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: floatingView)
        hostingView.setFrameSize(hostingView.fittingSize)

        let toolbarSize = hostingView.fittingSize

        // Calculate position (with full multi-monitor awareness)
        let origin = PositionCalculator.calculatePosition(
            for: selection.bounds,
            toolbarSize: toolbarSize,
            mouseLocation: selection.mouseLocation
        )

        // Create NSPanel (floating, non-activating)
        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: toolbarSize),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.contentView = hostingView

        panel.orderFrontRegardless()
        self.panel = panel

        setupDismissMonitors()
    }

    /// Dismiss the floating toolbar and any popovers
    func dismiss(animated: Bool = true) {
        removeDismissMonitors()
        dismissPopover()

        guard let currentPanel = panel else {
            currentSelection = nil
            onDismissCallback?()
            return
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = DesignTokens.Animation.disappearDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                currentPanel.animator().alphaValue = 0
            } completionHandler: { [weak self] in
                Task { @MainActor in
                    if self?.panel === currentPanel {
                        self?.panel?.orderOut(nil)
                        self?.panel = nil
                        self?.currentViewModel = nil
                    } else {
                        currentPanel.orderOut(nil)
                    }
                }
            }
        } else {
            currentPanel.orderOut(nil)
            if self.panel === currentPanel {
                self.panel = nil
                self.currentViewModel = nil
            }
        }

        currentSelection = nil
        onDismissCallback?()
    }

    // MARK: - Action Handling

    private func handleAction(_ action: ActionType) {
        guard let selection = currentSelection else { return }

        switch action {
        case .translate:
            dismiss(animated: false)
            translatePanelController.show(for: selection.text, anchorBounds: selection.bounds)

        case .ai:
            dismiss(animated: false)
            aiPanelController.show(for: selection.text, anchorBounds: selection.bounds)

        case .more:
            if popoverPanel != nil {
                dismissPopover()
            } else {
                showMorePopover(for: selection)
            }

        default:
            if popoverPanel != nil {
                dismissPopover()
            }
            if action == .copy {
                currentViewModel?.triggerFeedback(message: "Copied")
            } else if action == .formatJSON {
                currentViewModel?.triggerFeedback(message: "JSON Formatted & Copied")
            }

            ActionExecutor.execute(action, with: selection.text, anchorView: panel?.contentView)

            let delay: TimeInterval = (action == .copy || action == .formatJSON) ? 0.85 : 0.12
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.dismiss(animated: true)
            }
        }
    }

    // MARK: - More Menu Popover

    private func showMorePopover(for selection: TextSelection) {
        guard let toolbarPanel = panel else { return }

        let moreVM = MoreMenuViewModel(
            text: selection.text,
            onAction: { [weak self] action in
                self?.handleAction(action)
            },
            onPlugin: { [weak self] plugin in
                PluginManager.shared.execute(plugin, with: selection.text)
                self?.dismiss(animated: true)
            },
            onOpenAI: { [weak self] in
                self?.dismiss(animated: false)
                self?.aiPanelController.show(for: selection.text, anchorBounds: selection.bounds)
            },
            onDismiss: { [weak self] in
                self?.dismissPopover()
            }
        )

        let popoverView = MoreMenuView(viewModel: moreVM)
        let hostingView = NSHostingView(rootView: popoverView)
        hostingView.setFrameSize(hostingView.fittingSize)
        let popoverSize = hostingView.fittingSize

        // Calculate position relative to toolbar
        var popoverOrigin = CGPoint(
            x: toolbarPanel.frame.maxX - popoverSize.width,
            y: toolbarPanel.frame.minY - popoverSize.height - 6
        )

        // Find the active screen for this toolbar
        let screen = NSScreen.screens.first(where: { $0.frame.contains(toolbarPanel.frame.origin) }) ?? NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.visibleFrame

        if popoverOrigin.y < screenFrame.minY {
            popoverOrigin.y = toolbarPanel.frame.maxY + 6
        }
        popoverOrigin.x = max(screenFrame.minX + 8, min(screenFrame.maxX - popoverSize.width - 8, popoverOrigin.x))

        let pPanel = NSPanel(
            contentRect: NSRect(origin: popoverOrigin, size: popoverSize),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        pPanel.isOpaque = false
        pPanel.backgroundColor = .clear
        pPanel.hasShadow = false
        pPanel.level = .floating
        pPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        pPanel.contentView = hostingView

        pPanel.alphaValue = 0
        pPanel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignTokens.Animation.fast
            pPanel.animator().alphaValue = 1.0
        }

        self.popoverPanel = pPanel
    }

    private func dismissPopover() {
        guard let pPanel = popoverPanel else { return }
        pPanel.orderOut(nil)
        popoverPanel = nil
    }

    // MARK: - Dismiss Monitors

    private func setupDismissMonitors() {
        // Dismiss when user clicks outside
        dismissMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }

                let mouseLoc = NSEvent.mouseLocation
                let inToolbar = self.panel?.frame.contains(mouseLoc) ?? false
                let inPopover = self.popoverPanel?.frame.contains(mouseLoc) ?? false
                let inAIPanel = self.aiPanelController.isVisible
                let inTranslate = self.translatePanelController.isVisible

                if !inToolbar && !inPopover && !inAIPanel && !inTranslate {
                    self.dismiss(animated: true)
                }
            }
        }

        // Dismiss on Escape key
        escapeMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown]
        ) { [weak self] event in
            if event.keyCode == 53 { // Escape
                Task { @MainActor in
                    self?.dismiss(animated: true)
                    self?.aiPanelController.dismiss()
                    self?.translatePanelController.dismiss()
                }
            }
        }
    }

    private func removeDismissMonitors() {
        if let monitor = dismissMonitor {
            NSEvent.removeMonitor(monitor)
            dismissMonitor = nil
        }
        if let monitor = escapeMonitor {
            NSEvent.removeMonitor(monitor)
            escapeMonitor = nil
        }
    }
}

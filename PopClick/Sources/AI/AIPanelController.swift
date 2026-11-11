import AppKit
import SwiftUI

/// Manages the floating AI modal panel with full multi-monitor awareness and dynamic resizing
@MainActor
final class AIPanelController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<AIPanelView>?

    func show(
        for text: String,
        anchorBounds: CGRect,
        codeContext: CodeContext? = nil,
        initialAction: AIService.AIAction? = nil
    ) {
        dismiss()

        let viewModel = AIPanelViewModel(
            originalText: text,
            codeContext: codeContext,
            initialAction: initialAction
        ) { [weak self] in
            self?.dismiss()
        }

        let panelView = AIPanelView(viewModel: viewModel)
        let hosting = NSHostingView(rootView: panelView)
        hosting.setFrameSize(hosting.fittingSize)
        self.hostingView = hosting

        let size = hosting.fittingSize

        // Locate target screen (handles multi-monitor setups)
        let mouseLoc = NSEvent.mouseLocation
        let targetPoint = (anchorBounds.width > 2 && anchorBounds.height > 2)
            ? CGPoint(x: anchorBounds.midX, y: anchorBounds.midY)
            : mouseLoc

        let screen = NSScreen.screens.first(where: { $0.frame.contains(targetPoint) })
            ?? NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) })
            ?? NSScreen.main
            ?? NSScreen.screens.first!

        let screenFrame = screen.visibleFrame

        // Center relative to selection or screen
        var origin = CGPoint(
            x: anchorBounds.midX - size.width / 2,
            y: anchorBounds.maxY + 12
        )

        if origin.y + size.height > screenFrame.maxY {
            origin.y = anchorBounds.minY - size.height - 12
        }

        origin.x = max(screenFrame.minX + 16, min(screenFrame.maxX - size.width - 16, origin.x))
        origin.y = max(screenFrame.minY + 16, min(screenFrame.maxY - size.height - 16, origin.y))

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.minSize = NSSize(width: 480, height: 200)
        panel.maxSize = NSSize(width: 1200, height: 950)
        panel.contentView = hosting

        // Handle dynamic resizing between promptSelection, loading, and result
        viewModel.onSizeChanged = { [weak panel, weak hosting, weak self] in
            guard let panel = panel, let hosting = hosting else { return }
            hosting.layoutSubtreeIfNeeded()
            let targetSize = hosting.fittingSize
            var newFrame = panel.frame
            let oldOrigin = newFrame.origin
            newFrame.size = targetSize
            newFrame.origin = CGPoint(
                x: oldOrigin.x - (targetSize.width - panel.frame.width) / 2,
                y: oldOrigin.y - (targetSize.height - panel.frame.height) / 2
            )

            // Keep within active screen bounds
            let centerPt = CGPoint(x: newFrame.midX, y: newFrame.midY)
            if let sc = self?.findScreen(for: centerPt) ?? NSScreen.main {
                newFrame.origin.x = max(sc.visibleFrame.minX + 16, min(sc.visibleFrame.maxX - newFrame.width - 16, newFrame.origin.x))
                newFrame.origin.y = max(sc.visibleFrame.minY + 16, min(sc.visibleFrame.maxY - newFrame.height - 16, newFrame.origin.y))
            }

            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.22
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(newFrame, display: true)
            }
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignTokens.Animation.appearDuration
            panel.animator().alphaValue = 1.0
        }

        self.panel = panel
    }

    func dismiss() {
        guard let currentPanel = panel else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = DesignTokens.Animation.disappearDuration
            currentPanel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                if self?.panel === currentPanel {
                    self?.panel?.orderOut(nil)
                    self?.panel = nil
                    self?.hostingView = nil
                } else {
                    currentPanel.orderOut(nil)
                }
            }
        }
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    private func findScreen(for point: CGPoint) -> NSScreen? {
        return NSScreen.screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main
    }
}

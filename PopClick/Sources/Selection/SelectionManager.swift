import AppKit

/// Orchestrates text selection detection via global event monitoring + Accessibility API
final class SelectionManager {
    private let accessibilityManager = AccessibilityManager()
    private let eventManager = EventManager()

    var onSelection: ((TextSelection) -> Void)?
    var onDeselect: (() -> Void)?

    private var debounceWorkItem: DispatchWorkItem?
    private var lastSelectedText: String = ""
    private var mouseDownPoint: CGPoint = .zero

    init(onSelection: @escaping (TextSelection) -> Void, onDeselect: (() -> Void)? = nil) {
        self.onSelection = onSelection
        self.onDeselect = onDeselect
    }

    func startMonitoring() {
        eventManager.onMouseDown = { [weak self] point, _ in
            self?.mouseDownPoint = point
        }

        eventManager.onMouseUp = { [weak self] upPoint, clickCount in
            self?.handleMouseUp(at: upPoint, clickCount: clickCount)
        }

        eventManager.onEscapeKey = { [weak self] in
            self?.resetLastSelection()
            self?.onDeselect?()
        }

        eventManager.startMonitoring()
    }

    func stopMonitoring() {
        eventManager.stopMonitoring()
        debounceWorkItem?.cancel()
    }

    /// Reset so the same text can trigger again
    func resetLastSelection() {
        lastSelectedText = ""
    }

    // MARK: - Private

    private func handleMouseUp(at mouseLocation: CGPoint, clickCount: Int) {
        let dragDistance = hypot(mouseLocation.x - mouseDownPoint.x, mouseLocation.y - mouseDownPoint.y)

        // Single click without drag means deselect / dismiss
        if dragDistance < 4 && clickCount <= 1 {
            resetLastSelection()
            onDeselect?()
            return
        }

        // Debounce rapid events
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.checkForSelection(mouseLocation: mouseLocation)
        }
        debounceWorkItem = workItem

        let delay = UserDefaults.standard.object(forKey: "selectionDelay") as? Double ?? 0.15
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func checkForSelection(mouseLocation: CGPoint) {
        guard let text = accessibilityManager.getSelectedText(),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            resetLastSelection()
            return
        }

        // Avoid duplicate triggers for the same selection
        guard text != lastSelectedText else { return }
        lastSelectedText = text

        // Get bounds or use mouse location
        let bounds = accessibilityManager.getSelectionBounds() ?? CGRect(
            x: mouseLocation.x - 50,
            y: mouseLocation.y - 10,
            width: 100,
            height: 20
        )

        let codeContext = accessibilityManager.extractCodeContext(for: text)
        let contentType = TextSelection.detectContentType(text, context: codeContext)
        let selection = TextSelection(
            text: text,
            bounds: bounds,
            mouseLocation: mouseLocation,
            contentType: contentType,
            codeContext: codeContext
        )

        onSelection?(selection)
    }
}

import Foundation
import AppKit

/// Monitors global keyboard and mouse events
final class EventManager {
    private var globalMouseUpMonitor: Any?
    private var globalMouseDownMonitor: Any?
    private var globalKeyMonitor: Any?

    var onMouseUp: ((CGPoint, Int) -> Void)?    // (screenPoint, clickCount)
    var onMouseDown: ((CGPoint, Int) -> Void)?  // (screenPoint, clickCount)
    var onEscapeKey: (() -> Void)?

    func startMonitoring() {
        // Monitor global mouse-up events
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseUp]
        ) { [weak self] event in
            let screenPoint = NSEvent.mouseLocation
            self?.onMouseUp?(screenPoint, event.clickCount)
        }

        // Monitor global mouse-down events
        globalMouseDownMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            let screenPoint = NSEvent.mouseLocation
            self?.onMouseDown?(screenPoint, event.clickCount)
        }

        // Monitor key events (Escape)
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown]
        ) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.onEscapeKey?()
            }
        }
    }

    func stopMonitoring() {
        if let monitor = globalMouseUpMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseUpMonitor = nil
        }
        if let monitor = globalMouseDownMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseDownMonitor = nil
        }
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyMonitor = nil
        }
    }

    deinit {
        stopMonitoring()
    }
}

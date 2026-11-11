import AppKit

/// Application entry point
@main
struct PopClickMain {
    // Retain strong reference to delegate to prevent deallocation by AppKit's weak property
    private static var strongDelegate: AppDelegate?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        strongDelegate = delegate
        app.delegate = delegate
        app.run()
    }
}

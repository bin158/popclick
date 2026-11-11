import SwiftUI
import AppKit
import WebKit

// MARK: - KaTeX Resource Locator

public enum KaTeXResourceLocator {
    /// Locates the bundled or local KaTeX & Marked offline resources directory.
    public static func locateKatexDirectory() -> URL? {
        let fm = FileManager.default

        // 1. App Bundle Resources/katex
        if let bundleKatex = Bundle.main.resourceURL?.appendingPathComponent("katex"),
           fm.fileExists(atPath: bundleKatex.appendingPathComponent("template.html").path) {
            return bundleKatex
        }

        // 2. Relative to main bundle Contents/Resources/katex
        let bundleResources = Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/katex")
        if fm.fileExists(atPath: bundleResources.appendingPathComponent("template.html").path) {
            return bundleResources
        }

        // 3. Known project directory fallback for development
        let devPath = URL(fileURLWithPath: "/Users/binye/Documents/01_Projects/popclick/PopClick/Resources/katex")
        if fm.fileExists(atPath: devPath.appendingPathComponent("template.html").path) {
            return devPath
        }

        return nil
    }
}

// MARK: - Auto-Sizing Native Web View

public final class AutoSizingWebView: WKWebView {
    public var contentHeight: CGFloat = 36 {
        didSet {
            if abs(oldValue - contentHeight) > 0.5 {
                heightConstraint?.constant = contentHeight
                invalidateIntrinsicContentSize()
            }
        }
    }

    private var heightConstraint: NSLayoutConstraint?

    public override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        setValue(false, forKey: "drawsBackground")
        if #available(macOS 12.0, *) {
            underPageBackgroundColor = .clear
        }

        translatesAutoresizingMaskIntoConstraints = false
        let constraint = heightAnchor.constraint(equalToConstant: contentHeight)
        constraint.priority = .defaultHigh
        constraint.isActive = true
        self.heightConstraint = constraint

        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    public override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: contentHeight)
    }
}

// MARK: - Web Coordinator

public final class MarkdownWebCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    weak var webView: AutoSizingWebView?
    private var pendingMarkdown: String?
    private var lastRenderedMarkdown: String?
    private var isNavigationFinished: Bool = false

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "heightHandler" {
            if let heightNum = message.body as? NSNumber {
                let h = CGFloat(heightNum.doubleValue)
                if h > 0 {
                    DispatchQueue.main.async { [weak self] in
                        self?.webView?.contentHeight = h
                    }
                }
            }
        } else if message.name == "copyHandler" {
            if let str = message.body as? String {
                ClipboardManager.copy(str)
                DesignTokens.performHapticFeedback()
            }
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isNavigationFinished = true
        if let markdown = pendingMarkdown {
            render(markdown: markdown, in: webView as? AutoSizingWebView)
        }
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    public func render(markdown: String, in targetWebView: AutoSizingWebView?) {
        if let wv = targetWebView {
            self.webView = wv
        }

        guard isNavigationFinished, let webView = self.webView else {
            self.pendingMarkdown = markdown
            return
        }

        if lastRenderedMarkdown == markdown {
            return
        }
        lastRenderedMarkdown = markdown
        pendingMarkdown = nil

        let escaped = (try? String(data: JSONEncoder().encode(markdown), encoding: .utf8)) ?? "\"\""
        let js = "renderMarkdown(\(escaped));"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}

// MARK: - Auto-Sizing Markdown Representable

public struct AutoSizingMarkdownWebView: NSViewRepresentable {
    public let markdown: String

    public init(markdown: String) {
        self.markdown = markdown
    }

    public func makeCoordinator() -> MarkdownWebCoordinator {
        return MarkdownWebCoordinator()
    }

    public func makeNSView(context: Context) -> AutoSizingWebView {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "heightHandler")
        controller.add(context.coordinator, name: "copyHandler")
        config.userContentController = controller

        let webView = AutoSizingWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView

        if let katexDir = KaTeXResourceLocator.locateKatexDirectory() {
            let templateURL = katexDir.appendingPathComponent("template.html")
            webView.loadFileURL(templateURL, allowingReadAccessTo: katexDir)
        }

        return webView
    }

    public func updateNSView(_ nsView: AutoSizingWebView, context: Context) {
        context.coordinator.render(markdown: markdown, in: nsView)
    }

    public static func dismantleNSView(_ nsView: AutoSizingWebView, coordinator: MarkdownWebCoordinator) {
        nsView.configuration.userContentController.removeScriptMessageHandler(forName: "heightHandler")
        nsView.configuration.userContentController.removeScriptMessageHandler(forName: "copyHandler")
        nsView.navigationDelegate = nil
        coordinator.webView = nil
    }
}

// MARK: - MarkdownContentView

/// Production-grade native Markdown + KaTeX LaTeX rich text view
public struct MarkdownContentView: View {
    public let markdown: String

    public init(markdown: String) {
        self.markdown = markdown
    }

    public var body: some View {
        if KaTeXResourceLocator.locateKatexDirectory() != nil {
            AutoSizingMarkdownWebView(markdown: markdown)
        } else {
            Text(markdown)
                .font(DesignTokens.Typography.bodyFont)
                .lineSpacing(3.5)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Legacy Compatibility

public struct LatexFormatter {
    public static func containsMathCommands(_ text: String) -> Bool {
        return text.contains("$") || text.contains("\\")
    }
}

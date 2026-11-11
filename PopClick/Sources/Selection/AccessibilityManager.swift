import AppKit
import ApplicationServices

/// Reads selected text and geometry from any application using the Accessibility API
final class AccessibilityManager {

    /// Attempt to read the currently selected text from the focused application
    func getSelectedText() -> String? {
        if let text = getSelectedTextViaAccessibility(), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }

        // Safe fallback only if selection actually copied
        return getSelectedTextViaClipboard()
    }

    /// Get selected text bounds on screen in Cocoa coordinates (bottom-left origin)
    func getSelectionBounds() -> CGRect? {
        guard let focusedApp = NSWorkspace.shared.frontmostApplication else { return nil }

        let appElement = AXUIElementCreateApplication(focusedApp.processIdentifier)
        var focusedElement: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        guard result == .success, let element = focusedElement as! AXUIElement? else { return nil }

        // Try to get selected text range bounds
        var selectedRangeValue: CFTypeRef?
        let rangeResult = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedRangeValue
        )

        if rangeResult == .success, let rangeValue = selectedRangeValue {
            var boundsValue: CFTypeRef?
            let boundsResult = AXUIElementCopyParameterizedAttributeValue(
                element,
                kAXBoundsForRangeParameterizedAttribute as CFString,
                rangeValue,
                &boundsValue
            )

            if boundsResult == .success, let bounds = boundsValue {
                var rect = CGRect.zero
                if AXValueGetValue(bounds as! AXValue, .cgRect, &rect) {
                    if rect.width > 2 && rect.height > 2 {
                        return convertAXRectToCocoaRect(rect)
                    }
                }
            }
        }

        // Fallback: focused element position and size
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?

        AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
        AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)

        if let posValue = positionValue, let szValue = sizeValue {
            var position = CGPoint.zero
            var size = CGSize.zero
            AXValueGetValue(posValue as! AXValue, .cgPoint, &position)
            AXValueGetValue(szValue as! AXValue, .cgSize, &size)
            if size.width > 10 && size.height > 10 && size.width < 3000 && size.height < 3000 {
                let axRect = CGRect(origin: position, size: size)
                return convertAXRectToCocoaRect(axRect)
            }
        }

        return nil
    }

    /// Converts Accessibility screen coordinates (top-left origin) to Cocoa screen coordinates (bottom-left origin)
    private func convertAXRectToCocoaRect(_ rect: CGRect) -> CGRect {
        guard let primaryScreen = NSScreen.screens.first else { return rect }
        let primaryHeight = primaryScreen.frame.height
        let cocoaY = primaryHeight - (rect.origin.y + rect.size.height)
        return CGRect(x: rect.origin.x, y: cocoaY, width: rect.size.width, height: rect.size.height)
    }

    // MARK: - Private

    private func getSelectedTextViaAccessibility() -> String? {
        guard let focusedApp = NSWorkspace.shared.frontmostApplication else { return nil }

        let appElement = AXUIElementCreateApplication(focusedApp.processIdentifier)
        var focusedElement: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        guard result == .success, let element = focusedElement as! AXUIElement? else { return nil }

        // 1. Direct selected text attribute
        var selectedTextValue: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        )

        if textResult == .success, let text = selectedTextValue as? String, !text.isEmpty {
            return text
        }

        // 2. Selected range + string for range
        var selectedRangeValue: CFTypeRef?
        let rangeResult = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedRangeValue
        )

        if rangeResult == .success, let rangeValue = selectedRangeValue {
            var range = CFRange()
            if AXValueGetValue(rangeValue as! AXValue, .cfRange, &range), range.length > 0 {
                var stringValue: CFTypeRef?
                let stringResult = AXUIElementCopyParameterizedAttributeValue(
                    element,
                    kAXStringForRangeParameterizedAttribute as CFString,
                    rangeValue,
                    &stringValue
                )
                if stringResult == .success, let text = stringValue as? String, !text.isEmpty {
                    return text
                }

                // If element has value attribute, slice substring
                var fullValue: CFTypeRef?
                if AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &fullValue) == .success,
                   let fullString = fullValue as? String {
                    let nsString = fullString as NSString
                    if range.location >= 0 && range.location + range.length <= nsString.length {
                        return nsString.substring(with: NSRange(location: range.location, length: range.length))
                    }
                }
            }
        }

        return nil
    }

    /// Extracts rich contextual code information (application, window title, document URL, surrounding lines)
    public func extractCodeContext(for selectedText: String) -> CodeContext {
        guard let focusedApp = NSWorkspace.shared.frontmostApplication else {
            let detection = CodeDetector.detect(text: selectedText)
            return CodeContext(selectedCode: selectedText, isCode: detection.isCode, detectedLanguage: detection.language)
        }

        let appName = focusedApp.localizedName
        let bundleId = focusedApp.bundleIdentifier

        let appElement = AXUIElementCreateApplication(focusedApp.processIdentifier)
        var focusedWindowValue: CFTypeRef?
        var documentPath: String?
        var fileExtension: String?

        // Check focused window for document URL or file path in title
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindowValue) == .success,
           let windowElement = focusedWindowValue as! AXUIElement? {

            // Try document attribute
            var docValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(windowElement, kAXDocumentAttribute as CFString, &docValue) == .success,
               let docStr = docValue as? String {
                documentPath = docStr
                if let url = URL(string: docStr) {
                    fileExtension = url.pathExtension
                } else {
                    fileExtension = (docStr as NSString).pathExtension
                }
            }

            // Fallback: search window title for file extension (e.g. "MainView.swift - MyApp")
            if fileExtension == nil || fileExtension?.isEmpty == true {
                var titleValue: CFTypeRef?
                if AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &titleValue) == .success,
                   let titleStr = titleValue as? String {
                    let words = titleStr.components(separatedBy: CharacterSet(charactersIn: " —-–()[]\t"))
                    for word in words {
                        let trimmedWord = word.trimmingCharacters(in: .whitespaces)
                        if trimmedWord.contains(".") {
                            let ext = (trimmedWord as NSString).pathExtension.lowercased()
                            if !ext.isEmpty && ext.count <= 6 {
                                fileExtension = ext
                                break
                            }
                        }
                    }
                }
            }
        }

        // Try extracting surrounding code from focused text element
        var focusedElementValue: CFTypeRef?
        var surroundingBefore: String?
        var surroundingAfter: String?
        var fullFile: String?

        if AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElementValue) == .success,
           let element = focusedElementValue as! AXUIElement? {

            var fullValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &fullValue) == .success,
               let fullString = fullValue as? String {
                fullFile = fullString
                let nsString = fullString as NSString

                var rangeValue: CFTypeRef?
                if AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &rangeValue) == .success,
                   let rVal = rangeValue {
                    var range = CFRange()
                    if AXValueGetValue(rVal as! AXValue, .cfRange, &range), range.location >= 0 {
                        // Extract lines before
                        let beforeLength = min(range.location, 1200)
                        let beforeStart = range.location - beforeLength
                        if beforeStart >= 0 {
                            let beforeSub = nsString.substring(with: NSRange(location: beforeStart, length: beforeLength))
                            let beforeLines = beforeSub.components(separatedBy: .newlines)
                            surroundingBefore = beforeLines.suffix(8).joined(separator: "\n")
                        }

                        // Extract lines after
                        let selEnd = range.location + range.length
                        if selEnd <= nsString.length {
                            let afterLength = min(nsString.length - selEnd, 1200)
                            let afterSub = nsString.substring(with: NSRange(location: selEnd, length: afterLength))
                            let afterLines = afterSub.components(separatedBy: .newlines)
                            surroundingAfter = afterLines.prefix(8).joined(separator: "\n")
                        }
                    }
                }
            }
        }

        let detection = CodeDetector.detect(text: selectedText, fileExtension: fileExtension, appName: appName)

        return CodeContext(
            selectedCode: selectedText,
            isCode: detection.isCode,
            surroundingBefore: surroundingBefore,
            surroundingAfter: surroundingAfter,
            fullFileContent: fullFile,
            appName: appName,
            appBundleId: bundleId,
            filePath: documentPath,
            fileExtension: fileExtension,
            detectedLanguage: detection.language,
            contextMode: .selectionOnly
        )
    }

    private func getSelectedTextViaClipboard() -> String? {
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)
        let previousChangeCount = pasteboard.changeCount

        // Simulate Cmd+C with proper modifier keys
        let src = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: 55, keyDown: true)
        let cDown = CGEvent(keyboardEventSource: src, virtualKey: 8, keyDown: true)
        cDown?.flags = .maskCommand
        let cUp = CGEvent(keyboardEventSource: src, virtualKey: 8, keyDown: false)
        cUp?.flags = .maskCommand
        let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: 55, keyDown: false)

        cmdDown?.post(tap: .cgSessionEventTap)
        cDown?.post(tap: .cgSessionEventTap)
        cUp?.post(tap: .cgSessionEventTap)
        cmdUp?.post(tap: .cgSessionEventTap)

        // Wait up to 100ms for pasteboard update
        for _ in 1...5 {
            Thread.sleep(forTimeInterval: 0.02)
            if pasteboard.changeCount != previousChangeCount {
                let newText = pasteboard.string(forType: .string)

                // Restore previous clipboard if there was one
                if let previous = previousContents {
                    pasteboard.clearContents()
                    pasteboard.setString(previous, forType: .string)
                }
                return newText
            }
        }

        // If changeCount did not change, NOTHING was copied!
        return nil
    }
}

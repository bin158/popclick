import AppKit

/// Calculates optimal toolbar position on screen across single or multi-monitor configurations
struct PositionCalculator {

    /// Calculate toolbar position relative to text selection or mouse cursor
    /// - Parameters:
    ///   - selectionBounds: Bounds of the selected text in screen coordinates (bottom-left origin)
    ///   - toolbarSize: Size of the toolbar
    ///   - mouseLocation: Mouse location in screen coordinates (bottom-left origin)
    /// - Returns: Origin point for the toolbar window in Cocoa screen coordinates
    static func calculatePosition(
        for selectionBounds: CGRect,
        toolbarSize: CGSize,
        mouseLocation: CGPoint
    ) -> CGPoint {
        // Has valid selection bounds?
        let hasValidBounds = selectionBounds.width > 2 && selectionBounds.height > 2 && !selectionBounds.isNull && !selectionBounds.isInfinite

        let targetPoint = hasValidBounds
            ? CGPoint(x: selectionBounds.midX, y: selectionBounds.midY)
            : mouseLocation

        // Find the specific display containing the selection or mouse
        let screen = NSScreen.screens.first(where: { $0.frame.contains(targetPoint) })
            ?? NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
            ?? NSScreen.main
            ?? NSScreen.screens.first!

        let screenFrame = screen.visibleFrame
        let offset = DesignTokens.Toolbar.offsetFromSelection

        var x: CGFloat
        var y: CGFloat

        if hasValidBounds {
            // Center horizontally above selection
            x = selectionBounds.midX - toolbarSize.width / 2
            y = selectionBounds.maxY + offset

            // If it exceeds the top of this monitor's visible frame, flip to below selection
            if y + toolbarSize.height > screenFrame.maxY {
                y = selectionBounds.minY - toolbarSize.height - offset
            }
        } else {
            // Anchor to mouse location
            x = mouseLocation.x - toolbarSize.width / 2
            y = mouseLocation.y + offset

            if y + toolbarSize.height > screenFrame.maxY {
                y = mouseLocation.y - toolbarSize.height - offset
            }
        }

        // Clamp to current screen's visible frame boundaries
        x = max(screenFrame.minX + 10, min(screenFrame.maxX - toolbarSize.width - 10, x))
        y = max(screenFrame.minY + 10, min(screenFrame.maxY - toolbarSize.height - 10, y))

        return CGPoint(x: x, y: y)
    }
}

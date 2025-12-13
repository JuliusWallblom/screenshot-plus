import AppKit
import SwiftUI

struct WindowFactory {
    let defaultSize = NSSize(width: 800, height: 600)

    @MainActor
    func createAnnotationWindow(windowState: AnnotationWindowState, canvasState: CanvasState) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false

        let contentView = AnnotationContentView(state: windowState, canvasState: canvasState)
        window.contentView = NSHostingView(rootView: contentView)

        let toolbar = NSToolbar(identifier: "AnnotationToolbar")
        let toolbarController = ToolbarController(canvasState: canvasState, windowState: windowState)
        toolbar.delegate = toolbarController
        toolbarController.setToolbar(toolbar)
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        window.titleVisibility = .hidden

        window.title = windowState.imageURL.lastPathComponent
        window.center()

        return window
    }
}

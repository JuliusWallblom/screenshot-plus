import Testing
import AppKit
@testable import Screenshot_

@Suite("ToolbarController Tests")
struct ToolbarControllerTests {
    @Test("ToolbarController provides default toolbar item identifiers")
    func providesDefaultToolbarItemIdentifiers() {
        let canvasState = CanvasState()
        let windowState = AnnotationWindowState(imageURL: URL(fileURLWithPath: "/tmp/test.png"))
        let controller = ToolbarController(canvasState: canvasState, windowState: windowState)

        let toolbar = NSToolbar(identifier: "TestToolbar")
        let identifiers = controller.toolbarDefaultItemIdentifiers(toolbar)

        #expect(!identifiers.isEmpty)
    }

    @Test("ToolbarController syncs selectedIndex when currentTool changes")
    func syncToolbarWhenCurrentToolChanges() async {
        let canvasState = CanvasState()
        canvasState.currentTool = .rectangle
        let windowState = AnnotationWindowState(imageURL: URL(fileURLWithPath: "/tmp/test.png"))
        let controller = ToolbarController(canvasState: canvasState, windowState: windowState)

        let toolbar = NSToolbar(identifier: "TestToolbar")
        toolbar.delegate = controller
        controller.setToolbar(toolbar)

        // Force toolbar to create items
        _ = controller.toolbar(toolbar, itemForItemIdentifier: .init("toolsGroup"), willBeInsertedIntoToolbar: true)

        // Verify initial state
        #expect(controller.currentToolsGroupIndex == 1) // rectangle is at index 1

        // Change currentTool programmatically
        canvasState.currentTool = .oval

        // Wait for main queue to process the Combine update
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Toolbar should sync
        #expect(controller.currentToolsGroupIndex == 2) // oval is at index 2
    }

    @Test("Changing tool via toolbar clears annotation selection")
    func changingToolViaToolbarClearsSelection() {
        let canvasState = CanvasState()
        canvasState.currentTool = .rectangle
        let windowState = AnnotationWindowState(imageURL: URL(fileURLWithPath: "/tmp/test.png"))
        let controller = ToolbarController(canvasState: canvasState, windowState: windowState)

        // Add an annotation and select it
        let annotation = Annotation(
            type: .rectangle,
            startPoint: .zero,
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .red,
            strokeWidth: 2
        )
        canvasState.annotations.append(annotation)
        canvasState.selectedAnnotationIds = [annotation.id]

        // Verify annotation is selected
        #expect(canvasState.selectedAnnotationIds.count == 1)

        // Simulate user clicking a different tool in the toolbar
        controller.selectTool(.oval)

        // Selection should be cleared
        #expect(canvasState.selectedAnnotationIds.isEmpty)
    }
}

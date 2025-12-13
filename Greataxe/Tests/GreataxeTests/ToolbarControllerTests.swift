import Testing
import AppKit
@testable import Greataxe

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
}

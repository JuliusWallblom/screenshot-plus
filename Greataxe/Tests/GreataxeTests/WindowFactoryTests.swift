import Testing
import AppKit
@testable import Preview_

@Suite("WindowFactory Tests")
struct WindowFactoryTests {
    @Test("WindowFactory can be instantiated")
    func canBeInstantiated() {
        let factory = WindowFactory()
        #expect(factory.defaultSize.width == 800)
        #expect(factory.defaultSize.height == 600)
    }

    @Test("WindowFactory result contains toolbarController for retention")
    @MainActor
    func resultContainsToolbarController() throws {
        let factory = WindowFactory()
        let tempURL = URL(fileURLWithPath: "/tmp/test.png")
        let windowState = AnnotationWindowState(imageURL: tempURL)
        let canvasState = CanvasState()

        let result = factory.createAnnotationWindow(windowState: windowState, canvasState: canvasState)

        // Verify toolbarController is returned and assigned as delegate
        // Caller must retain result.toolbarController (NSToolbar.delegate is weak)
        #expect(result.window.toolbar?.delegate === result.toolbarController)
    }
}

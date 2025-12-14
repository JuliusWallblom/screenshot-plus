import Testing
import SwiftUI
@testable import Screenshot_

@Suite("Annotation View Integration Tests")
struct AnnotationViewIntegrationTests {
    @Test("AnnotationView has CanvasState for managing tools")
    func annotationViewHasCanvasState() {
        let testURL = URL(fileURLWithPath: "/tmp/test.png")
        let windowState = AnnotationWindowState(imageURL: testURL)
        let view = AnnotationView(state: windowState)

        // Verify canvasState exists and has a valid tool
        let validTools: [DrawingTool] = [.select, .rectangle, .oval, .line, .arrow, .pen, .text, .crop]
        #expect(validTools.contains(view.canvasState.currentTool))
    }
}

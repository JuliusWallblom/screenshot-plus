import Testing
import SwiftUI
@testable import Preview_

@Suite("Annotation View Integration Tests")
struct AnnotationViewIntegrationTests {
    @Test("AnnotationView has CanvasState for managing tools")
    func annotationViewHasCanvasState() {
        let testURL = URL(fileURLWithPath: "/tmp/test.png")
        let windowState = AnnotationWindowState(imageURL: testURL)
        let view = AnnotationView(state: windowState)

        #expect(view.canvasState != nil)
    }
}

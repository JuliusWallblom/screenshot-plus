import Testing
import SwiftUI
@testable import Greataxe

@Suite("Annotation Canvas Tests")
struct AnnotationCanvasTests {
    @Test("Annotation model stores shape properties")
    func annotationModelStoresShapeProperties() {
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 10, y: 20),
            endPoint: CGPoint(x: 100, y: 80),
            strokeColor: .red,
            strokeWidth: 2.0
        )

        #expect(annotation.type == .rectangle)
        #expect(annotation.startPoint == CGPoint(x: 10, y: 20))
        #expect(annotation.endPoint == CGPoint(x: 100, y: 80))
        #expect(annotation.strokeColor == .red)
        #expect(annotation.strokeWidth == 2.0)
    }

    @Test("Annotation computes bounding rect correctly")
    func annotationComputesBoundingRect() {
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 100, y: 50),
            endPoint: CGPoint(x: 50, y: 100),
            strokeColor: .blue,
            strokeWidth: 1.0
        )

        let rect = annotation.boundingRect

        #expect(rect.origin.x == 50)
        #expect(rect.origin.y == 50)
        #expect(rect.width == 50)
        #expect(rect.height == 50)
    }

    @Test("CanvasState tracks current tool")
    func canvasStateTracksCurrentTool() {
        let canvasState = CanvasState()

        #expect(canvasState.currentTool == .rectangle)

        canvasState.currentTool = .arrow
        #expect(canvasState.currentTool == .arrow)
    }

    @Test("CanvasState stores annotations")
    func canvasStateStoresAnnotations() {
        let canvasState = CanvasState()

        #expect(canvasState.annotations.isEmpty)

        let annotation = Annotation(
            type: .line,
            startPoint: .zero,
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .green,
            strokeWidth: 3.0
        )

        canvasState.annotations.append(annotation)
        #expect(canvasState.annotations.count == 1)
    }
}

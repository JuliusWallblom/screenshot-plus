import Testing
import AppKit
@testable import Screenshot_

@Suite("GestureHandler Tests")
struct GestureHandlerTests {
    @Test("GestureHandler can determine drawing mode for empty canvas")
    func determineDrawingModeForEmptyCanvas() {
        let canvasState = CanvasState()
        canvasState.currentTool = .rectangle
        let handler = GestureHandler(canvasState: canvasState)

        let tapLocation = CGPoint(x: 100, y: 100)
        let mode = handler.determineDragMode(at: tapLocation, annotations: [], selectedIds: [])

        #expect(mode == .drawing)
    }

    @Test("GestureHandler can determine select mode for select tool on empty canvas")
    func determineSelectModeForSelectTool() {
        let canvasState = CanvasState()
        canvasState.currentTool = .select
        let handler = GestureHandler(canvasState: canvasState)

        let tapLocation = CGPoint(x: 100, y: 100)
        let mode = handler.determineDragMode(at: tapLocation, annotations: [], selectedIds: [])

        #expect(mode == .marquee)
    }

    @Test("GestureHandler determines moving mode when clicking selected annotation")
    func determineMovingModeForSelectedAnnotation() {
        let canvasState = CanvasState()
        canvasState.currentTool = .rectangle
        let coordinateSpace = CoordinateSpace(imageSize: CGSize(width: 800, height: 600), screenRect: CGRect(x: 0, y: 0, width: 800, height: 600))
        let hitTestService = HitTestService()
        let handler = GestureHandler(canvasState: canvasState, hitTestService: hitTestService, coordinateSpace: coordinateSpace)

        // Create annotation at (100, 100) to (200, 200)
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 100, y: 100),
            endPoint: CGPoint(x: 200, y: 200),
            strokeColor: .red,
            strokeWidth: 2
        )

        // Tap in middle of annotation
        let tapLocation = CGPoint(x: 150, y: 150)
        let mode = handler.determineDragMode(at: tapLocation, annotations: [annotation], selectedIds: [annotation.id])

        #expect(mode == .moving)
    }

    @Test("GestureHandler determines resizing mode when clicking handle of selected annotation")
    func determineResizingModeForHandle() {
        let canvasState = CanvasState()
        canvasState.currentTool = .rectangle
        let coordinateSpace = CoordinateSpace(imageSize: CGSize(width: 800, height: 600), screenRect: CGRect(x: 0, y: 0, width: 800, height: 600))
        let hitTestService = HitTestService()
        let handler = GestureHandler(canvasState: canvasState, hitTestService: hitTestService, coordinateSpace: coordinateSpace)

        // Create annotation at (100, 100) to (200, 200)
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 100, y: 100),
            endPoint: CGPoint(x: 200, y: 200),
            strokeColor: .red,
            strokeWidth: 2
        )

        // Tap on bottom-right corner handle
        let tapLocation = CGPoint(x: 200, y: 200)
        let mode = handler.determineDragMode(at: tapLocation, annotations: [annotation], selectedIds: [annotation.id])

        if case .resizing(let handle) = mode {
            #expect(handle == .bottomRight)
        } else {
            Issue.record("Expected resizing mode but got \(mode)")
        }
    }
}

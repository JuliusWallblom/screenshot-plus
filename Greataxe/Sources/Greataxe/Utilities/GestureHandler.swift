import AppKit

/// Handles gesture processing for the drawing canvas.
/// Determines drag mode based on tap location and current state.
struct GestureHandler {
    let canvasState: CanvasState
    var hitTestService: HitTestService?
    var coordinateSpace: CoordinateSpace?

    init(canvasState: CanvasState, hitTestService: HitTestService? = nil, coordinateSpace: CoordinateSpace? = nil) {
        self.canvasState = canvasState
        self.hitTestService = hitTestService
        self.coordinateSpace = coordinateSpace
    }

    /// Determines the appropriate drag mode for a tap at the given location.
    func determineDragMode(
        at location: CGPoint,
        annotations: [Annotation],
        selectedIds: Set<UUID>
    ) -> CanvasDragMode {
        if let hitTestService = hitTestService, let coordinateSpace = coordinateSpace {
            // For single selection, check resize handles first
            let selectedAnnotations = annotations.filter { selectedIds.contains($0.id) }
            if selectedAnnotations.count == 1, let selected = selectedAnnotations.first {
                if let handle = hitTestService.hitTestHandle(screenPoint: location, annotation: selected, coordinateSpace: coordinateSpace) {
                    return .resizing(handle)
                }
            }

            // Check if clicking on a selected annotation to move it
            if let annotation = hitTestService.hitTestAnnotation(screenPoint: location, annotations: annotations, coordinateSpace: coordinateSpace),
               selectedIds.contains(annotation.id) {
                return .moving
            }
        }

        // Select tool: start marquee selection
        if canvasState.currentTool == .select {
            return .marquee
        }

        // Text tool: handled separately (in onEnded)
        if canvasState.currentTool == .text {
            return .none
        }

        // Start drawing new annotation
        return .drawing
    }
}

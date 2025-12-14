import SwiftUI
import AppKit

enum CanvasDragMode: Equatable {
    case none
    case drawing
    case moving
    case resizing(HandlePosition)
    case rotating
    case marquee
}

// HandlePosition is defined in HitTestService.swift

struct DrawingCanvasView: View {
    @ObservedObject var canvasState: CanvasState
    let imageRect: CGRect
    // Text editing state
    @State private var editingAnnotationId: UUID? = nil
    @State private var editingOriginalText: String? = nil
    @State private var isCreatingNewText = false
    @State private var newTextAnnotation: Annotation? = nil
    @State private var textInputPosition: CGPoint = .zero
    // Drag state
    @State private var dragMode: CanvasDragMode = .none
    @State private var dragStartPoint: CGPoint = .zero
    @State private var originalAnnotation: Annotation?
    @State private var currentCursor: NSCursor = .arrow
    @State private var didRotate: Bool = false
    @State private var keyMonitor: Any?
    @State private var marqueeStart: CGPoint = .zero
    @State private var marqueeEnd: CGPoint = .zero
    @State private var currentSize: CGSize = .zero
    @State private var currentRotationDegrees: Double = 0
    @State private var wasAlreadySelected: Bool = false

    private var coordinateSpace: CoordinateSpace {
        CoordinateSpace(imageSize: canvasState.imageSize, screenRect: imageRect)
    }

    private func screenToImage(_ point: CGPoint) -> CGPoint {
        coordinateSpace.screenToImage(point)
    }

    private func imageToScreen(_ point: CGPoint) -> CGPoint {
        coordinateSpace.imageToScreen(point)
    }

    private var displayScale: CGFloat {
        coordinateSpace.scale
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Canvas { context, size in
                    // Draw non-text annotations only
                    for annotation in canvasState.annotations where annotation.type != .text {
                        drawAnnotation(annotation, in: &context)
                    }
                    if let current = canvasState.currentAnnotation, current.type != .text {
                        drawAnnotation(current, in: &context)
                    }
                    // Draw selection handles for all selected
                    for annotation in canvasState.selectedAnnotations {
                        drawSelectionHandles(for: annotation, in: &context)
                    }
                    // Draw marquee selection rectangle
                    if case .marquee = dragMode {
                        let rect = CGRect(
                            x: min(marqueeStart.x, marqueeEnd.x),
                            y: min(marqueeStart.y, marqueeEnd.y),
                            width: abs(marqueeEnd.x - marqueeStart.x),
                            height: abs(marqueeEnd.y - marqueeStart.y)
                        )
                        context.stroke(
                            Path(rect),
                            with: .color(.blue.opacity(0.8)),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                        )
                        context.fill(
                            Path(rect),
                            with: .color(.blue.opacity(0.1))
                        )
                    }

                    // Draw size info box during resize
                    if case .resizing = dragMode, let selected = canvasState.selectedAnnotation {
                        let screenRect = annotationScreenBounds(selected)
                        let text = Text("\(Int(currentSize.width)) × \(Int(currentSize.height))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                        let position = CGPoint(x: screenRect.midX, y: screenRect.maxY + 20)

                        // Background pill
                        let bgRect = CGRect(x: position.x - 40, y: position.y - 10, width: 80, height: 20)
                        context.fill(Path(roundedRect: bgRect, cornerRadius: 4), with: .color(.black.opacity(0.75)))
                        context.draw(text, at: position)
                    }

                    // Draw rotation info box only when actually rotating
                    if case .rotating = dragMode, didRotate, let selected = canvasState.selectedAnnotation {
                        let screenRect = annotationScreenBounds(selected)
                        let text = Text("\(Int(round(currentRotationDegrees)))°")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                        let position = CGPoint(x: screenRect.midX, y: screenRect.maxY + 20)

                        // Background pill
                        let bgRect = CGRect(x: position.x - 25, y: position.y - 10, width: 50, height: 20)
                        context.fill(Path(roundedRect: bgRect, cornerRadius: 4), with: .color(.black.opacity(0.75)))
                        context.draw(text, at: position)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDragChanged(value, in: geometry.size)
                        }
                        .onEnded { value in
                            handleDragEnded(value)
                        }
                )
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        updateCursor(at: location)
                    case .ended:
                        NSCursor.arrow.set()
                    }
                }

                // Render ALL text annotations as actual views (same component for display AND edit)
                ForEach(canvasState.annotations.filter { $0.type == .text }) { annotation in
                    TextAnnotationView(
                        annotation: annotation,
                        isEditing: editingAnnotationId == annotation.id,
                        displayScale: displayScale,
                        screenPosition: imageToScreen(annotation.startPoint),
                        onTextChange: { newText in
                            if let idx = canvasState.annotations.firstIndex(where: { $0.id == annotation.id }) {
                                canvasState.annotations[idx].text = newText
                            }
                        },
                        onCommit: {
                            editingAnnotationId = nil
                        },
                        onCancel: {
                            // Restore original text if we saved it
                            if let original = editingOriginalText {
                                if let idx = canvasState.annotations.firstIndex(where: { $0.id == annotation.id }) {
                                    canvasState.annotations[idx].text = original
                                }
                            }
                            editingAnnotationId = nil
                            editingOriginalText = nil
                        }
                    )
                }

                // New text being created
                if isCreatingNewText {
                    TextAnnotationView(
                        annotation: newTextAnnotation!,
                        isEditing: true,
                        displayScale: displayScale,
                        screenPosition: textInputPosition,
                        onTextChange: { newText in
                            newTextAnnotation?.text = newText
                        },
                        onCommit: {
                            if let annotation = newTextAnnotation, !annotation.text.isEmpty {
                                canvasState.saveState()
                                canvasState.annotations.append(annotation)
                                canvasState.selectedAnnotationIds = [annotation.id]
                                NSApp.keyWindow?.toolbar?.validateVisibleItems()
                            }
                            isCreatingNewText = false
                            newTextAnnotation = nil
                        },
                        onCancel: {
                            isCreatingNewText = false
                            newTextAnnotation = nil
                        }
                    )
                }
            }
        }
        .onAppear {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // Check if a text field or text view has focus - if so, don't intercept
                if let firstResponder = NSApp.keyWindow?.firstResponder,
                   firstResponder is NSTextView || firstResponder is NSTextField {
                    return event
                }

                if event.keyCode == 51 || event.keyCode == 117 { // 51 = backspace, 117 = forward delete
                    if !canvasState.selectedAnnotationIds.isEmpty {
                        deleteSelectedAnnotation()
                        return nil // Consume the event
                    }
                }
                // Enter/Return = deselect
                if event.keyCode == 36 || event.keyCode == 76 { // 36 = return, 76 = enter (numpad)
                    if !canvasState.selectedAnnotationIds.isEmpty {
                        canvasState.selectedAnnotationIds.removeAll()
                        return nil
                    }
                }
                // Cmd+Z = undo, Cmd+Shift+Z = redo
                if event.keyCode == 6 && event.modifierFlags.contains(.command) {
                    if event.modifierFlags.contains(.shift) {
                        canvasState.redo()
                    } else {
                        canvasState.undo()
                    }
                    NSApp.keyWindow?.toolbar?.validateVisibleItems()
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = keyMonitor {
                NSEvent.removeMonitor(monitor)
                keyMonitor = nil
            }
        }
    }

    private func handleDragChanged(_ value: DragGesture.Value, in size: CGSize) {
        let screenLocation = value.location
        let screenStart = value.startLocation
        let imageLocation = screenToImage(screenLocation)
        let imageStart = screenToImage(screenStart)

        // If currently editing text and click happens outside, commit the edit
        if (editingAnnotationId != nil || isCreatingNewText) && dragMode == .none {
            // Check if clicking on the text being edited - if so, don't commit
            if let editingId = editingAnnotationId,
               let annotation = canvasState.annotations.first(where: { $0.id == editingId }) {
                let screenRect = annotationScreenBounds(annotation)
                if !screenRect.contains(screenStart) {
                    editingAnnotationId = nil
                    editingOriginalText = nil
                }
            } else if isCreatingNewText {
                // Commit new text
                if let annotation = newTextAnnotation, !annotation.text.isEmpty {
                    canvasState.saveState()
                    canvasState.annotations.append(annotation)
                    canvasState.selectedAnnotationIds = [annotation.id]
                    NSApp.keyWindow?.toolbar?.validateVisibleItems()
                }
                isCreatingNewText = false
                newTextAnnotation = nil
            }
        }

        // If starting a new drag
        if case .none = dragMode {
            dragStartPoint = imageStart

            // If something is selected (single selection), handle resize/rotate
            if let selected = canvasState.selectedAnnotation {
                // Check if clicking on a resize handle
                if let handle = hitTestHandle(screenPoint: screenStart, annotation: selected) {
                    canvasState.saveState()
                    dragMode = .resizing(handle)
                    originalAnnotation = selected
                    currentSize = selected.boundingRect.size
                    return
                }
            }

            // Check if clicking on any selected annotation to move
            if let annotation = hitTestAnnotation(screenPoint: screenStart),
               canvasState.isSelected(annotation) {
                canvasState.saveState()
                dragMode = .moving
                originalAnnotation = annotation
                wasAlreadySelected = true
                return
            }

            // Check if clicking on an unselected annotation to select it (any tool)
            if let annotation = hitTestAnnotation(screenPoint: screenStart) {
                canvasState.selectAnnotation(annotation)
                canvasState.saveState()
                dragMode = .moving
                originalAnnotation = annotation
                wasAlreadySelected = false
                return
            }

            // Clicking on empty space
            if !canvasState.selectedAnnotationIds.isEmpty {
                // If single item selected, allow rotation
                if let selected = canvasState.selectedAnnotation {
                    canvasState.saveState()
                    dragMode = .rotating
                    originalAnnotation = selected
                    didRotate = false
                    // Initialize rotation display
                    var degrees = selected.rotation * 180 / .pi
                    degrees = degrees.truncatingRemainder(dividingBy: 360)
                    if degrees < 0 { degrees += 360 }
                    currentRotationDegrees = degrees
                    return
                } else {
                    // Multiple items selected - deselect
                    canvasState.selectedAnnotationIds.removeAll()
                }
            }

            // Select tool: start marquee selection
            if canvasState.currentTool == .select {
                dragMode = .marquee
                marqueeStart = screenStart
                marqueeEnd = screenStart
                return
            }

            if canvasState.currentTool == .text {
                return // Text handled in onEnded
            }

            // Start drawing new annotation (in image coords)
            dragMode = .drawing
            canvasState.currentAnnotation = Annotation(
                type: annotationType(for: canvasState.currentTool),
                startPoint: imageStart,
                endPoint: imageLocation,
                strokeColor: canvasState.strokeColor,
                strokeWidth: canvasState.strokeWidth,
                isFilled: canvasState.fillShapes
            )
            return
        }

        // Continue existing drag
        switch dragMode {
        case .drawing:
            let shiftHeld = NSEvent.modifierFlags.contains(.shift)
            if shiftHeld && (canvasState.currentTool == .rectangle || canvasState.currentTool == .oval) {
                // Constrain to square/circle when shift is held
                let start = canvasState.currentAnnotation?.startPoint ?? imageStart
                let dx = imageLocation.x - start.x
                let dy = imageLocation.y - start.y
                let size = max(abs(dx), abs(dy))
                canvasState.currentAnnotation?.endPoint = CGPoint(
                    x: start.x + (dx >= 0 ? size : -size),
                    y: start.y + (dy >= 0 ? size : -size)
                )
            } else {
                canvasState.currentAnnotation?.endPoint = imageLocation
            }
            if canvasState.currentTool == .pen || canvasState.currentTool == .arrow {
                canvasState.currentAnnotation?.points.append(imageLocation)
            }

        case .moving:
            let delta = CGPoint(x: imageLocation.x - dragStartPoint.x, y: imageLocation.y - dragStartPoint.y)
            if let original = originalAnnotation {
                canvasState.updateSelectedAnnotations { annotation in
                    annotation.startPoint = CGPoint(x: original.startPoint.x + delta.x, y: original.startPoint.y + delta.y)
                    annotation.endPoint = CGPoint(x: original.endPoint.x + delta.x, y: original.endPoint.y + delta.y)
                    if !original.points.isEmpty {
                        annotation.points = original.points.map { CGPoint(x: $0.x + delta.x, y: $0.y + delta.y) }
                    }
                }
            }

        case .resizing(let handle):
            if let original = originalAnnotation {
                canvasState.updateSelectedAnnotations { annotation in
                    if annotation.type == .text && annotation.textBackgroundColor != nil {
                        // For text with background, resize by adjusting padding from the dragged corner
                        let originalRect = original.boundingRect

                        var newPaddingTop = original.textBackgroundPaddingTop
                        var newPaddingRight = original.textBackgroundPaddingRight
                        var newPaddingBottom = original.textBackgroundPaddingBottom
                        var newPaddingLeft = original.textBackgroundPaddingLeft

                        switch handle {
                        case .bottomRight:
                            // Adjust right and bottom padding
                            let deltaRight = imageLocation.x - originalRect.maxX
                            let deltaBottom = imageLocation.y - originalRect.maxY
                            newPaddingRight = max(0, min(50, original.textBackgroundPaddingRight + deltaRight))
                            newPaddingBottom = max(0, min(50, original.textBackgroundPaddingBottom + deltaBottom))
                        case .bottomLeft:
                            // Adjust left and bottom padding
                            let deltaLeft = originalRect.minX - imageLocation.x
                            let deltaBottom = imageLocation.y - originalRect.maxY
                            newPaddingLeft = max(0, min(50, original.textBackgroundPaddingLeft + deltaLeft))
                            newPaddingBottom = max(0, min(50, original.textBackgroundPaddingBottom + deltaBottom))
                        case .topRight:
                            // Adjust right and top padding
                            let deltaRight = imageLocation.x - originalRect.maxX
                            let deltaTop = originalRect.minY - imageLocation.y
                            newPaddingRight = max(0, min(50, original.textBackgroundPaddingRight + deltaRight))
                            newPaddingTop = max(0, min(50, original.textBackgroundPaddingTop + deltaTop))
                        case .topLeft:
                            // Adjust left and top padding
                            let deltaLeft = originalRect.minX - imageLocation.x
                            let deltaTop = originalRect.minY - imageLocation.y
                            newPaddingLeft = max(0, min(50, original.textBackgroundPaddingLeft + deltaLeft))
                            newPaddingTop = max(0, min(50, original.textBackgroundPaddingTop + deltaTop))
                        }

                        annotation.textBackgroundPaddingTop = newPaddingTop
                        annotation.textBackgroundPaddingRight = newPaddingRight
                        annotation.textBackgroundPaddingBottom = newPaddingBottom
                        annotation.textBackgroundPaddingLeft = newPaddingLeft
                        currentSize = annotation.boundingRect.size

                        // Update canvasState so sliders in popover reflect the change
                        canvasState.textBackgroundPaddingTop = newPaddingTop
                        canvasState.textBackgroundPaddingRight = newPaddingRight
                        canvasState.textBackgroundPaddingBottom = newPaddingBottom
                        canvasState.textBackgroundPaddingLeft = newPaddingLeft
                    } else if annotation.type == .pen {
                        // For pen annotations, scale all points proportionally
                        // Calculate actual bounds from points, without stroke padding
                        let allPoints = [original.startPoint] + original.points
                        let minX = allPoints.map { $0.x }.min() ?? original.startPoint.x
                        let minY = allPoints.map { $0.y }.min() ?? original.startPoint.y
                        let maxX = allPoints.map { $0.x }.max() ?? original.startPoint.x
                        let maxY = allPoints.map { $0.y }.max() ?? original.startPoint.y
                        let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

                        // Calculate stroke padding offset (handles are on padded boundingRect)
                        let strokePadding = original.strokeWidth
                        // Adjust imageLocation to account for the padding offset
                        let adjustedLocation = CGPoint(
                            x: imageLocation.x + (handle == .topLeft || handle == .bottomLeft ? strokePadding : -strokePadding),
                            y: imageLocation.y + (handle == .topLeft || handle == .topRight ? strokePadding : -strokePadding)
                        )

                        var newRect = rect
                        let shiftHeld = NSEvent.modifierFlags.contains(.shift)

                        switch handle {
                        case .topLeft:
                            newRect.origin = adjustedLocation
                            newRect.size.width = rect.maxX - adjustedLocation.x
                            newRect.size.height = rect.maxY - adjustedLocation.y
                        case .topRight:
                            newRect.origin.y = adjustedLocation.y
                            newRect.size.width = adjustedLocation.x - rect.minX
                            newRect.size.height = rect.maxY - adjustedLocation.y
                        case .bottomLeft:
                            newRect.origin.x = adjustedLocation.x
                            newRect.size.width = rect.maxX - adjustedLocation.x
                            newRect.size.height = adjustedLocation.y - rect.minY
                        case .bottomRight:
                            newRect.size.width = adjustedLocation.x - rect.minX
                            newRect.size.height = adjustedLocation.y - rect.minY
                        }

                        // Constrain aspect ratio when shift is held
                        if shiftHeld && rect.width > 0 && rect.height > 0 {
                            var originalAspect = rect.width / rect.height
                            // Snap to 1:1 if very close (handles floating point imprecision from shift-created squares)
                            if abs(originalAspect - 1.0) < 0.02 {
                                originalAspect = 1.0
                            }

                            let size = max(abs(newRect.width), abs(newRect.height))
                            let adjustedWidth = size * (newRect.width < 0 ? -1 : 1)
                            let adjustedHeight = size / originalAspect * (newRect.height < 0 ? -1 : 1)

                            switch handle {
                            case .topLeft:
                                newRect.origin.x = rect.maxX - adjustedWidth
                                newRect.origin.y = rect.maxY - adjustedHeight
                                newRect.size.width = adjustedWidth
                                newRect.size.height = adjustedHeight
                            case .topRight:
                                newRect.origin.y = rect.maxY - adjustedHeight
                                newRect.size.width = adjustedWidth
                                newRect.size.height = adjustedHeight
                            case .bottomLeft:
                                newRect.origin.x = rect.maxX - adjustedWidth
                                newRect.size.width = adjustedWidth
                                newRect.size.height = adjustedHeight
                            case .bottomRight:
                                newRect.size.width = adjustedWidth
                                newRect.size.height = adjustedHeight
                            }
                        }

                        // Calculate scale factors
                        let scaleX = rect.width > 0 ? newRect.width / rect.width : 1
                        let scaleY = rect.height > 0 ? newRect.height / rect.height : 1

                        // Scale startPoint relative to original rect
                        annotation.startPoint = CGPoint(
                            x: newRect.minX + (original.startPoint.x - rect.minX) * scaleX,
                            y: newRect.minY + (original.startPoint.y - rect.minY) * scaleY
                        )

                        // Scale all points in the path
                        annotation.points = original.points.map { point in
                            CGPoint(
                                x: newRect.minX + (point.x - rect.minX) * scaleX,
                                y: newRect.minY + (point.y - rect.minY) * scaleY
                            )
                        }

                        currentSize = CGSize(width: abs(newRect.width), height: abs(newRect.height))
                    } else if annotation.type == .arrow && !original.points.isEmpty {
                        // For arrows, scale start point and all points in the path
                        let end = original.points.last!
                        let relevantPoints = [original.startPoint, end]
                        let minX = relevantPoints.map { $0.x }.min()!
                        let minY = relevantPoints.map { $0.y }.min()!
                        let maxX = relevantPoints.map { $0.x }.max()!
                        let maxY = relevantPoints.map { $0.y }.max()!
                        let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

                        // Calculate padding offset (handles are on padded boundingRect)
                        let strokePadding = max(original.strokeWidth / 2, original.strokeWidth * 4)
                        let adjustedLocation = CGPoint(
                            x: imageLocation.x + (handle == .topLeft || handle == .bottomLeft ? strokePadding : -strokePadding),
                            y: imageLocation.y + (handle == .topLeft || handle == .topRight ? strokePadding : -strokePadding)
                        )

                        var newRect = rect
                        let shiftHeld = NSEvent.modifierFlags.contains(.shift)

                        switch handle {
                        case .topLeft:
                            newRect.origin = adjustedLocation
                            newRect.size.width = rect.maxX - adjustedLocation.x
                            newRect.size.height = rect.maxY - adjustedLocation.y
                        case .topRight:
                            newRect.origin.y = adjustedLocation.y
                            newRect.size.width = adjustedLocation.x - rect.minX
                            newRect.size.height = rect.maxY - adjustedLocation.y
                        case .bottomLeft:
                            newRect.origin.x = adjustedLocation.x
                            newRect.size.width = rect.maxX - adjustedLocation.x
                            newRect.size.height = adjustedLocation.y - rect.minY
                        case .bottomRight:
                            newRect.size.width = adjustedLocation.x - rect.minX
                            newRect.size.height = adjustedLocation.y - rect.minY
                        }

                        // Constrain aspect ratio when shift is held
                        if shiftHeld && rect.width > 0 && rect.height > 0 {
                            var originalAspect = rect.width / rect.height
                            if abs(originalAspect - 1.0) < 0.02 {
                                originalAspect = 1.0
                            }

                            let size = max(abs(newRect.width), abs(newRect.height))
                            let adjustedWidth = size * (newRect.width < 0 ? -1 : 1)
                            let adjustedHeight = size / originalAspect * (newRect.height < 0 ? -1 : 1)

                            switch handle {
                            case .topLeft:
                                newRect.origin.x = rect.maxX - adjustedWidth
                                newRect.origin.y = rect.maxY - adjustedHeight
                                newRect.size.width = adjustedWidth
                                newRect.size.height = adjustedHeight
                            case .topRight:
                                newRect.origin.y = rect.maxY - adjustedHeight
                                newRect.size.width = adjustedWidth
                                newRect.size.height = adjustedHeight
                            case .bottomLeft:
                                newRect.origin.x = rect.maxX - adjustedWidth
                                newRect.size.width = adjustedWidth
                                newRect.size.height = adjustedHeight
                            case .bottomRight:
                                newRect.size.width = adjustedWidth
                                newRect.size.height = adjustedHeight
                            }
                        }

                        // Calculate scale factors
                        let scaleX = rect.width > 0 ? newRect.width / rect.width : 1
                        let scaleY = rect.height > 0 ? newRect.height / rect.height : 1

                        // Scale startPoint
                        annotation.startPoint = CGPoint(
                            x: newRect.minX + (original.startPoint.x - rect.minX) * scaleX,
                            y: newRect.minY + (original.startPoint.y - rect.minY) * scaleY
                        )

                        // Scale all points in the path
                        annotation.points = original.points.map { point in
                            CGPoint(
                                x: newRect.minX + (point.x - rect.minX) * scaleX,
                                y: newRect.minY + (point.y - rect.minY) * scaleY
                            )
                        }

                        currentSize = CGSize(width: abs(newRect.width), height: abs(newRect.height))
                    } else if annotation.type != .text {
                        // For rectangle, oval, line, arrow - use actual shape bounds, not padded boundingRect
                        let minX = min(original.startPoint.x, original.endPoint.x)
                        let minY = min(original.startPoint.y, original.endPoint.y)
                        let maxX = max(original.startPoint.x, original.endPoint.x)
                        let maxY = max(original.startPoint.y, original.endPoint.y)
                        let rect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

                        // Calculate stroke padding offset (handles are on padded boundingRect)
                        let strokePadding = original.isFilled ? 0 : original.strokeWidth
                        // Adjust imageLocation to account for the padding offset
                        let adjustedLocation = CGPoint(
                            x: imageLocation.x + (handle == .topLeft || handle == .bottomLeft ? strokePadding : -strokePadding),
                            y: imageLocation.y + (handle == .topLeft || handle == .topRight ? strokePadding : -strokePadding)
                        )

                        var newRect = rect
                        let shiftHeld = NSEvent.modifierFlags.contains(.shift)

                        switch handle {
                        case .topLeft:
                            newRect.origin = adjustedLocation
                            newRect.size.width = rect.maxX - adjustedLocation.x
                            newRect.size.height = rect.maxY - adjustedLocation.y
                        case .topRight:
                            newRect.origin.y = adjustedLocation.y
                            newRect.size.width = adjustedLocation.x - rect.minX
                            newRect.size.height = rect.maxY - adjustedLocation.y
                        case .bottomLeft:
                            newRect.origin.x = adjustedLocation.x
                            newRect.size.width = rect.maxX - adjustedLocation.x
                            newRect.size.height = adjustedLocation.y - rect.minY
                        case .bottomRight:
                            newRect.size.width = adjustedLocation.x - rect.minX
                            newRect.size.height = adjustedLocation.y - rect.minY
                        }

                        // Constrain aspect ratio when shift is held
                        if shiftHeld && rect.width > 0 && rect.height > 0 {
                            var originalAspect = rect.width / rect.height
                            // Snap to 1:1 if very close (handles floating point imprecision from shift-created squares)
                            if abs(originalAspect - 1.0) < 0.02 {
                                originalAspect = 1.0
                            }

                            let size = max(abs(newRect.width), abs(newRect.height))
                            let adjustedWidth = size * (newRect.width < 0 ? -1 : 1)
                            let adjustedHeight = size / originalAspect * (newRect.height < 0 ? -1 : 1)

                            switch handle {
                            case .topLeft:
                                newRect.origin.x = rect.maxX - adjustedWidth
                                newRect.origin.y = rect.maxY - adjustedHeight
                                newRect.size.width = adjustedWidth
                                newRect.size.height = adjustedHeight
                            case .topRight:
                                newRect.origin.y = rect.maxY - adjustedHeight
                                newRect.size.width = adjustedWidth
                                newRect.size.height = adjustedHeight
                            case .bottomLeft:
                                newRect.origin.x = rect.maxX - adjustedWidth
                                newRect.size.width = adjustedWidth
                                newRect.size.height = adjustedHeight
                            case .bottomRight:
                                newRect.size.width = adjustedWidth
                                newRect.size.height = adjustedHeight
                            }
                        }

                        // For lines, preserve the original direction
                        if annotation.type == .line {
                            // Determine which corners the original start/end were at
                            let startWasAtMinX = original.startPoint.x <= original.endPoint.x
                            let startWasAtMinY = original.startPoint.y <= original.endPoint.y

                            // Assign start/end to preserve the same relative positions
                            annotation.startPoint = CGPoint(
                                x: startWasAtMinX ? newRect.minX : newRect.maxX,
                                y: startWasAtMinY ? newRect.minY : newRect.maxY
                            )
                            annotation.endPoint = CGPoint(
                                x: startWasAtMinX ? newRect.maxX : newRect.minX,
                                y: startWasAtMinY ? newRect.maxY : newRect.minY
                            )
                        } else {
                            annotation.startPoint = newRect.origin
                            annotation.endPoint = CGPoint(x: newRect.maxX, y: newRect.maxY)
                        }
                        currentSize = CGSize(width: abs(newRect.width), height: abs(newRect.height))
                    }
                }
            }

        case .rotating:
            if let original = originalAnnotation {
                let center = CGPoint(
                    x: original.boundingRect.midX,
                    y: original.boundingRect.midY
                )
                let angle = atan2(imageLocation.y - center.y, imageLocation.x - center.x)
                let startAngle = atan2(dragStartPoint.y - center.y, dragStartPoint.x - center.x)
                let deltaAngle = angle - startAngle

                // Only count as rotation if angle changed significantly
                if abs(deltaAngle) > 0.01 {
                    didRotate = true
                }

                let totalRotation = original.rotation + deltaAngle
                // Convert to degrees and normalize to 0-360
                var degrees = totalRotation * 180 / .pi
                degrees = degrees.truncatingRemainder(dividingBy: 360)
                if degrees < 0 { degrees += 360 }
                currentRotationDegrees = degrees

                canvasState.updateSelectedAnnotations { annotation in
                    annotation.rotation = totalRotation
                }
            }

        case .marquee:
            marqueeEnd = screenLocation

        case .none:
            break
        }
    }

    private func deleteSelectedAnnotation() {
        guard !canvasState.selectedAnnotationIds.isEmpty else { return }
        canvasState.saveState()

        // Find the lowest index of selected items for "next best" selection
        let selectedIndices = canvasState.annotations.enumerated()
            .filter { canvasState.selectedAnnotationIds.contains($0.element.id) }
            .map { $0.offset }
        let lowestIndex = selectedIndices.min() ?? 0

        // Remove selected annotations
        canvasState.annotations.removeAll { canvasState.selectedAnnotationIds.contains($0.id) }
        canvasState.selectedAnnotationIds.removeAll()

        // Select next best annotation
        if !canvasState.annotations.isEmpty {
            let nextIndex = min(lowestIndex, canvasState.annotations.count - 1)
            canvasState.selectedAnnotationIds = [canvasState.annotations[nextIndex].id]
        }

        NSApp.keyWindow?.toolbar?.validateVisibleItems()
    }

    private func updateCursor(at location: CGPoint) {
        // Check resize handles if single item is selected
        if let selected = canvasState.selectedAnnotation {
            if hitTestHandle(screenPoint: location, annotation: selected) != nil {
                NSCursor.crosshair.set()
                return
            }
        }

        // Check if over an annotation (for move/select)
        if hitTestAnnotation(screenPoint: location) != nil {
            NSCursor.openHand.set()
            return
        }

        // If single item is selected and cursor is outside, show rotation cursor
        if canvasState.selectedAnnotation != nil {
            NSCursor.closedHand.set()
            return
        }

        // In select mode with nothing selected, show crosshair for marquee
        if canvasState.currentTool == .select {
            NSCursor.crosshair.set()
            return
        }

        NSCursor.arrow.set()
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        // Creating new text annotation
        if canvasState.currentTool == .text && dragMode == .none {
            let imagePoint = screenToImage(value.startLocation)
            textInputPosition = value.startLocation

            var annotation = Annotation(
                type: .text,
                startPoint: imagePoint,
                endPoint: imagePoint,
                strokeColor: canvasState.strokeColor,
                strokeWidth: canvasState.strokeWidth,
                text: "",
                fontSize: canvasState.textFontSize,
                fontName: canvasState.textFontName
            )
            annotation.textBackgroundColor = canvasState.textBackgroundColor
            annotation.textBackgroundPaddingTop = canvasState.textBackgroundPaddingTop
            annotation.textBackgroundPaddingRight = canvasState.textBackgroundPaddingRight
            annotation.textBackgroundPaddingBottom = canvasState.textBackgroundPaddingBottom
            annotation.textBackgroundPaddingLeft = canvasState.textBackgroundPaddingLeft
            annotation.textBackgroundCornerRadius = canvasState.textBackgroundCornerRadius
            annotation.textAlignment = canvasState.textAlignment

            newTextAnnotation = annotation
            isCreatingNewText = true
            return
        }

        if case .drawing = dragMode {
            if var annotation = canvasState.currentAnnotation {
                let imageLocation = screenToImage(value.location)
                let shiftHeld = NSEvent.modifierFlags.contains(.shift)
                if shiftHeld && (canvasState.currentTool == .rectangle || canvasState.currentTool == .oval) {
                    let start = annotation.startPoint
                    let dx = imageLocation.x - start.x
                    let dy = imageLocation.y - start.y
                    let size = max(abs(dx), abs(dy))
                    annotation.endPoint = CGPoint(
                        x: start.x + (dx >= 0 ? size : -size),
                        y: start.y + (dy >= 0 ? size : -size)
                    )
                } else {
                    annotation.endPoint = imageLocation
                }
                canvasState.saveState()
                canvasState.annotations.append(annotation)
                canvasState.selectedAnnotationIds = [annotation.id]
                canvasState.currentAnnotation = nil
                NSApp.keyWindow?.toolbar?.validateVisibleItems()
            }
        }

        // If clicked (not dragged) on an already-selected text annotation, enter edit mode
        if case .moving = dragMode, wasAlreadySelected {
            let distance = hypot(value.location.x - value.startLocation.x, value.location.y - value.startLocation.y)
            if distance < 3, let original = originalAnnotation, original.type == .text {
                // Enter edit mode for this text annotation (don't remove it, just edit in place)
                editingOriginalText = original.text
                editingAnnotationId = original.id
                canvasState.selectedAnnotationIds.removeAll()
            }
        }

        // Deselect if clicked outside without rotating
        if case .rotating = dragMode {
            if !didRotate {
                canvasState.selectedAnnotationIds.removeAll()
            }
        }

        // Complete marquee selection
        if case .marquee = dragMode {
            let marqueeRect = CGRect(
                x: min(marqueeStart.x, marqueeEnd.x),
                y: min(marqueeStart.y, marqueeEnd.y),
                width: abs(marqueeEnd.x - marqueeStart.x),
                height: abs(marqueeEnd.y - marqueeStart.y)
            )

            var selectedIds: Set<UUID> = []
            for annotation in canvasState.annotations {
                let annotationScreenRect = annotationScreenBounds(annotation)
                if marqueeRect.intersects(annotationScreenRect) {
                    selectedIds.insert(annotation.id)
                }
            }
            canvasState.selectedAnnotationIds = selectedIds
        }

        dragMode = .none
        originalAnnotation = nil
        didRotate = false
        wasAlreadySelected = false
    }

    private func annotationScreenBounds(_ annotation: Annotation) -> CGRect {
        let imageRect = annotation.boundingRect
        let screenOrigin = imageToScreen(imageRect.origin)
        return CGRect(
            x: screenOrigin.x,
            y: screenOrigin.y,
            width: imageRect.width * displayScale,
            height: imageRect.height * displayScale
        )
    }

    private func hitTestAnnotation(screenPoint: CGPoint) -> Annotation? {
        // Check in reverse order (top-most first)
        for annotation in canvasState.annotations.reversed() {
            let imageRect = annotation.boundingRect
            let screenRect = CGRect(
                x: imageToScreen(imageRect.origin).x - 10,
                y: imageToScreen(imageRect.origin).y - 10,
                width: imageRect.width * displayScale + 20,
                height: imageRect.height * displayScale + 20
            )
            if screenRect.contains(screenPoint) {
                return annotation
            }
        }
        return nil
    }

    private func hitTestHandle(screenPoint: CGPoint, annotation: Annotation) -> HandlePosition? {
        let imageRect = annotation.boundingRect
        let handleSize: CGFloat = 16
        let center = imageToScreen(CGPoint(x: imageRect.midX, y: imageRect.midY))

        let handles: [(HandlePosition, CGPoint)] = [
            (.topLeft, imageToScreen(CGPoint(x: imageRect.minX, y: imageRect.minY))),
            (.topRight, imageToScreen(CGPoint(x: imageRect.maxX, y: imageRect.minY))),
            (.bottomLeft, imageToScreen(CGPoint(x: imageRect.minX, y: imageRect.maxY))),
            (.bottomRight, imageToScreen(CGPoint(x: imageRect.maxX, y: imageRect.maxY)))
        ]

        for (position, handleCenter) in handles {
            let rotatedHandle = rotatePoint(handleCenter, around: center, by: annotation.rotation)
            let handleRect = CGRect(x: rotatedHandle.x - handleSize/2, y: rotatedHandle.y - handleSize/2, width: handleSize, height: handleSize)
            if handleRect.contains(screenPoint) {
                return position
            }
        }
        return nil
    }

    private func rotatePoint(_ point: CGPoint, around center: CGPoint, by angle: Double) -> CGPoint {
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        let dx = point.x - center.x
        let dy = point.y - center.y
        return CGPoint(
            x: center.x + dx * cosAngle - dy * sinAngle,
            y: center.y + dx * sinAngle + dy * cosAngle
        )
    }

    private func annotationType(for tool: DrawingTool) -> AnnotationType {
        switch tool {
        case .select: return .rectangle
        case .rectangle: return .rectangle
        case .oval: return .oval
        case .line: return .line
        case .arrow: return .arrow
        case .pen: return .pen
        case .text: return .text
        case .crop: return .rectangle
        }
    }

    private func drawAnnotation(_ annotation: Annotation, in context: inout GraphicsContext) {
        // Text annotations are rendered as SwiftUI views, not on the canvas
        guard annotation.type != .text else { return }

        let imageRect = annotation.boundingRect
        let screenCenter = imageToScreen(CGPoint(x: imageRect.midX, y: imageRect.midY))

        var rotatedContext = context
        if annotation.rotation != 0 {
            rotatedContext.translateBy(x: screenCenter.x, y: screenCenter.y)
            rotatedContext.rotate(by: Angle(radians: annotation.rotation))
            rotatedContext.translateBy(x: -screenCenter.x, y: -screenCenter.y)
        }

        if annotation.type == .arrow {
            // Draw arrow line and filled arrowhead separately
            let (linePath, arrowheadPath) = arrowPaths(annotation: annotation, strokeWidth: annotation.strokeWidth * displayScale)
            rotatedContext.stroke(
                linePath,
                with: .color(annotation.strokeColor),
                lineWidth: annotation.strokeWidth * displayScale
            )
            rotatedContext.fill(
                arrowheadPath,
                with: .color(annotation.strokeColor)
            )
        } else {
            let path = pathForAnnotation(annotation)
            if annotation.isFilled && (annotation.type == .rectangle || annotation.type == .oval) {
                rotatedContext.fill(path, with: .color(annotation.strokeColor))
            } else {
                rotatedContext.stroke(
                    path,
                    with: .color(annotation.strokeColor),
                    lineWidth: annotation.strokeWidth * displayScale
                )
            }
        }
    }

    private func drawSelectionHandles(for annotation: Annotation, in context: inout GraphicsContext) {
        let imageRect = annotation.boundingRect
        let screenOrigin = imageToScreen(imageRect.origin)
        let screenRect = CGRect(
            x: screenOrigin.x,
            y: screenOrigin.y,
            width: imageRect.width * displayScale,
            height: imageRect.height * displayScale
        )
        let handleSize: CGFloat = 8
        let center = CGPoint(x: screenRect.midX, y: screenRect.midY)
        let rotation = annotation.rotation

        // Draw rotated selection border
        var borderPath = Path()
        let corners = [
            CGPoint(x: screenRect.minX, y: screenRect.minY),
            CGPoint(x: screenRect.maxX, y: screenRect.minY),
            CGPoint(x: screenRect.maxX, y: screenRect.maxY),
            CGPoint(x: screenRect.minX, y: screenRect.maxY)
        ].map { rotatePoint($0, around: center, by: rotation) }

        borderPath.move(to: corners[0])
        for i in 1..<corners.count {
            borderPath.addLine(to: corners[i])
        }
        borderPath.closeSubpath()

        context.stroke(
            borderPath,
            with: .color(.blue.opacity(0.5)),
            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
        )

        // Draw corner handles
        let handles = [
            CGPoint(x: screenRect.minX, y: screenRect.minY),
            CGPoint(x: screenRect.maxX, y: screenRect.minY),
            CGPoint(x: screenRect.minX, y: screenRect.maxY),
            CGPoint(x: screenRect.maxX, y: screenRect.maxY)
        ]

        for handlePoint in handles {
            let rotatedPoint = rotatePoint(handlePoint, around: center, by: rotation)
            let handleRect = CGRect(x: rotatedPoint.x - handleSize/2, y: rotatedPoint.y - handleSize/2, width: handleSize, height: handleSize)
            context.fill(Path(handleRect), with: .color(.white))
            context.stroke(Path(handleRect), with: .color(.blue), lineWidth: 1)
        }
    }

    private func pathForAnnotation(_ annotation: Annotation) -> Path {
        let imageRect = annotation.boundingRect
        let screenOrigin = imageToScreen(imageRect.origin)
        let screenRect = CGRect(
            x: screenOrigin.x,
            y: screenOrigin.y,
            width: imageRect.width * displayScale,
            height: imageRect.height * displayScale
        )

        switch annotation.type {
        case .rectangle:
            return Path(screenRect)
        case .oval:
            return Path(ellipseIn: screenRect)
        case .line:
            return Path { path in
                path.move(to: imageToScreen(annotation.startPoint))
                path.addLine(to: imageToScreen(annotation.endPoint))
            }
        case .arrow:
            return Path() // Arrows handled separately with filled arrowhead
        case .pen:
            return Path { path in
                guard !annotation.points.isEmpty else {
                    path.move(to: imageToScreen(annotation.startPoint))
                    path.addLine(to: imageToScreen(annotation.endPoint))
                    return
                }
                path.move(to: imageToScreen(annotation.startPoint))
                for point in annotation.points {
                    path.addLine(to: imageToScreen(point))
                }
            }
        case .text:
            return Path()
        }
    }

    private func arrowPaths(annotation: Annotation, strokeWidth: CGFloat) -> (line: Path, arrowhead: Path) {
        let start = imageToScreen(annotation.startPoint)
        let end: CGPoint
        let controlPoint: CGPoint

        if annotation.points.isEmpty {
            end = imageToScreen(annotation.endPoint)
            controlPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        } else {
            end = imageToScreen(annotation.points.last!)
            controlPoint = calculateControlPoint(start: start, end: end, points: annotation.points.map { imageToScreen($0) })
        }

        // Calculate arrowhead angle based on curve tangent at end
        let angle = atan2(end.y - controlPoint.y, end.x - controlPoint.x)
        let arrowLength = max(10, strokeWidth * 4)
        let arrowAngle: CGFloat = .pi / 6

        let arrowPoint1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let arrowPoint2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )

        // Shorten the line so it ends at the base of the arrowhead
        let arrowBase = CGPoint(
            x: (arrowPoint1.x + arrowPoint2.x) / 2,
            y: (arrowPoint1.y + arrowPoint2.y) / 2
        )

        let linePath = Path { path in
            path.move(to: start)
            path.addQuadCurve(to: arrowBase, control: controlPoint)
        }

        let arrowheadPath = Path { path in
            path.move(to: end)
            path.addLine(to: arrowPoint1)
            path.addLine(to: arrowPoint2)
            path.closeSubpath()
        }

        return (linePath, arrowheadPath)
    }

    private func calculateControlPoint(start: CGPoint, end: CGPoint, points: [CGPoint]) -> CGPoint {
        let midPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)

        guard !points.isEmpty else {
            return midPoint
        }

        let dx = end.x - start.x
        let dy = end.y - start.y
        let lineLength = sqrt(dx * dx + dy * dy)

        guard lineLength > 0 else {
            return midPoint
        }

        // Calculate average signed perpendicular offset from the straight line
        // This averages out back-and-forth movements
        var totalOffset: CGFloat = 0
        for point in points {
            // Signed perpendicular distance (positive = one side, negative = other)
            let signedDistance = ((point.y - start.y) * dx - (point.x - start.x) * dy) / lineLength
            totalOffset += signedDistance
        }
        let avgOffset = totalOffset / CGFloat(points.count)

        // If the average curve is very slight, return straight line
        if abs(avgOffset) < 3 {
            return midPoint
        }

        // Calculate perpendicular direction (normalized)
        let perpX = -dy / lineLength
        let perpY = dx / lineLength

        // Place control point at midpoint offset by average perpendicular distance
        // Multiply by ~1.5 to make the curve more pronounced (bezier control point effect)
        return CGPoint(
            x: midPoint.x + perpX * avgOffset * 1.5,
            y: midPoint.y + perpY * avgOffset * 1.5
        )
    }
}

// MARK: - TextAnnotationView
// Uses the SAME NSTextView for both display AND editing - no more mismatches!

struct TextAnnotationView: View {
    let annotation: Annotation
    let isEditing: Bool
    let displayScale: CGFloat
    let screenPosition: CGPoint
    let onTextChange: (String) -> Void
    let onCommit: () -> Void
    let onCancel: () -> Void

    private var scaledFontSize: CGFloat {
        annotation.fontSize * displayScale
    }

    private var nsFont: NSFont {
        if annotation.fontName == "System" {
            return NSFont.systemFont(ofSize: scaledFontSize, weight: .medium)
        } else {
            return NSFont(name: annotation.fontName, size: scaledFontSize)
                ?? NSFont.systemFont(ofSize: scaledFontSize, weight: .medium)
        }
    }

    private static let textMeasurementService = TextMeasurementService()

    private func calculateTextSize() -> CGSize {
        Self.textMeasurementService.measureText(annotation.text, font: nsFont)
    }

    @State private var measuredSize: CGSize = CGSize(width: 10, height: 20)

    var body: some View {
        let scaledPaddingTop = annotation.textBackgroundColor != nil ? annotation.textBackgroundPaddingTop * displayScale : 0
        let scaledPaddingRight = annotation.textBackgroundColor != nil ? annotation.textBackgroundPaddingRight * displayScale : 0
        let scaledPaddingBottom = annotation.textBackgroundColor != nil ? annotation.textBackgroundPaddingBottom * displayScale : 0
        let scaledPaddingLeft = annotation.textBackgroundColor != nil ? annotation.textBackgroundPaddingLeft * displayScale : 0

        // Total size including padding
        let totalWidth = measuredSize.width + scaledPaddingLeft + scaledPaddingRight
        let totalHeight = measuredSize.height + scaledPaddingTop + scaledPaddingBottom

        // Calculate position to match annotation.boundingRect exactly
        // .position() places the CENTER of the view, so we need to calculate where center should be
        let posX: CGFloat = {
            switch annotation.textAlignment {
            case .left:
                // Left edge of box at (startPoint.x - paddingLeft), so center at (startPoint.x - paddingLeft + totalWidth/2)
                return screenPosition.x - scaledPaddingLeft + totalWidth / 2
            case .center:
                // Center of text at startPoint.x
                return screenPosition.x + (scaledPaddingRight - scaledPaddingLeft) / 2
            case .right:
                // Right edge of text at startPoint.x
                return screenPosition.x + scaledPaddingRight - totalWidth / 2
            }
        }()
        // Top edge of box at (startPoint.y - paddingTop), so center at (startPoint.y - paddingTop + totalHeight/2)
        let posY = screenPosition.y - scaledPaddingTop + totalHeight / 2

        TextViewWrapper(
            text: annotation.text,
            font: nsFont,
            textColor: NSColor(annotation.strokeColor),
            alignment: annotation.textAlignment,
            isEditing: isEditing,
            onTextChange: onTextChange,
            onCommit: onCommit,
            onCancel: onCancel
        )
        .fixedSize()
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    measuredSize = geo.size
                }.onChange(of: geo.size) { _, newSize in
                    measuredSize = newSize
                }
            }
        )
        .padding(EdgeInsets(
            top: scaledPaddingTop,
            leading: scaledPaddingLeft,
            bottom: scaledPaddingBottom,
            trailing: scaledPaddingRight
        ))
        .background(
            Group {
                if let bgColor = annotation.textBackgroundColor {
                    RoundedRectangle(cornerRadius: annotation.textBackgroundCornerRadius * displayScale)
                        .fill(bgColor)
                }
            }
        )
        .rotationEffect(Angle(radians: annotation.rotation), anchor: .center)
        .position(x: posX, y: posY)
        .allowsHitTesting(isEditing) // Only intercept clicks when editing
    }
}


// MARK: - TextViewWrapper (NSTextView-based)

struct TextViewWrapper: NSViewRepresentable {
    let text: String
    let font: NSFont
    let textColor: NSColor
    let alignment: TextAlignment
    let isEditing: Bool
    let onTextChange: (String) -> Void
    let onCommit: () -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> AnnotationTextView {
        let textView = AnnotationTextView()
        textView.delegate = context.coordinator
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isRichText = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0

        // CRITICAL: Prevent automatic text wrapping - only wrap on explicit newlines
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.size = NSSize(width: 10000, height: 10000)
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
        textView.maxSize = NSSize(width: 10000, height: 10000)

        let nsAlignment: NSTextAlignment
        switch alignment {
        case .left: nsAlignment = .left
        case .center: nsAlignment = .center
        case .right: nsAlignment = .right
        }
        textView.alignment = nsAlignment

        textView.string = text
        textView.isEditable = isEditing
        textView.isSelectable = isEditing
        textView.onCommit = onCommit
        textView.onCancel = onCancel

        if isEditing {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
                // Move cursor to end
                textView.setSelectedRange(NSRange(location: textView.string.count, length: 0))
            }
        }

        return textView
    }

    func updateNSView(_ textView: AnnotationTextView, context: Context) {
        // Only update text if not currently editing (to avoid cursor jumps)
        if !isEditing && textView.string != text {
            textView.string = text
        }

        textView.font = font
        textView.textColor = textColor
        textView.isEditable = isEditing
        textView.isSelectable = isEditing
        textView.onCommit = onCommit
        textView.onCancel = onCancel

        let nsAlignment: NSTextAlignment
        switch alignment {
        case .left: nsAlignment = .left
        case .center: nsAlignment = .center
        case .right: nsAlignment = .right
        }
        textView.alignment = nsAlignment

        if isEditing && textView.window?.firstResponder != textView {
            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(textView)
            }
        }

        textView.invalidateIntrinsicContentSize()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextViewWrapper

        init(_ parent: TextViewWrapper) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.onTextChange(textView.string)
        }
    }
}

// MARK: - AnnotationTextView (Custom NSTextView)

class AnnotationTextView: NSTextView {
    var onCommit: (() -> Void)?
    var onCancel: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        // Enter without Shift = commit
        if event.keyCode == 36 && !event.modifierFlags.contains(.shift) {
            onCommit?()
            return
        }
        // Escape = cancel
        if event.keyCode == 53 {
            onCancel?()
            return
        }
        // Shift+Enter inserts newline (default NSTextView behavior)
        super.keyDown(with: event)
    }

    private static let textMeasurementService = TextMeasurementService()

    override var intrinsicContentSize: NSSize {
        guard let font = self.font else { return super.intrinsicContentSize }
        let size = Self.textMeasurementService.measureText(string, font: font)
        return NSSize(width: size.width, height: size.height)
    }
}

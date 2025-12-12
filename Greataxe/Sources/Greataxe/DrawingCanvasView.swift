import SwiftUI
import AppKit

struct DrawingCanvasView: View {
    @Bindable var canvasState: CanvasState

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for annotation in canvasState.annotations {
                    drawAnnotation(annotation, in: &context)
                }
                if let current = canvasState.currentAnnotation {
                    drawAnnotation(current, in: &context)
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
        }
    }

    private func handleDragChanged(_ value: DragGesture.Value, in size: CGSize) {
        if canvasState.currentAnnotation == nil {
            canvasState.currentAnnotation = Annotation(
                type: annotationType(for: canvasState.currentTool),
                startPoint: value.startLocation,
                endPoint: value.location,
                strokeColor: canvasState.strokeColor,
                strokeWidth: canvasState.strokeWidth
            )
        } else {
            canvasState.currentAnnotation?.endPoint = value.location
            if canvasState.currentTool == .pen {
                canvasState.currentAnnotation?.points.append(value.location)
            }
        }
    }

    private func handleDragEnded(_ value: DragGesture.Value) {
        if var annotation = canvasState.currentAnnotation {
            annotation.endPoint = value.location
            canvasState.annotations.append(annotation)
            canvasState.currentAnnotation = nil
        }
    }

    private func annotationType(for tool: DrawingTool) -> AnnotationType {
        switch tool {
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
        context.stroke(
            pathForAnnotation(annotation),
            with: .color(annotation.strokeColor),
            lineWidth: annotation.strokeWidth
        )
    }

    private func pathForAnnotation(_ annotation: Annotation) -> Path {
        let rect = annotation.boundingRect

        switch annotation.type {
        case .rectangle:
            return Path(rect)
        case .oval:
            return Path(ellipseIn: rect)
        case .line:
            return Path { path in
                path.move(to: annotation.startPoint)
                path.addLine(to: annotation.endPoint)
            }
        case .arrow:
            return arrowPath(from: annotation.startPoint, to: annotation.endPoint, strokeWidth: annotation.strokeWidth)
        case .pen:
            return Path { path in
                guard !annotation.points.isEmpty else {
                    path.move(to: annotation.startPoint)
                    path.addLine(to: annotation.endPoint)
                    return
                }
                path.move(to: annotation.startPoint)
                for point in annotation.points {
                    path.addLine(to: point)
                }
            }
        case .text:
            return Path()
        }
    }

    private func arrowPath(from start: CGPoint, to end: CGPoint, strokeWidth: CGFloat) -> Path {
        Path { path in
            path.move(to: start)
            path.addLine(to: end)

            let angle = atan2(end.y - start.y, end.x - start.x)
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

            path.move(to: end)
            path.addLine(to: arrowPoint1)
            path.move(to: end)
            path.addLine(to: arrowPoint2)
        }
    }
}

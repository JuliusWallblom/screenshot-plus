import Foundation

enum HandlePosition: Equatable {
    case topLeft, topRight, bottomLeft, bottomRight
}

struct HitTestService {
    private let handleSize: CGFloat = 16
    private let hitPadding: CGFloat = 10

    func hitTestAnnotation(screenPoint: CGPoint, annotations: [Annotation], coordinateSpace: CoordinateSpace) -> Annotation? {
        for annotation in annotations.reversed() {
            let imageRect = annotation.boundingRect
            let screenOrigin = coordinateSpace.imageToScreen(imageRect.origin)
            let screenRect = CGRect(
                x: screenOrigin.x - hitPadding,
                y: screenOrigin.y - hitPadding,
                width: imageRect.width * coordinateSpace.scale + (hitPadding * 2),
                height: imageRect.height * coordinateSpace.scale + (hitPadding * 2)
            )
            if screenRect.contains(screenPoint) {
                return annotation
            }
        }
        return nil
    }

    func hitTestHandle(screenPoint: CGPoint, annotation: Annotation, coordinateSpace: CoordinateSpace) -> HandlePosition? {
        let imageRect = annotation.boundingRect
        let center = coordinateSpace.imageToScreen(CGPoint(x: imageRect.midX, y: imageRect.midY))

        let handles: [(HandlePosition, CGPoint)] = [
            (.topLeft, coordinateSpace.imageToScreen(CGPoint(x: imageRect.minX, y: imageRect.minY))),
            (.topRight, coordinateSpace.imageToScreen(CGPoint(x: imageRect.maxX, y: imageRect.minY))),
            (.bottomLeft, coordinateSpace.imageToScreen(CGPoint(x: imageRect.minX, y: imageRect.maxY))),
            (.bottomRight, coordinateSpace.imageToScreen(CGPoint(x: imageRect.maxX, y: imageRect.maxY)))
        ]

        for (position, handleCenter) in handles {
            let rotatedHandle = rotatePoint(handleCenter, around: center, by: annotation.rotation)
            let handleRect = CGRect(
                x: rotatedHandle.x - handleSize / 2,
                y: rotatedHandle.y - handleSize / 2,
                width: handleSize,
                height: handleSize
            )
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
}

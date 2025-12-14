import Foundation

/// Handles resize and rotation calculations for annotations.
struct ResizeRotateHandler {

    /// Calculates the rotation delta angle from a drag gesture.
    func calculateRotationDelta(
        center: CGPoint,
        dragStart: CGPoint,
        currentLocation: CGPoint
    ) -> CGFloat {
        let currentAngle = atan2(currentLocation.y - center.y, currentLocation.x - center.x)
        let startAngle = atan2(dragStart.y - center.y, dragStart.x - center.x)
        return currentAngle - startAngle
    }

    /// Calculates the new rectangle after resizing from a handle.
    func calculateResizedRect(
        original: CGRect,
        handle: HandlePosition,
        dragLocation: CGPoint,
        constrainAspectRatio: Bool
    ) -> CGRect {
        var newRect = original

        switch handle {
        case .topLeft:
            newRect.origin = dragLocation
            newRect.size.width = original.maxX - dragLocation.x
            newRect.size.height = original.maxY - dragLocation.y
        case .topRight:
            newRect.origin.y = dragLocation.y
            newRect.size.width = dragLocation.x - original.minX
            newRect.size.height = original.maxY - dragLocation.y
        case .bottomLeft:
            newRect.origin.x = dragLocation.x
            newRect.size.width = original.maxX - dragLocation.x
            newRect.size.height = dragLocation.y - original.minY
        case .bottomRight:
            newRect.size.width = dragLocation.x - original.minX
            newRect.size.height = dragLocation.y - original.minY
        }

        // Constrain aspect ratio if requested
        if constrainAspectRatio && original.width > 0 && original.height > 0 {
            var originalAspect = original.width / original.height
            // Snap to 1:1 if very close
            if abs(originalAspect - 1.0) < 0.02 {
                originalAspect = 1.0
            }

            let size = max(abs(newRect.width), abs(newRect.height))
            let adjustedWidth = size * (newRect.width < 0 ? -1 : 1)
            let adjustedHeight = size / originalAspect * (newRect.height < 0 ? -1 : 1)

            switch handle {
            case .topLeft:
                newRect.origin.x = original.maxX - adjustedWidth
                newRect.origin.y = original.maxY - adjustedHeight
                newRect.size.width = adjustedWidth
                newRect.size.height = adjustedHeight
            case .topRight:
                newRect.origin.y = original.maxY - adjustedHeight
                newRect.size.width = adjustedWidth
                newRect.size.height = adjustedHeight
            case .bottomLeft:
                newRect.origin.x = original.maxX - adjustedWidth
                newRect.size.width = adjustedWidth
                newRect.size.height = adjustedHeight
            case .bottomRight:
                newRect.size.width = adjustedWidth
                newRect.size.height = adjustedHeight
            }
        }

        return newRect
    }

    /// Scales an array of points from one rect to another.
    func scalePoints(_ points: [CGPoint], from originalRect: CGRect, to newRect: CGRect) -> [CGPoint] {
        let scaleX = originalRect.width > 0 ? newRect.width / originalRect.width : 1
        let scaleY = originalRect.height > 0 ? newRect.height / originalRect.height : 1

        return points.map { point in
            CGPoint(
                x: newRect.minX + (point.x - originalRect.minX) * scaleX,
                y: newRect.minY + (point.y - originalRect.minY) * scaleY
            )
        }
    }
}

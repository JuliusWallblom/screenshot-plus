import AppKit
import SwiftUI

struct AnnotationRenderer {
    func calculateArrowControlPoint(start: CGPoint, end: CGPoint, points: [CGPoint]) -> CGPoint {
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

        var totalOffset: CGFloat = 0
        for point in points {
            let signedDistance = ((point.y - start.y) * dx - (point.x - start.x) * dy) / lineLength
            totalOffset += signedDistance
        }
        let avgOffset = totalOffset / CGFloat(points.count)

        if abs(avgOffset) < 3 {
            return midPoint
        }

        let perpX = -dy / lineLength
        let perpY = dx / lineLength

        return CGPoint(
            x: midPoint.x + perpX * avgOffset * 1.5,
            y: midPoint.y + perpY * avgOffset * 1.5
        )
    }

    func calculateArrowhead(end: CGPoint, controlPoint: CGPoint, strokeWidth: CGFloat) -> (point1: CGPoint, point2: CGPoint, base: CGPoint) {
        let angle = atan2(end.y - controlPoint.y, end.x - controlPoint.x)
        let arrowLength = max(10, strokeWidth * 4)
        let arrowAngle: CGFloat = .pi / 6

        let point1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let point2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )
        let base = CGPoint(
            x: (point1.x + point2.x) / 2,
            y: (point1.y + point2.y) / 2
        )

        return (point1, point2, base)
    }
}

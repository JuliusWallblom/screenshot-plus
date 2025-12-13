import Testing
import AppKit
@testable import Preview_

@Suite("AnnotationRenderer Tests")
struct AnnotationRendererTests {
    @Test("AnnotationRenderer calculates arrow control point for straight line")
    func calculatesArrowControlPointForStraightLine() {
        let renderer = AnnotationRenderer()
        let start = CGPoint(x: 0, y: 0)
        let end = CGPoint(x: 100, y: 0)

        let controlPoint = renderer.calculateArrowControlPoint(start: start, end: end, points: [])

        // For straight line with no points, control point should be at midpoint
        #expect(controlPoint.x == 50)
        #expect(controlPoint.y == 0)
    }

    @Test("AnnotationRenderer calculates arrowhead geometry")
    func calculatesArrowheadGeometry() {
        let renderer = AnnotationRenderer()
        let end = CGPoint(x: 100, y: 0)
        let controlPoint = CGPoint(x: 50, y: 0)

        let arrowhead = renderer.calculateArrowhead(end: end, controlPoint: controlPoint, strokeWidth: 2.0)

        // Arrowhead base should be between the arrow tip (end) and the two wing points
        #expect(arrowhead.base.x < end.x)
        #expect(arrowhead.point1.x < end.x)
        #expect(arrowhead.point2.x < end.x)
    }
}

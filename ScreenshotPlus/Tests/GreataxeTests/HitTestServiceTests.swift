import Testing
import SwiftUI
@testable import Screenshot_

@Suite("HitTestService Tests")
struct HitTestServiceTests {
    @Test("HitTestService finds annotation at screen point")
    func findsAnnotationAtScreenPoint() {
        let service = HitTestService()
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 100, y: 100),
            endPoint: CGPoint(x: 200, y: 200),
            strokeColor: .red,
            strokeWidth: 2.0
        )
        let annotations = [annotation]
        let coordinateSpace = CoordinateSpace(
            imageSize: CGSize(width: 1000, height: 1000),
            screenRect: CGRect(x: 0, y: 0, width: 500, height: 500)
        )

        // Screen point in the middle of the annotation (scaled down by 2x)
        let screenPoint = CGPoint(x: 75, y: 75) // Maps to image ~(150, 150) which is inside rect
        let result = service.hitTestAnnotation(screenPoint: screenPoint, annotations: annotations, coordinateSpace: coordinateSpace)

        #expect(result?.id == annotation.id)
    }

    @Test("HitTestService returns nil when clicking outside annotations")
    func returnsNilWhenOutsideAnnotations() {
        let service = HitTestService()
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 100, y: 100),
            endPoint: CGPoint(x: 200, y: 200),
            strokeColor: .red,
            strokeWidth: 2.0
        )
        let annotations = [annotation]
        let coordinateSpace = CoordinateSpace(
            imageSize: CGSize(width: 1000, height: 1000),
            screenRect: CGRect(x: 0, y: 0, width: 500, height: 500)
        )

        // Screen point far outside the annotation
        let screenPoint = CGPoint(x: 400, y: 400)
        let result = service.hitTestAnnotation(screenPoint: screenPoint, annotations: annotations, coordinateSpace: coordinateSpace)

        #expect(result == nil)
    }

    @Test("HitTestService detects handle positions")
    func detectsHandlePositions() {
        let service = HitTestService()
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 100, y: 100),
            endPoint: CGPoint(x: 200, y: 200),
            strokeColor: .red,
            strokeWidth: 2.0
        )
        let coordinateSpace = CoordinateSpace(
            imageSize: CGSize(width: 1000, height: 1000),
            screenRect: CGRect(x: 0, y: 0, width: 500, height: 500)
        )

        // Screen point at bottom-right handle (200, 200 in image = 100, 100 in screen)
        let screenPoint = CGPoint(x: 100, y: 100)
        let result = service.hitTestHandle(screenPoint: screenPoint, annotation: annotation, coordinateSpace: coordinateSpace)

        #expect(result == .bottomRight)
    }
}

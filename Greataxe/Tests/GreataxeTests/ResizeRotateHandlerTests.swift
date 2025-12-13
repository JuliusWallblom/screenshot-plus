import Testing
import AppKit
@testable import Preview_

@Suite("ResizeRotateHandler Tests")
struct ResizeRotateHandlerTests {
    @Test("calculates rotation angle from drag")
    func calculatesRotationAngle() {
        let handler = ResizeRotateHandler()

        // Annotation centered at (100, 100)
        let center = CGPoint(x: 100, y: 100)
        // Start dragging from right side (0 degrees)
        let dragStart = CGPoint(x: 150, y: 100)
        // Drag to top (90 degrees counter-clockwise in standard coords, but -90 in screen coords)
        let currentLocation = CGPoint(x: 100, y: 50)

        let deltaAngle = handler.calculateRotationDelta(
            center: center,
            dragStart: dragStart,
            currentLocation: currentLocation
        )

        // Should be approximately -π/2 (90 degrees counter-clockwise)
        #expect(abs(deltaAngle + .pi / 2) < 0.01)
    }

    @Test("calculates new rect for bottom-right resize")
    func calculatesNewRectForBottomRightResize() {
        let handler = ResizeRotateHandler()

        let originalRect = CGRect(x: 100, y: 100, width: 100, height: 100)
        let dragLocation = CGPoint(x: 250, y: 250)

        let newRect = handler.calculateResizedRect(
            original: originalRect,
            handle: .bottomRight,
            dragLocation: dragLocation,
            constrainAspectRatio: false
        )

        #expect(newRect.origin.x == 100)
        #expect(newRect.origin.y == 100)
        #expect(newRect.width == 150)
        #expect(newRect.height == 150)
    }

    @Test("calculates new rect for top-left resize")
    func calculatesNewRectForTopLeftResize() {
        let handler = ResizeRotateHandler()

        let originalRect = CGRect(x: 100, y: 100, width: 100, height: 100)
        let dragLocation = CGPoint(x: 50, y: 50)

        let newRect = handler.calculateResizedRect(
            original: originalRect,
            handle: .topLeft,
            dragLocation: dragLocation,
            constrainAspectRatio: false
        )

        #expect(newRect.origin.x == 50)
        #expect(newRect.origin.y == 50)
        #expect(newRect.width == 150)
        #expect(newRect.height == 150)
    }

    @Test("constrains aspect ratio when requested")
    func constrainsAspectRatio() {
        let handler = ResizeRotateHandler()

        // 2:1 aspect ratio rectangle
        let originalRect = CGRect(x: 100, y: 100, width: 200, height: 100)
        // Drag to make it taller than wide
        let dragLocation = CGPoint(x: 250, y: 300)

        let newRect = handler.calculateResizedRect(
            original: originalRect,
            handle: .bottomRight,
            dragLocation: dragLocation,
            constrainAspectRatio: true
        )

        // Should maintain 2:1 aspect ratio
        let aspectRatio = newRect.width / newRect.height
        #expect(abs(aspectRatio - 2.0) < 0.01)
    }

    @Test("scales points proportionally")
    func scalesPointsProportionally() {
        let handler = ResizeRotateHandler()

        let originalRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let newRect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let points = [
            CGPoint(x: 50, y: 50),   // center
            CGPoint(x: 0, y: 0),     // origin
            CGPoint(x: 100, y: 100)  // opposite corner
        ]

        let scaledPoints = handler.scalePoints(points, from: originalRect, to: newRect)

        #expect(scaledPoints[0].x == 100)  // center scaled
        #expect(scaledPoints[0].y == 100)
        #expect(scaledPoints[1].x == 0)    // origin unchanged
        #expect(scaledPoints[1].y == 0)
        #expect(scaledPoints[2].x == 200)  // corner scaled
        #expect(scaledPoints[2].y == 200)
    }
}

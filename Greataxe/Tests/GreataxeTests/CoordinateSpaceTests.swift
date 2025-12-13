import Testing
import SwiftUI
@testable import Preview_

@Suite("CoordinateSpace Tests")
struct CoordinateSpaceTests {
    @Test("CoordinateSpace converts screen point to image coordinates")
    func screenToImageConversion() {
        let coordinateSpace = CoordinateSpace(
            imageSize: CGSize(width: 1000, height: 500),
            screenRect: CGRect(x: 100, y: 50, width: 500, height: 250)
        )

        // Point at screen (100, 50) should map to image (0, 0)
        let imagePoint = coordinateSpace.screenToImage(CGPoint(x: 100, y: 50))

        #expect(imagePoint.x == 0)
        #expect(imagePoint.y == 0)
    }

    @Test("CoordinateSpace converts image point to screen coordinates")
    func imageToScreenConversion() {
        let coordinateSpace = CoordinateSpace(
            imageSize: CGSize(width: 1000, height: 500),
            screenRect: CGRect(x: 100, y: 50, width: 500, height: 250)
        )

        // Image point (0, 0) should map to screen (100, 50)
        let screenPoint = coordinateSpace.imageToScreen(CGPoint(x: 0, y: 0))

        #expect(screenPoint.x == 100)
        #expect(screenPoint.y == 50)
    }

    @Test("CoordinateSpace provides display scale factor")
    func displayScaleFactor() {
        let coordinateSpace = CoordinateSpace(
            imageSize: CGSize(width: 1000, height: 500),
            screenRect: CGRect(x: 100, y: 50, width: 500, height: 250)
        )

        // screenRect.width / imageSize.width = 500 / 1000 = 0.5
        #expect(coordinateSpace.scale == 0.5)
    }

    @Test("Round-trip conversion preserves coordinates")
    func roundTripConversion() {
        let coordinateSpace = CoordinateSpace(
            imageSize: CGSize(width: 1000, height: 500),
            screenRect: CGRect(x: 100, y: 50, width: 500, height: 250)
        )

        let originalScreen = CGPoint(x: 250, y: 150)
        let toImage = coordinateSpace.screenToImage(originalScreen)
        let backToScreen = coordinateSpace.imageToScreen(toImage)

        #expect(abs(backToScreen.x - originalScreen.x) < 0.001)
        #expect(abs(backToScreen.y - originalScreen.y) < 0.001)
    }
}

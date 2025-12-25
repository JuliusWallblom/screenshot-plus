import Testing
import AppKit
@testable import Screenshot_

@Suite("ImageExporter Tests")
struct ImageExporterTests {
    @Test("Annotation near top of image exports near top")
    func annotationNearTopExportsNearTop() throws {
        // Create a 100x100 white image
        let size = NSSize(width: 100, height: 100)
        let baseImage = NSImage(size: size)
        baseImage.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        baseImage.unlockFocus()

        // Create a filled rectangle annotation at Y=5-15 (near top in SwiftUI coordinates)
        // In SwiftUI, Y=0 is at top, so Y=5 means 5 pixels from top
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 40, y: 5),
            endPoint: CGPoint(x: 60, y: 15),
            strokeColor: .red,
            strokeWidth: 2.0,
            isFilled: true
        )

        let exporter = ImageExporter()
        let resultImage = exporter.renderImage(baseImage, with: [annotation])

        #expect(resultImage != nil)

        guard let result = resultImage,
              let tiffData = result.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            Issue.record("Failed to get bitmap from result image")
            return
        }

        // Find all non-white pixels (the annotation)
        var annotationPixels: [(Int, Int)] = []
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                if let color = bitmap.colorAt(x: x, y: y) {
                    let isWhite = color.redComponent > 0.99 && color.greenComponent > 0.99 && color.blueComponent > 0.99
                    if !isWhite {
                        annotationPixels.append((x, y))
                    }
                }
            }
        }

        #expect(!annotationPixels.isEmpty, "Should find annotation pixels")

        if !annotationPixels.isEmpty {
            let minY = annotationPixels.map { $0.1 }.min()!
            let maxY = annotationPixels.map { $0.1 }.max()!

            // The annotation at SwiftUI Y=5-15 should appear near the TOP of the exported image
            // In bitmap coordinates (Y=0 at top), this should be around Y=10-30 (at 2x scale)
            let scale = CGFloat(bitmap.pixelsWide) / size.width
            let expectedMinY = 5.0 * scale  // Y=5 from top in points
            let expectedMaxY = 15.0 * scale // Y=15 from top in points

            // Allow some tolerance for anti-aliasing
            let tolerance = 5.0 * scale
            #expect(CGFloat(minY) >= expectedMinY - tolerance,
                    "Annotation top edge (\(minY)) should be near expected position (\(expectedMinY))")
            #expect(CGFloat(maxY) <= expectedMaxY + tolerance,
                    "Annotation bottom edge (\(maxY)) should be near expected position (\(expectedMaxY))")

            // The annotation should NOT be near the bottom (which would indicate the bug)
            let imageHeightPixels = CGFloat(bitmap.pixelsHigh)
            let bottomThreshold = imageHeightPixels * 0.7
            #expect(CGFloat(minY) < bottomThreshold,
                    "Annotation should be in top half, not bottom (found at Y=\(minY), threshold=\(bottomThreshold))")
        }
    }

    @Test("Annotation near bottom of image exports near bottom")
    func annotationNearBottomExportsNearBottom() throws {
        let size = NSSize(width: 100, height: 100)
        let baseImage = NSImage(size: size)
        baseImage.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        baseImage.unlockFocus()

        // Create annotation at Y=85-95 (near bottom in SwiftUI coordinates)
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 40, y: 85),
            endPoint: CGPoint(x: 60, y: 95),
            strokeColor: .blue,
            strokeWidth: 2.0,
            isFilled: true
        )

        let exporter = ImageExporter()
        let resultImage = exporter.renderImage(baseImage, with: [annotation])

        guard let result = resultImage,
              let tiffData = result.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            Issue.record("Failed to get bitmap")
            return
        }

        var annotationPixels: [(Int, Int)] = []
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                if let color = bitmap.colorAt(x: x, y: y) {
                    let isWhite = color.redComponent > 0.99 && color.greenComponent > 0.99 && color.blueComponent > 0.99
                    if !isWhite {
                        annotationPixels.append((x, y))
                    }
                }
            }
        }

        #expect(!annotationPixels.isEmpty, "Should find annotation pixels")

        if !annotationPixels.isEmpty {
            let minY = annotationPixels.map { $0.1 }.min()!
            let imageHeightPixels = CGFloat(bitmap.pixelsHigh)

            // Annotation at Y=85-95 from top should be in the bottom portion of the image
            let topThreshold = imageHeightPixels * 0.7
            #expect(CGFloat(minY) >= topThreshold,
                    "Annotation should be in bottom portion (found at Y=\(minY), threshold=\(topThreshold))")
        }
    }
}

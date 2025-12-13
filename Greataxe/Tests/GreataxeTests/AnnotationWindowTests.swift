import Testing
import SwiftUI
@testable import Preview_

@Suite("Annotation Window Tests")
struct AnnotationWindowTests {
    @Test("AnnotationWindowState holds image URL")
    func annotationWindowStateHoldsImageURL() throws {
        let testURL = URL(fileURLWithPath: "/tmp/test-screenshot.png")
        let state = AnnotationWindowState(imageURL: testURL)

        #expect(state.imageURL == testURL)
    }

    @Test("AnnotationWindowState can load NSImage from URL")
    func annotationWindowStateLoadsImage() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let testImagePath = tempDir.appendingPathComponent("test-screenshot.png")

        // Create a simple 100x100 red PNG image
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw TestError.imageCreationFailed
        }

        try pngData.write(to: testImagePath)
        defer { try? FileManager.default.removeItem(at: testImagePath) }

        let state = AnnotationWindowState(imageURL: testImagePath)
        let loadedImage = state.loadImage()

        #expect(loadedImage != nil)
        #expect(loadedImage?.size.width == 100)
        #expect(loadedImage?.size.height == 100)
    }
}

enum TestError: Error {
    case imageCreationFailed
}

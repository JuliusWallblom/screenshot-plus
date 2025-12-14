import Testing
import AppKit
@testable import Screenshot_

@Suite("Clipboard Tests")
struct ClipboardTests {
    @Test("ImageExporter can render image with annotations")
    func imageExporterCanRenderImageWithAnnotations() throws {
        let size = NSSize(width: 100, height: 100)
        let baseImage = NSImage(size: size)
        baseImage.lockFocus()
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        baseImage.unlockFocus()

        let annotations = [
            Annotation(
                type: .rectangle,
                startPoint: CGPoint(x: 10, y: 10),
                endPoint: CGPoint(x: 50, y: 50),
                strokeColor: .red,
                strokeWidth: 2.0
            )
        ]

        let exporter = ImageExporter()
        let resultImage = exporter.renderImage(baseImage, with: annotations)

        #expect(resultImage != nil)
        #expect(resultImage?.size.width == 100)
        #expect(resultImage?.size.height == 100)
    }

    @Test("ImageExporter can copy image to clipboard")
    func imageExporterCanCopyImageToClipboard() throws {
        let size = NSSize(width: 50, height: 50)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()

        let exporter = ImageExporter()
        let success = exporter.copyToClipboard(image)

        #expect(success)
    }
}

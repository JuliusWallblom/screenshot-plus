import Testing
import AppKit
@testable import Screenshot_

@Suite("FileOperationError Tests")
struct FileOperationErrorTests {
    @Test("ExportError has descriptive messages")
    func exportErrorHasDescriptiveMessages() {
        let renderError = ExportError.renderFailed
        let writeError = ExportError.writeFailed(NSError(domain: "test", code: 1))
        let conversionError = ExportError.imageConversionFailed

        #expect(renderError.localizedDescription.contains("render"))
        #expect(writeError.localizedDescription.contains("write") || writeError.localizedDescription.contains("save"))
        #expect(conversionError.localizedDescription.contains("convert"))
    }

    @Test("ImageExporter saveToFileResult returns success for valid operation")
    func saveToFileResultReturnsSuccess() throws {
        let exporter = ImageExporter()
        let image = NSImage(size: NSSize(width: 100, height: 100))
        image.lockFocus()
        NSColor.red.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 100, height: 100)).fill()
        image.unlockFocus()

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = exporter.saveToFileResult(image, at: tempURL)

        switch result {
        case .success(let url):
            #expect(url == tempURL)
            #expect(FileManager.default.fileExists(atPath: tempURL.path))
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    @Test("ImageExporter saveToFileResult returns failure for invalid path")
    func saveToFileResultReturnsFailure() {
        let exporter = ImageExporter()
        let image = NSImage(size: NSSize(width: 100, height: 100))

        // Invalid path that can't be written to
        let invalidURL = URL(fileURLWithPath: "/nonexistent/path/image.png")

        let result = exporter.saveToFileResult(image, at: invalidURL)

        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure:
            // Expected
            break
        }
    }
}

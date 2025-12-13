import Testing
import AppKit
@testable import Preview_

@Suite("TextMeasurementService Tests")
struct TextMeasurementServiceTests {
    @Test("TextMeasurementService creates font for system font name")
    func createsFontForSystemFontName() {
        let service = TextMeasurementService()
        let font = service.font(name: "System", size: 16)

        #expect(font.pointSize == 16)
    }

    @Test("TextMeasurementService measures single line text size")
    func measuresSingleLineTextSize() {
        let service = TextMeasurementService()
        let font = service.font(name: "System", size: 16)
        let size = service.measureText("Hello", font: font)

        #expect(size.width > 0)
        #expect(size.height > 0)
    }

    @Test("TextMeasurementService measures multiline text correctly")
    func measuresMultilineTextSize() {
        let service = TextMeasurementService()
        let font = service.font(name: "System", size: 16)
        let singleLine = service.measureText("Hello", font: font)
        let twoLines = service.measureText("Hello\nWorld", font: font)

        // Two lines should be roughly twice the height
        #expect(twoLines.height > singleLine.height * 1.5)
    }

    @Test("TextMeasurementService handles empty text with minimum size")
    func handlesEmptyTextWithMinimumSize() {
        let service = TextMeasurementService()
        let font = service.font(name: "System", size: 16)
        let size = service.measureText("", font: font)

        // Empty text should still have minimum width and height
        #expect(size.width >= 10)
        #expect(size.height > 0)
    }
}

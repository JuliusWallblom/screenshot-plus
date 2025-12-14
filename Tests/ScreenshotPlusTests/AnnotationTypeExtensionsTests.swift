import Testing
import SwiftUI
@testable import Screenshot_

@Suite("Annotation Type Extensions Tests")
struct AnnotationTypeExtensionsTests {
    @Test("isShape returns true for shape types")
    func isShapeReturnsTrue() {
        let rectangle = Annotation(type: .rectangle, startPoint: .zero, endPoint: CGPoint(x: 100, y: 100), strokeColor: .red, strokeWidth: 2)
        let oval = Annotation(type: .oval, startPoint: .zero, endPoint: CGPoint(x: 100, y: 100), strokeColor: .red, strokeWidth: 2)
        let line = Annotation(type: .line, startPoint: .zero, endPoint: CGPoint(x: 100, y: 100), strokeColor: .red, strokeWidth: 2)

        #expect(rectangle.isShape == true)
        #expect(oval.isShape == true)
        #expect(line.isShape == true)
    }

    @Test("isShape returns false for non-shape types")
    func isShapeReturnsFalse() {
        let text = Annotation(type: .text, startPoint: .zero, endPoint: .zero, strokeColor: .red, strokeWidth: 2, text: "Hello")
        let pen = Annotation(type: .pen, startPoint: .zero, endPoint: CGPoint(x: 100, y: 100), strokeColor: .red, strokeWidth: 2)

        #expect(text.isShape == false)
        #expect(pen.isShape == false)
    }

    @Test("isDrawnPath returns true for pen and arrow")
    func isDrawnPathReturnsTrue() {
        let pen = Annotation(type: .pen, startPoint: .zero, endPoint: CGPoint(x: 100, y: 100), strokeColor: .red, strokeWidth: 2)
        let arrow = Annotation(type: .arrow, startPoint: .zero, endPoint: CGPoint(x: 100, y: 100), strokeColor: .red, strokeWidth: 2)

        #expect(pen.isDrawnPath == true)
        #expect(arrow.isDrawnPath == true)
    }

    @Test("hasTextBackground returns true only when background color is set")
    func hasTextBackgroundWorks() {
        var text = Annotation(type: .text, startPoint: .zero, endPoint: .zero, strokeColor: .red, strokeWidth: 2, text: "Hello")
        #expect(text.hasTextBackground == false)

        text.textBackgroundColor = .blue
        #expect(text.hasTextBackground == true)
    }

    @Test("canBeFilled returns true for rectangle and oval")
    func canBeFilledWorks() {
        let rectangle = Annotation(type: .rectangle, startPoint: .zero, endPoint: CGPoint(x: 100, y: 100), strokeColor: .red, strokeWidth: 2)
        let oval = Annotation(type: .oval, startPoint: .zero, endPoint: CGPoint(x: 100, y: 100), strokeColor: .red, strokeWidth: 2)
        let line = Annotation(type: .line, startPoint: .zero, endPoint: CGPoint(x: 100, y: 100), strokeColor: .red, strokeWidth: 2)

        #expect(rectangle.canBeFilled == true)
        #expect(oval.canBeFilled == true)
        #expect(line.canBeFilled == false)
    }

    @Test("correspondingTool returns matching DrawingTool for each AnnotationType")
    func correspondingToolMapsCorrectly() {
        #expect(AnnotationType.rectangle.correspondingTool == .rectangle)
        #expect(AnnotationType.oval.correspondingTool == .oval)
        #expect(AnnotationType.line.correspondingTool == .line)
        #expect(AnnotationType.arrow.correspondingTool == .arrow)
        #expect(AnnotationType.pen.correspondingTool == .pen)
        #expect(AnnotationType.text.correspondingTool == .text)
    }
}

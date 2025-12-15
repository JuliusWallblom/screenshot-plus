import Testing
import SwiftUI
@testable import Screenshot_

@Suite("Text Annotation Tests")
struct TextAnnotationTests {
    @Test("Text annotation stores text content")
    func textAnnotationStoresTextContent() {
        var annotation = Annotation(
            type: .text,
            startPoint: CGPoint(x: 50, y: 50),
            endPoint: CGPoint(x: 50, y: 50),
            strokeColor: .black,
            strokeWidth: 1.0
        )
        annotation.text = "Hello World"

        #expect(annotation.text == "Hello World")
        #expect(annotation.type == .text)
    }

    @Test("Text annotation has text stroke properties")
    func textAnnotationHasTextStrokeProperties() {
        var annotation = Annotation(
            type: .text,
            startPoint: CGPoint(x: 50, y: 50),
            endPoint: CGPoint(x: 50, y: 50),
            strokeColor: .black,
            strokeWidth: 1.0
        )

        // Default values
        #expect(annotation.textStrokeColor == nil)
        #expect(annotation.textStrokeWidth == 1.0)

        // Set stroke properties
        annotation.textStrokeColor = .red
        annotation.textStrokeWidth = 2.0

        #expect(annotation.textStrokeColor == .red)
        #expect(annotation.textStrokeWidth == 2.0)
    }

    @Test("TextAnnotationState manages editing state")
    func textAnnotationStateManagesEditingState() {
        let textState = TextAnnotationState()

        #expect(textState.isEditing == false)
        #expect(textState.editingText == "")

        textState.startEditing(at: CGPoint(x: 100, y: 100))

        #expect(textState.isEditing == true)
        #expect(textState.editingPosition == CGPoint(x: 100, y: 100))

        textState.editingText = "Test text"
        let annotation = textState.finishEditing(color: .red)

        #expect(textState.isEditing == false)
        #expect(annotation?.text == "Test text")
        #expect(annotation?.type == .text)
    }
}

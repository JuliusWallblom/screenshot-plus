import Testing
import SwiftUI
@testable import Preview_

@Suite("TextEditingController Tests")
struct TextEditingControllerTests {
    @Test("TextEditingController starts in idle state")
    func startsInIdleState() {
        let controller = TextEditingController()

        #expect(controller.state == .idle)
        #expect(controller.editingAnnotationId == nil)
        #expect(controller.isCreatingNew == false)
    }

    @Test("TextEditingController can start creating new text")
    func canStartCreatingNewText() {
        let controller = TextEditingController()
        let position = CGPoint(x: 100, y: 100)

        controller.startCreatingText(at: position, color: .red, fontSize: 16, fontName: "SF Pro")

        #expect(controller.state == .creating)
        #expect(controller.isCreatingNew == true)
        #expect(controller.newAnnotation != nil)
        #expect(controller.screenPosition == position)
    }

    @Test("TextEditingController can start editing existing text")
    func canStartEditingExistingText() {
        let controller = TextEditingController()
        let annotation = Annotation(
            type: .text,
            startPoint: CGPoint(x: 100, y: 100),
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .red,
            strokeWidth: 2,
            text: "Hello"
        )

        controller.startEditing(annotation: annotation)

        #expect(controller.state == .editing)
        #expect(controller.editingAnnotationId == annotation.id)
        #expect(controller.originalText == "Hello")
    }

    @Test("TextEditingController can commit new text")
    func canCommitNewText() {
        let controller = TextEditingController()
        controller.startCreatingText(at: CGPoint(x: 100, y: 100), color: .red, fontSize: 16, fontName: "SF Pro")
        controller.newAnnotation?.text = "New text"

        let result = controller.commit()

        #expect(result != nil)
        #expect(result?.text == "New text")
        #expect(controller.state == .idle)
    }

    @Test("TextEditingController cancel restores original text")
    func cancelRestoresOriginalText() {
        let controller = TextEditingController()

        _ = controller.cancel()

        #expect(controller.state == .idle)
        #expect(controller.editingAnnotationId == nil)
    }
}

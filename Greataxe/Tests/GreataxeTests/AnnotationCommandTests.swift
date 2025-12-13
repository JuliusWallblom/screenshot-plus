import Testing
import SwiftUI
@testable import Greataxe

@Suite("AnnotationCommand Tests")
struct AnnotationCommandTests {
    @Test("AddAnnotationCommand adds annotation on execute")
    func addAnnotationOnExecute() {
        var annotations: [Annotation] = []
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .red,
            strokeWidth: 2
        )

        let command = AddAnnotationCommand(annotation: annotation)
        command.execute(annotations: &annotations)

        #expect(annotations.count == 1)
        #expect(annotations[0].id == annotation.id)
    }

    @Test("AddAnnotationCommand removes annotation on undo")
    func removeAnnotationOnUndo() {
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .red,
            strokeWidth: 2
        )
        var annotations: [Annotation] = [annotation]

        let command = AddAnnotationCommand(annotation: annotation)
        command.undo(annotations: &annotations)

        #expect(annotations.isEmpty)
    }

    @Test("DeleteAnnotationCommand removes annotation on execute")
    func deleteAnnotationOnExecute() {
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .red,
            strokeWidth: 2
        )
        var annotations: [Annotation] = [annotation]

        let command = DeleteAnnotationCommand(annotation: annotation, index: 0)
        command.execute(annotations: &annotations)

        #expect(annotations.isEmpty)
    }

    @Test("DeleteAnnotationCommand restores annotation on undo")
    func restoreAnnotationOnUndo() {
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .red,
            strokeWidth: 2
        )
        var annotations: [Annotation] = []

        let command = DeleteAnnotationCommand(annotation: annotation, index: 0)
        command.undo(annotations: &annotations)

        #expect(annotations.count == 1)
        #expect(annotations[0].id == annotation.id)
    }
}

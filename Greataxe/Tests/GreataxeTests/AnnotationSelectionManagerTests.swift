import Testing
import SwiftUI
@testable import Preview_

@Suite("AnnotationSelectionManager Tests")
struct AnnotationSelectionManagerTests {
    @Test("AnnotationSelectionManager can select single annotation")
    func selectsSingleAnnotation() {
        let manager = AnnotationSelectionManager()
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 10, y: 10),
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .red,
            strokeWidth: 2.0
        )

        manager.select(annotation)

        #expect(manager.selectedIds.contains(annotation.id))
        #expect(manager.selectedIds.count == 1)
    }

    @Test("AnnotationSelectionManager can add to existing selection")
    func addsToExistingSelection() {
        let manager = AnnotationSelectionManager()
        let annotation1 = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 10, y: 10),
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .red,
            strokeWidth: 2.0
        )
        let annotation2 = Annotation(
            type: .oval,
            startPoint: CGPoint(x: 50, y: 50),
            endPoint: CGPoint(x: 150, y: 150),
            strokeColor: .blue,
            strokeWidth: 2.0
        )

        manager.select(annotation1)
        manager.addToSelection(annotation2)

        #expect(manager.selectedIds.count == 2)
        #expect(manager.isSelected(annotation1))
        #expect(manager.isSelected(annotation2))
    }

    @Test("AnnotationSelectionManager can clear selection")
    func clearsSelection() {
        let manager = AnnotationSelectionManager()
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 10, y: 10),
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .red,
            strokeWidth: 2.0
        )

        manager.select(annotation)
        manager.clearSelection()

        #expect(manager.selectedIds.isEmpty)
    }

    @Test("AnnotationSelectionManager can toggle selection")
    func togglesSelection() {
        let manager = AnnotationSelectionManager()
        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 10, y: 10),
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .red,
            strokeWidth: 2.0
        )

        manager.toggleSelection(annotation)
        #expect(manager.isSelected(annotation))

        manager.toggleSelection(annotation)
        #expect(!manager.isSelected(annotation))
    }
}

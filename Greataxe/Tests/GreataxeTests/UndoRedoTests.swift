import Testing
import SwiftUI
@testable import Greataxe

@Suite("Undo/Redo Tests")
struct UndoRedoTests {
    @Test("UndoManager can undo adding annotation")
    func undoManagerCanUndoAddingAnnotation() {
        let undoManager = AnnotationUndoManager()
        let canvasState = CanvasState()

        let annotation = Annotation(
            type: .rectangle,
            startPoint: CGPoint(x: 10, y: 10),
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .red,
            strokeWidth: 2.0
        )

        undoManager.addAnnotation(annotation, to: canvasState)

        #expect(canvasState.annotations.count == 1)
        #expect(undoManager.canUndo)

        undoManager.undo()

        #expect(canvasState.annotations.count == 0)
        #expect(undoManager.canRedo)
    }

    @Test("UndoManager can redo after undo")
    func undoManagerCanRedoAfterUndo() {
        let undoManager = AnnotationUndoManager()
        let canvasState = CanvasState()

        let annotation = Annotation(
            type: .line,
            startPoint: .zero,
            endPoint: CGPoint(x: 50, y: 50),
            strokeColor: .blue,
            strokeWidth: 1.0
        )

        undoManager.addAnnotation(annotation, to: canvasState)
        undoManager.undo()

        #expect(canvasState.annotations.count == 0)

        undoManager.redo()

        #expect(canvasState.annotations.count == 1)
        #expect(!undoManager.canRedo)
    }

    @Test("UndoManager tracks canUndo and canRedo state")
    func undoManagerTracksCanUndoAndCanRedo() {
        let undoManager = AnnotationUndoManager()
        let canvasState = CanvasState()

        #expect(!undoManager.canUndo)
        #expect(!undoManager.canRedo)

        let annotation = Annotation(
            type: .oval,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 50, y: 50),
            strokeColor: .green,
            strokeWidth: 3.0
        )

        undoManager.addAnnotation(annotation, to: canvasState)

        #expect(undoManager.canUndo)
        #expect(!undoManager.canRedo)
    }
}

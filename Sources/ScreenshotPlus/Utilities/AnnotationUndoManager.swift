import Foundation

@Observable
final class AnnotationUndoManager {
    private var undoStack: [UndoAction] = []
    private var redoStack: [UndoAction] = []
    private weak var canvasState: CanvasState?

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func addAnnotation(_ annotation: Annotation, to canvasState: CanvasState) {
        self.canvasState = canvasState
        canvasState.annotations.append(annotation)

        let action = UndoAction(
            type: .add,
            annotation: annotation
        )
        undoStack.append(action)
        redoStack.removeAll()
    }

    func undo() {
        guard let action = undoStack.popLast(),
              let canvasState = canvasState else { return }

        switch action.type {
        case .add:
            canvasState.annotations.removeAll { $0.id == action.annotation.id }
        case .remove:
            canvasState.annotations.append(action.annotation)
        }

        redoStack.append(action)
    }

    func redo() {
        guard let action = redoStack.popLast(),
              let canvasState = canvasState else { return }

        switch action.type {
        case .add:
            canvasState.annotations.append(action.annotation)
        case .remove:
            canvasState.annotations.removeAll { $0.id == action.annotation.id }
        }

        undoStack.append(action)
    }
}

private struct UndoAction {
    enum ActionType {
        case add
        case remove
    }

    let type: ActionType
    let annotation: Annotation
}

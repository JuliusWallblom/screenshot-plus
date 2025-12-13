import Foundation

/// Protocol for undoable annotation operations.
protocol AnnotationCommand {
    /// Executes the command, modifying the annotations array.
    func execute(annotations: inout [Annotation])

    /// Undoes the command, reverting the annotations array.
    func undo(annotations: inout [Annotation])
}

/// Command for adding an annotation.
struct AddAnnotationCommand: AnnotationCommand {
    let annotation: Annotation

    func execute(annotations: inout [Annotation]) {
        annotations.append(annotation)
    }

    func undo(annotations: inout [Annotation]) {
        annotations.removeAll { $0.id == annotation.id }
    }
}

/// Command for deleting an annotation.
struct DeleteAnnotationCommand: AnnotationCommand {
    let annotation: Annotation
    let index: Int

    func execute(annotations: inout [Annotation]) {
        annotations.removeAll { $0.id == annotation.id }
    }

    func undo(annotations: inout [Annotation]) {
        // Insert at original index, clamped to valid range
        let insertIndex = min(index, annotations.count)
        annotations.insert(annotation, at: insertIndex)
    }
}

/// Command for moving an annotation.
struct MoveAnnotationCommand: AnnotationCommand {
    let annotationId: UUID
    let oldStartPoint: CGPoint
    let oldEndPoint: CGPoint
    let oldPoints: [CGPoint]
    let newStartPoint: CGPoint
    let newEndPoint: CGPoint
    let newPoints: [CGPoint]

    func execute(annotations: inout [Annotation]) {
        guard let index = annotations.firstIndex(where: { $0.id == annotationId }) else { return }
        annotations[index].startPoint = newStartPoint
        annotations[index].endPoint = newEndPoint
        annotations[index].points = newPoints
    }

    func undo(annotations: inout [Annotation]) {
        guard let index = annotations.firstIndex(where: { $0.id == annotationId }) else { return }
        annotations[index].startPoint = oldStartPoint
        annotations[index].endPoint = oldEndPoint
        annotations[index].points = oldPoints
    }
}

/// Command for resizing an annotation.
struct ResizeAnnotationCommand: AnnotationCommand {
    let annotationId: UUID
    let oldStartPoint: CGPoint
    let oldEndPoint: CGPoint
    let oldPoints: [CGPoint]
    let newStartPoint: CGPoint
    let newEndPoint: CGPoint
    let newPoints: [CGPoint]

    func execute(annotations: inout [Annotation]) {
        guard let index = annotations.firstIndex(where: { $0.id == annotationId }) else { return }
        annotations[index].startPoint = newStartPoint
        annotations[index].endPoint = newEndPoint
        annotations[index].points = newPoints
    }

    func undo(annotations: inout [Annotation]) {
        guard let index = annotations.firstIndex(where: { $0.id == annotationId }) else { return }
        annotations[index].startPoint = oldStartPoint
        annotations[index].endPoint = oldEndPoint
        annotations[index].points = oldPoints
    }
}

/// Command for rotating an annotation.
struct RotateAnnotationCommand: AnnotationCommand {
    let annotationId: UUID
    let oldRotation: Double
    let newRotation: Double

    func execute(annotations: inout [Annotation]) {
        guard let index = annotations.firstIndex(where: { $0.id == annotationId }) else { return }
        annotations[index].rotation = newRotation
    }

    func undo(annotations: inout [Annotation]) {
        guard let index = annotations.firstIndex(where: { $0.id == annotationId }) else { return }
        annotations[index].rotation = oldRotation
    }
}

/// Command for editing text annotation content.
struct EditTextCommand: AnnotationCommand {
    let annotationId: UUID
    let oldText: String
    let newText: String

    func execute(annotations: inout [Annotation]) {
        guard let index = annotations.firstIndex(where: { $0.id == annotationId }) else { return }
        annotations[index].text = newText
    }

    func undo(annotations: inout [Annotation]) {
        guard let index = annotations.firstIndex(where: { $0.id == annotationId }) else { return }
        annotations[index].text = oldText
    }
}

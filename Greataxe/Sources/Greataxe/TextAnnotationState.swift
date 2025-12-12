import SwiftUI

@Observable
final class TextAnnotationState {
    var isEditing: Bool = false
    var editingText: String = ""
    var editingPosition: CGPoint = .zero

    func startEditing(at position: CGPoint) {
        isEditing = true
        editingPosition = position
        editingText = ""
    }

    func finishEditing(color: Color) -> Annotation? {
        guard isEditing, !editingText.isEmpty else {
            isEditing = false
            editingText = ""
            return nil
        }

        var annotation = Annotation(
            type: .text,
            startPoint: editingPosition,
            endPoint: editingPosition,
            strokeColor: color,
            strokeWidth: 1.0
        )
        annotation.text = editingText

        isEditing = false
        editingText = ""

        return annotation
    }

    func cancelEditing() {
        isEditing = false
        editingText = ""
    }
}

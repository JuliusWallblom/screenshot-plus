import Foundation
import SwiftUI

/// Manages the text annotation editing lifecycle.
final class TextEditingController: ObservableObject {
    enum State: Equatable {
        case idle
        case creating
        case editing
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var editingAnnotationId: UUID?
    @Published private(set) var originalText: String?
    @Published var newAnnotation: Annotation?
    @Published private(set) var screenPosition: CGPoint = .zero

    var isCreatingNew: Bool {
        state == .creating
    }

    var isEditing: Bool {
        state == .editing
    }

    var isActive: Bool {
        state != .idle
    }

    /// Starts creating a new text annotation at the given position.
    func startCreatingText(
        at position: CGPoint,
        color: Color,
        fontSize: CGFloat,
        fontName: String,
        backgroundColor: Color? = nil,
        paddingTop: CGFloat = 8,
        paddingRight: CGFloat = 8,
        paddingBottom: CGFloat = 8,
        paddingLeft: CGFloat = 8,
        cornerRadius: CGFloat = 4,
        alignment: TextAlignment = .left
    ) {
        let imagePoint = position // Caller should convert to image coords

        var annotation = Annotation(
            type: .text,
            startPoint: imagePoint,
            endPoint: imagePoint,
            strokeColor: color,
            strokeWidth: 2,
            text: "",
            fontSize: fontSize,
            fontName: fontName
        )
        annotation.textBackgroundColor = backgroundColor
        annotation.textBackgroundPaddingTop = paddingTop
        annotation.textBackgroundPaddingRight = paddingRight
        annotation.textBackgroundPaddingBottom = paddingBottom
        annotation.textBackgroundPaddingLeft = paddingLeft
        annotation.textBackgroundCornerRadius = cornerRadius
        annotation.textAlignment = alignment

        newAnnotation = annotation
        screenPosition = position
        state = .creating
    }

    /// Starts editing an existing text annotation.
    func startEditing(annotation: Annotation) {
        guard annotation.type == .text else { return }

        editingAnnotationId = annotation.id
        originalText = annotation.text
        state = .editing
    }

    /// Commits the current text edit, returning the annotation to add (for new) or nil (for edit).
    func commit() -> Annotation? {
        defer { reset() }

        switch state {
        case .creating:
            guard let annotation = newAnnotation, !annotation.text.isEmpty else {
                return nil
            }
            return annotation
        case .editing:
            // For editing, the annotation is already in the canvas - just clear state
            return nil
        case .idle:
            return nil
        }
    }

    /// Cancels the current edit, returning the original text if editing.
    func cancel() -> String? {
        let original = originalText
        reset()
        return original
    }

    /// Resets all state to idle.
    func reset() {
        state = .idle
        editingAnnotationId = nil
        originalText = nil
        newAnnotation = nil
        screenPosition = .zero
    }

    /// Checks if a click outside should dismiss the editor.
    func shouldDismissOnClick(at point: CGPoint, annotationBounds: CGRect?) -> Bool {
        guard isActive else { return false }

        if let bounds = annotationBounds {
            return !bounds.contains(point)
        }
        return true
    }
}

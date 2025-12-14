import Foundation
import Combine

final class AnnotationSelectionManager: ObservableObject {
    @Published private(set) var selectedIds: Set<UUID> = []

    func select(_ annotation: Annotation) {
        selectedIds = [annotation.id]
    }

    func addToSelection(_ annotation: Annotation) {
        selectedIds.insert(annotation.id)
    }

    func deselect(_ annotation: Annotation) {
        selectedIds.remove(annotation.id)
    }

    func clearSelection() {
        selectedIds.removeAll()
    }

    func isSelected(_ annotation: Annotation) -> Bool {
        selectedIds.contains(annotation.id)
    }

    func toggleSelection(_ annotation: Annotation) {
        if selectedIds.contains(annotation.id) {
            selectedIds.remove(annotation.id)
        } else {
            selectedIds.insert(annotation.id)
        }
    }

    func selectAll(_ annotations: [Annotation]) {
        selectedIds = Set(annotations.map(\.id))
    }

    func pruneSelection(keeping validIds: Set<UUID>) {
        selectedIds = selectedIds.intersection(validIds)
    }
}

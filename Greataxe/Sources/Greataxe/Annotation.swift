import Foundation
import SwiftUI

enum AnnotationType: Equatable {
    case rectangle
    case oval
    case line
    case arrow
    case pen
    case text
}

struct Annotation: Identifiable, Equatable {
    let id = UUID()
    var type: AnnotationType
    var startPoint: CGPoint
    var endPoint: CGPoint
    var strokeColor: Color
    var strokeWidth: CGFloat
    var points: [CGPoint] = []
    var text: String = ""

    var boundingRect: CGRect {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let maxX = max(startPoint.x, endPoint.x)
        let maxY = max(startPoint.y, endPoint.y)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    static func == (lhs: Annotation, rhs: Annotation) -> Bool {
        lhs.id == rhs.id
    }
}

enum DrawingTool: Equatable {
    case rectangle
    case oval
    case line
    case arrow
    case pen
    case text
    case crop
}

@Observable
final class CanvasState {
    var currentTool: DrawingTool = .rectangle
    var strokeColor: Color = .red
    var strokeWidth: CGFloat = 2.0
    var annotations: [Annotation] = []
    var currentAnnotation: Annotation?
}

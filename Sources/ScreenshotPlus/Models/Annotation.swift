import Foundation
import SwiftUI
import AppKit

enum AnnotationType: Equatable {
    case rectangle
    case oval
    case line
    case arrow
    case pen
    case text
}

enum TextAlignment: String, CaseIterable {
    case left
    case center
    case right
}

struct Annotation: Identifiable, Equatable {
    let id = UUID()
    var type: AnnotationType
    var startPoint: CGPoint
    var endPoint: CGPoint
    var strokeColor: Color
    var strokeWidth: CGFloat
    var isFilled: Bool = false
    var points: [CGPoint] = []
    var text: String = ""
    var fontSize: CGFloat = 16
    var fontName: String = "System"
    var rotation: Double = 0 // radians
    var textBackgroundColor: Color? = nil
    var textBackgroundPaddingTop: CGFloat = 4
    var textBackgroundPaddingRight: CGFloat = 4
    var textBackgroundPaddingBottom: CGFloat = 4
    var textBackgroundPaddingLeft: CGFloat = 4
    var textBackgroundCornerRadius: CGFloat = 4
    var textAlignment: TextAlignment = .left

    var boundingRect: CGRect {
        if type == .text {
            // Measure actual text size using NSFont (handles multi-line)
            let font: NSFont
            if fontName == "System" {
                font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
            } else {
                font = NSFont(name: fontName, size: fontSize) ?? NSFont.systemFont(ofSize: fontSize, weight: .medium)
            }
            let attributes: [NSAttributedString.Key: Any] = [.font: font]

            // Handle multi-line text
            let lines = text.components(separatedBy: "\n")
            let lineHeight = font.ascender - font.descender + font.leading
            let measuredHeight = lineHeight * CGFloat(max(lines.count, 1))
            let measuredWidth = max(
                lines.map { ($0 as NSString).size(withAttributes: attributes).width }.max() ?? 10,
                10
            )

            // Add padding if background is present
            let paddingTop: CGFloat = textBackgroundColor != nil ? textBackgroundPaddingTop : 0
            let paddingRight: CGFloat = textBackgroundColor != nil ? textBackgroundPaddingRight : 0
            let paddingBottom: CGFloat = textBackgroundColor != nil ? textBackgroundPaddingBottom : 0
            let paddingLeft: CGFloat = textBackgroundColor != nil ? textBackgroundPaddingLeft : 0

            // Adjust origin based on alignment
            let x: CGFloat
            switch textAlignment {
            case .left:
                x = startPoint.x - paddingLeft
            case .center:
                x = startPoint.x - measuredWidth / 2 - paddingLeft
            case .right:
                x = startPoint.x - measuredWidth - paddingLeft
            }
            return CGRect(
                x: x,
                y: startPoint.y - paddingTop,
                width: measuredWidth + paddingLeft + paddingRight,
                height: measuredHeight + paddingTop + paddingBottom
            )
        }
        if type == .pen && !points.isEmpty {
            // Include all points for pen annotations
            let allPoints = [startPoint] + points
            let minX = allPoints.map { $0.x }.min() ?? startPoint.x
            let minY = allPoints.map { $0.y }.min() ?? startPoint.y
            let maxX = allPoints.map { $0.x }.max() ?? startPoint.x
            let maxY = allPoints.map { $0.y }.max() ?? startPoint.y
            let strokePadding = strokeWidth
            return CGRect(
                x: minX - strokePadding,
                y: minY - strokePadding,
                width: maxX - minX + strokePadding * 2,
                height: maxY - minY + strokePadding * 2
            )
        }
        if type == .line {
            let minX = min(startPoint.x, endPoint.x)
            let minY = min(startPoint.y, endPoint.y)
            let maxX = max(startPoint.x, endPoint.x)
            let maxY = max(startPoint.y, endPoint.y)
            let strokePadding = strokeWidth
            return CGRect(
                x: minX - strokePadding,
                y: minY - strokePadding,
                width: maxX - minX + strokePadding * 2,
                height: maxY - minY + strokePadding * 2
            )
        }
        if type == .arrow && !points.isEmpty {
            // For arrows, only include start, end, and control point
            let end = points.last!
            let controlPoint = calculateArrowControlPoint()
            let relevantPoints = [startPoint, end, controlPoint]
            let minX = relevantPoints.map { $0.x }.min()!
            let minY = relevantPoints.map { $0.y }.min()!
            let maxX = relevantPoints.map { $0.x }.max()!
            let maxY = relevantPoints.map { $0.y }.max()!
            // Account for stroke width and arrowhead size
            let padding = max(strokeWidth / 2, strokeWidth * 4)
            return CGRect(
                x: minX - padding,
                y: minY - padding,
                width: maxX - minX + padding * 2,
                height: maxY - minY + padding * 2
            )
        }
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let maxX = max(startPoint.x, endPoint.x)
        let maxY = max(startPoint.y, endPoint.y)

        // For stroked shapes, expand bounds by stroke width (full width to account for rendering)
        let strokePadding = isFilled ? 0 : strokeWidth
        return CGRect(
            x: minX - strokePadding,
            y: minY - strokePadding,
            width: maxX - minX + strokePadding * 2,
            height: maxY - minY + strokePadding * 2
        )
    }

    private func calculateArrowControlPoint() -> CGPoint {
        let start = startPoint
        let end = points.last ?? endPoint
        let midPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)

        guard !points.isEmpty else { return midPoint }

        let dx = end.x - start.x
        let dy = end.y - start.y
        let lineLength = sqrt(dx * dx + dy * dy)

        guard lineLength > 0 else { return midPoint }

        var totalOffset: CGFloat = 0
        for point in points {
            let signedDistance = ((point.y - start.y) * dx - (point.x - start.x) * dy) / lineLength
            totalOffset += signedDistance
        }
        let avgOffset = totalOffset / CGFloat(points.count)

        if abs(avgOffset) < 3 { return midPoint }

        let perpX = -dy / lineLength
        let perpY = dx / lineLength

        return CGPoint(
            x: midPoint.x + perpX * avgOffset * 1.5,
            y: midPoint.y + perpY * avgOffset * 1.5
        )
    }

    static func == (lhs: Annotation, rhs: Annotation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Type-Safe Extensions

extension Annotation {
    /// Returns true for basic geometric shapes (rectangle, oval, line).
    var isShape: Bool {
        switch type {
        case .rectangle, .oval, .line:
            return true
        case .arrow, .pen, .text:
            return false
        }
    }

    /// Returns true for annotations with drawn paths (pen, arrow).
    var isDrawnPath: Bool {
        switch type {
        case .pen, .arrow:
            return true
        case .rectangle, .oval, .line, .text:
            return false
        }
    }

    /// Returns true if this text annotation has a background color set.
    var hasTextBackground: Bool {
        textBackgroundColor != nil
    }

    /// Returns true for types that support fill (rectangle, oval).
    var canBeFilled: Bool {
        switch type {
        case .rectangle, .oval:
            return true
        case .line, .arrow, .pen, .text:
            return false
        }
    }

    /// Returns true if this is a text annotation.
    var isText: Bool {
        type == .text
    }

    /// Returns true if this annotation uses the points array for its path.
    var usesPoints: Bool {
        switch type {
        case .pen, .arrow:
            return true
        case .rectangle, .oval, .line, .text:
            return false
        }
    }
}

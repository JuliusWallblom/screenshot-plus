import AppKit
import SwiftUI

enum TextAttributeBuilder {
    /// Builds NSAttributedString attributes for rendering text annotation.
    /// Includes stroke attributes when textStrokeColor is set.
    static func buildAttributes(for annotation: Annotation) -> [NSAttributedString.Key: Any] {
        let nsColor = NSColor(annotation.strokeColor)
        let font: NSFont
        if annotation.fontName == "System" {
            font = NSFont.systemFont(ofSize: annotation.fontSize, weight: .medium)
        } else {
            font = NSFont(name: annotation.fontName, size: annotation.fontSize)
                ?? NSFont.systemFont(ofSize: annotation.fontSize, weight: .medium)
        }

        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: nsColor
        ]

        // Add stroke attributes if textStrokeColor is set
        if let strokeColor = annotation.textStrokeColor {
            // Negative strokeWidth means draw both fill and stroke
            // The value represents percentage of font point size
            attributes[.strokeColor] = NSColor(strokeColor)
            attributes[.strokeWidth] = -annotation.textStrokeWidth
        }

        return attributes
    }
}

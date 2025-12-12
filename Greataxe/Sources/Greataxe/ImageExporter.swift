import AppKit
import SwiftUI

final class ImageExporter {
    func renderImage(_ baseImage: NSImage, with annotations: [Annotation]) -> NSImage? {
        let size = baseImage.size
        let image = NSImage(size: size)

        image.lockFocus()

        baseImage.draw(in: NSRect(origin: .zero, size: size))

        for annotation in annotations {
            drawAnnotation(annotation)
        }

        image.unlockFocus()

        return image
    }

    func copyToClipboard(_ image: NSImage) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.writeObjects([image])
    }

    func saveToFile(_ image: NSImage, at url: URL) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return false
        }

        do {
            try pngData.write(to: url)
            return true
        } catch {
            return false
        }
    }

    private func drawAnnotation(_ annotation: Annotation) {
        let path = NSBezierPath()
        let nsColor = NSColor(annotation.strokeColor)
        nsColor.setStroke()
        path.lineWidth = annotation.strokeWidth

        switch annotation.type {
        case .rectangle:
            path.appendRect(annotation.boundingRect)
        case .oval:
            path.appendOval(in: annotation.boundingRect)
        case .line:
            path.move(to: annotation.startPoint)
            path.line(to: annotation.endPoint)
        case .arrow:
            drawArrow(path: path, from: annotation.startPoint, to: annotation.endPoint, strokeWidth: annotation.strokeWidth)
        case .pen:
            path.move(to: annotation.startPoint)
            for point in annotation.points {
                path.line(to: point)
            }
            if annotation.points.isEmpty {
                path.line(to: annotation.endPoint)
            }
        case .text:
            drawText(annotation)
            return
        }

        path.stroke()
    }

    private func drawArrow(path: NSBezierPath, from start: CGPoint, to end: CGPoint, strokeWidth: CGFloat) {
        path.move(to: start)
        path.line(to: end)

        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength = max(10, strokeWidth * 4)
        let arrowAngle: CGFloat = .pi / 6

        let arrowPoint1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let arrowPoint2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )

        path.move(to: end)
        path.line(to: arrowPoint1)
        path.move(to: end)
        path.line(to: arrowPoint2)
    }

    private func drawText(_ annotation: Annotation) {
        let nsColor = NSColor(annotation.strokeColor)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: nsColor
        ]
        let string = NSAttributedString(string: annotation.text, attributes: attributes)
        string.draw(at: annotation.startPoint)
    }
}

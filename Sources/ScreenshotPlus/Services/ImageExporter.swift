import AppKit
import SwiftUI

final class ImageExporter {
    func renderImage(_ baseImage: NSImage, with annotations: [Annotation], paddingOptions: PaddingOptions = PaddingOptions()) -> NSImage? {
        if paddingOptions.enabled {
            return renderImageWithPadding(baseImage, annotations: annotations, options: paddingOptions)
        }

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

    private func renderImageWithPadding(_ baseImage: NSImage, annotations: [Annotation], options: PaddingOptions) -> NSImage? {
        let padding = options.amount
        let cornerRadius = options.cornerRadius
        let imageSize = baseImage.size
        let totalSize = NSSize(
            width: imageSize.width + padding * 2,
            height: imageSize.height + padding * 2
        )

        let image = NSImage(size: totalSize)
        image.lockFocus()

        // Draw gradient background
        let gradientRect = NSRect(origin: .zero, size: totalSize)
        drawGradient(in: gradientRect, gradient: options.gradient)

        // Draw image with rounded corners and shadow
        let imageRect = NSRect(
            x: padding,
            y: padding,
            width: imageSize.width,
            height: imageSize.height
        )

        // Draw image with rounded corners and optional shadow
        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()

        if options.shadow.enabled {
            context?.setShadow(
                offset: CGSize(width: 0, height: -options.shadow.offsetY),
                blur: options.shadow.radius,
                color: NSColor.black.withAlphaComponent(options.shadow.opacity).cgColor
            )
        }

        // Draw rounded rect background to cast the shadow
        let clipPath = NSBezierPath(roundedRect: imageRect, xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor.white.setFill()
        clipPath.fill()

        context?.restoreGState()

        // Now draw the actual image clipped to rounded rect
        context?.saveGState()
        clipPath.addClip()
        baseImage.draw(in: imageRect)
        context?.restoreGState()

        // Draw annotations offset by padding
        for annotation in annotations {
            drawAnnotation(annotation, offset: CGPoint(x: padding, y: padding))
        }

        image.unlockFocus()

        return image
    }

    private func drawGradient(in rect: NSRect, gradient: GradientBackground) {
        let startColor = NSColor(gradient.startColor)
        let endColor = NSColor(gradient.endColor)

        guard let nsGradient = NSGradient(starting: startColor, ending: endColor) else { return }

        let angle = gradient.angle
        nsGradient.draw(in: rect, angle: CGFloat(angle))
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

    /// Saves image to file, returning Result with URL on success or ExportError on failure.
    func saveToFileResult(_ image: NSImage, at url: URL) -> Result<URL, ExportError> {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return .failure(.imageConversionFailed)
        }

        do {
            try pngData.write(to: url)
            return .success(url)
        } catch {
            return .failure(.writeFailed(error))
        }
    }

    /// Copies image to clipboard, returning Result.
    func copyToClipboardResult(_ image: NSImage) -> Result<Void, ExportError> {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if pasteboard.writeObjects([image]) {
            return .success(())
        } else {
            return .failure(.clipboardFailed)
        }
    }

    /// Renders image with annotations, returning Result.
    func renderImageResult(_ baseImage: NSImage, with annotations: [Annotation], paddingOptions: PaddingOptions = PaddingOptions()) -> Result<NSImage, ExportError> {
        if let image = renderImage(baseImage, with: annotations, paddingOptions: paddingOptions) {
            return .success(image)
        } else {
            return .failure(.renderFailed)
        }
    }

    private func drawAnnotation(_ annotation: Annotation, offset: CGPoint = .zero) {
        // Text handles its own rotation
        if annotation.type == .text {
            drawText(annotation, offset: offset)
            return
        }

        let context = NSGraphicsContext.current?.cgContext
        let offsetRect = annotation.boundingRect.offsetBy(dx: offset.x, dy: offset.y)
        let center = CGPoint(x: offsetRect.midX, y: offsetRect.midY)

        // Apply rotation
        if annotation.rotation != 0 {
            context?.saveGState()
            context?.translateBy(x: center.x, y: center.y)
            context?.rotate(by: annotation.rotation)
            context?.translateBy(x: -center.x, y: -center.y)
        }

        let path = NSBezierPath()
        let nsColor = NSColor(annotation.strokeColor)
        nsColor.setStroke()
        path.lineWidth = annotation.strokeWidth

        let offsetStart = CGPoint(x: annotation.startPoint.x + offset.x, y: annotation.startPoint.y + offset.y)
        let offsetEnd = CGPoint(x: annotation.endPoint.x + offset.x, y: annotation.endPoint.y + offset.y)

        switch annotation.type {
        case .rectangle:
            path.appendRect(offsetRect)
        case .oval:
            path.appendOval(in: offsetRect)
        case .line:
            path.move(to: offsetStart)
            path.line(to: offsetEnd)
        case .arrow:
            drawArrow(annotation: annotation, offset: offset)
            // Arrow draws its own paths, so skip the common stroke below
            if annotation.rotation != 0 {
                context?.restoreGState()
            }
            return
        case .pen:
            path.move(to: offsetStart)
            for point in annotation.points {
                path.line(to: CGPoint(x: point.x + offset.x, y: point.y + offset.y))
            }
            if annotation.points.isEmpty {
                path.line(to: offsetEnd)
            }
        case .text:
            break // Handled above
        }

        if annotation.isFilled && (annotation.type == .rectangle || annotation.type == .oval) {
            nsColor.setFill()
            path.fill()
        } else {
            path.stroke()
        }

        if annotation.rotation != 0 {
            context?.restoreGState()
        }
    }

    private func drawArrow(annotation: Annotation, offset: CGPoint) {
        let start = CGPoint(x: annotation.startPoint.x + offset.x, y: annotation.startPoint.y + offset.y)
        let end: CGPoint
        let controlPoint: CGPoint

        if annotation.points.isEmpty {
            end = CGPoint(x: annotation.endPoint.x + offset.x, y: annotation.endPoint.y + offset.y)
            controlPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        } else {
            let lastPt = annotation.points.last!
            end = CGPoint(x: lastPt.x + offset.x, y: lastPt.y + offset.y)
            let offsetPoints = annotation.points.map { CGPoint(x: $0.x + offset.x, y: $0.y + offset.y) }
            controlPoint = calculateControlPoint(start: start, end: end, points: offsetPoints)
        }

        // Calculate arrowhead angle based on curve tangent at end
        let angle = atan2(end.y - controlPoint.y, end.x - controlPoint.x)
        let arrowLength = max(10, annotation.strokeWidth * 4)
        let arrowAngle: CGFloat = .pi / 6

        let arrowPoint1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let arrowPoint2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )

        // Shorten the line so it ends at the base of the arrowhead
        let arrowBase = CGPoint(
            x: (arrowPoint1.x + arrowPoint2.x) / 2,
            y: (arrowPoint1.y + arrowPoint2.y) / 2
        )

        let nsColor = NSColor(annotation.strokeColor)
        nsColor.setStroke()
        nsColor.setFill()

        // Draw the line (curve) ending at arrowhead base
        let linePath = NSBezierPath()
        linePath.lineWidth = annotation.strokeWidth
        linePath.move(to: start)
        linePath.curve(to: arrowBase, controlPoint1: controlPoint, controlPoint2: controlPoint)
        linePath.stroke()

        // Draw filled arrowhead triangle
        let arrowheadPath = NSBezierPath()
        arrowheadPath.move(to: end)
        arrowheadPath.line(to: arrowPoint1)
        arrowheadPath.line(to: arrowPoint2)
        arrowheadPath.close()
        arrowheadPath.fill()
    }

    private func calculateControlPoint(start: CGPoint, end: CGPoint, points: [CGPoint]) -> CGPoint {
        let midPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)

        guard !points.isEmpty else {
            return midPoint
        }

        let dx = end.x - start.x
        let dy = end.y - start.y
        let lineLength = sqrt(dx * dx + dy * dy)

        guard lineLength > 0 else {
            return midPoint
        }

        // Calculate average signed perpendicular offset from the straight line
        var totalOffset: CGFloat = 0
        for point in points {
            let signedDistance = ((point.y - start.y) * dx - (point.x - start.x) * dy) / lineLength
            totalOffset += signedDistance
        }
        let avgOffset = totalOffset / CGFloat(points.count)

        if abs(avgOffset) < 3 {
            return midPoint
        }

        let perpX = -dy / lineLength
        let perpY = dx / lineLength

        return CGPoint(
            x: midPoint.x + perpX * avgOffset * 1.5,
            y: midPoint.y + perpY * avgOffset * 1.5
        )
    }

    private func drawText(_ annotation: Annotation, offset: CGPoint = .zero) {
        let context = NSGraphicsContext.current?.cgContext

        let attributes = TextAttributeBuilder.buildAttributes(for: annotation)
        let string = NSAttributedString(string: annotation.text, attributes: attributes)
        let textSize = string.size()

        let basePoint = CGPoint(x: annotation.startPoint.x + offset.x, y: annotation.startPoint.y + offset.y)

        // Calculate draw point based on alignment
        let drawPoint: CGPoint
        switch annotation.textAlignment {
        case .left:
            drawPoint = basePoint
        case .center:
            drawPoint = CGPoint(x: basePoint.x - textSize.width / 2, y: basePoint.y)
        case .right:
            drawPoint = CGPoint(x: basePoint.x - textSize.width, y: basePoint.y)
        }

        // Calculate background rect using actual text size with individual edge padding
        let paddingTop = annotation.textBackgroundColor != nil ? annotation.textBackgroundPaddingTop : 0
        let paddingRight = annotation.textBackgroundColor != nil ? annotation.textBackgroundPaddingRight : 0
        let paddingBottom = annotation.textBackgroundColor != nil ? annotation.textBackgroundPaddingBottom : 0
        let paddingLeft = annotation.textBackgroundColor != nil ? annotation.textBackgroundPaddingLeft : 0
        let bgRect = CGRect(
            x: drawPoint.x - paddingLeft,
            y: drawPoint.y - paddingBottom,
            width: textSize.width + paddingLeft + paddingRight,
            height: textSize.height + paddingTop + paddingBottom
        )
        let center = CGPoint(x: bgRect.midX, y: bgRect.midY)

        // Apply rotation for text
        if annotation.rotation != 0 {
            context?.saveGState()
            context?.translateBy(x: center.x, y: center.y)
            context?.rotate(by: annotation.rotation)
            context?.translateBy(x: -center.x, y: -center.y)
        }

        // Draw background if set
        if let bgColor = annotation.textBackgroundColor {
            let cornerRadius = annotation.textBackgroundCornerRadius
            let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)
            NSColor(bgColor).setFill()
            bgPath.fill()
        }

        string.draw(at: drawPoint)

        if annotation.rotation != 0 {
            context?.restoreGState()
        }
    }
}

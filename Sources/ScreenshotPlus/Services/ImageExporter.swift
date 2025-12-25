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

        // Draw annotations with Y-coordinate flipping
        // SwiftUI uses Y=0 at top, NSImage lockFocus uses Y=0 at bottom
        for annotation in annotations {
            drawAnnotation(annotation, imageHeight: size.height)
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

        // Draw annotations offset by padding with Y-coordinate flipping
        // SwiftUI uses Y=0 at top, NSImage lockFocus uses Y=0 at bottom
        for annotation in annotations {
            drawAnnotation(annotation, offset: CGPoint(x: padding, y: padding), imageHeight: totalSize.height)
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

    /// Flips a Y coordinate from SwiftUI's coordinate system (Y=0 at top) to
    /// NSImage's coordinate system (Y=0 at bottom)
    private func flipY(_ y: CGFloat, imageHeight: CGFloat) -> CGFloat {
        return imageHeight - y
    }

    /// Flips a point's Y coordinate
    private func flipPoint(_ point: CGPoint, imageHeight: CGFloat) -> CGPoint {
        return CGPoint(x: point.x, y: flipY(point.y, imageHeight: imageHeight))
    }

    /// Flips a rect's Y coordinate (accounting for rect height)
    private func flipRect(_ rect: CGRect, imageHeight: CGFloat) -> CGRect {
        return CGRect(
            x: rect.origin.x,
            y: imageHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    private func drawAnnotation(_ annotation: Annotation, offset: CGPoint = .zero, imageHeight: CGFloat) {
        // Text handles its own rotation
        if annotation.type == .text {
            drawText(annotation, offset: offset, imageHeight: imageHeight)
            return
        }

        let context = NSGraphicsContext.current?.cgContext

        // Apply offset to bounding rect, then flip Y
        let offsetRect = annotation.boundingRect.offsetBy(dx: offset.x, dy: offset.y)
        let flippedRect = flipRect(offsetRect, imageHeight: imageHeight)
        let center = CGPoint(x: flippedRect.midX, y: flippedRect.midY)

        // Apply rotation (note: rotation direction needs to be inverted for flipped coords)
        if annotation.rotation != 0 {
            context?.saveGState()
            context?.translateBy(x: center.x, y: center.y)
            context?.rotate(by: -annotation.rotation) // Invert rotation for flipped Y
            context?.translateBy(x: -center.x, y: -center.y)
        }

        let path = NSBezierPath()
        let nsColor = NSColor(annotation.strokeColor)
        nsColor.setStroke()
        path.lineWidth = annotation.strokeWidth

        // Flip start and end points
        let offsetStart = CGPoint(x: annotation.startPoint.x + offset.x, y: annotation.startPoint.y + offset.y)
        let offsetEnd = CGPoint(x: annotation.endPoint.x + offset.x, y: annotation.endPoint.y + offset.y)
        let flippedStart = flipPoint(offsetStart, imageHeight: imageHeight)
        let flippedEnd = flipPoint(offsetEnd, imageHeight: imageHeight)

        switch annotation.type {
        case .rectangle:
            path.appendRect(flippedRect)
        case .oval:
            path.appendOval(in: flippedRect)
        case .line:
            path.move(to: flippedStart)
            path.line(to: flippedEnd)
        case .arrow:
            drawArrow(annotation: annotation, offset: offset, imageHeight: imageHeight)
            // Arrow draws its own paths, so skip the common stroke below
            if annotation.rotation != 0 {
                context?.restoreGState()
            }
            return
        case .pen:
            path.move(to: flippedStart)
            for point in annotation.points {
                let offsetPoint = CGPoint(x: point.x + offset.x, y: point.y + offset.y)
                path.line(to: flipPoint(offsetPoint, imageHeight: imageHeight))
            }
            if annotation.points.isEmpty {
                path.line(to: flippedEnd)
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

    private func drawArrow(annotation: Annotation, offset: CGPoint, imageHeight: CGFloat) {
        let offsetStart = CGPoint(x: annotation.startPoint.x + offset.x, y: annotation.startPoint.y + offset.y)
        let start = flipPoint(offsetStart, imageHeight: imageHeight)

        let end: CGPoint
        let controlPoint: CGPoint

        if annotation.points.isEmpty {
            let offsetEnd = CGPoint(x: annotation.endPoint.x + offset.x, y: annotation.endPoint.y + offset.y)
            end = flipPoint(offsetEnd, imageHeight: imageHeight)
            controlPoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        } else {
            let lastPt = annotation.points.last!
            let offsetEnd = CGPoint(x: lastPt.x + offset.x, y: lastPt.y + offset.y)
            end = flipPoint(offsetEnd, imageHeight: imageHeight)
            let flippedPoints = annotation.points.map { pt in
                flipPoint(CGPoint(x: pt.x + offset.x, y: pt.y + offset.y), imageHeight: imageHeight)
            }
            controlPoint = calculateControlPoint(start: start, end: end, points: flippedPoints)
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

    private func drawText(_ annotation: Annotation, offset: CGPoint = .zero, imageHeight: CGFloat) {
        let context = NSGraphicsContext.current?.cgContext

        let nsColor = NSColor(annotation.strokeColor)
        let font: NSFont
        if annotation.fontName == "System" {
            font = NSFont.systemFont(ofSize: annotation.fontSize, weight: .medium)
        } else {
            font = NSFont(name: annotation.fontName, size: annotation.fontSize) ?? NSFont.systemFont(ofSize: annotation.fontSize, weight: .medium)
        }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: nsColor
        ]
        let string = NSAttributedString(string: annotation.text, attributes: attributes)
        let textSize = string.size()

        let basePoint = CGPoint(x: annotation.startPoint.x + offset.x, y: annotation.startPoint.y + offset.y)

        // Calculate draw point based on alignment (in SwiftUI coordinates)
        let alignedPoint: CGPoint
        switch annotation.textAlignment {
        case .left:
            alignedPoint = basePoint
        case .center:
            alignedPoint = CGPoint(x: basePoint.x - textSize.width / 2, y: basePoint.y)
        case .right:
            alignedPoint = CGPoint(x: basePoint.x - textSize.width, y: basePoint.y)
        }

        // Calculate background rect using actual text size with individual edge padding (in SwiftUI coords)
        let paddingTop = annotation.textBackgroundColor != nil ? annotation.textBackgroundPaddingTop : 0
        let paddingRight = annotation.textBackgroundColor != nil ? annotation.textBackgroundPaddingRight : 0
        let paddingBottom = annotation.textBackgroundColor != nil ? annotation.textBackgroundPaddingBottom : 0
        let paddingLeft = annotation.textBackgroundColor != nil ? annotation.textBackgroundPaddingLeft : 0

        // In SwiftUI coords: bgRect top-left is at (alignedPoint.x - paddingLeft, alignedPoint.y - paddingTop)
        let bgRectSwiftUI = CGRect(
            x: alignedPoint.x - paddingLeft,
            y: alignedPoint.y - paddingTop,
            width: textSize.width + paddingLeft + paddingRight,
            height: textSize.height + paddingTop + paddingBottom
        )

        // Flip the background rect
        let bgRect = flipRect(bgRectSwiftUI, imageHeight: imageHeight)
        let center = CGPoint(x: bgRect.midX, y: bgRect.midY)

        // Flip the draw point - in NSImage coords, text draws from bottom-left of text bounds
        // So we need to position at the flipped Y minus the text height (since text draws upward)
        let flippedDrawPoint = CGPoint(
            x: alignedPoint.x,
            y: flipY(alignedPoint.y + textSize.height, imageHeight: imageHeight)
        )

        // Apply rotation for text (inverted for flipped Y)
        if annotation.rotation != 0 {
            context?.saveGState()
            context?.translateBy(x: center.x, y: center.y)
            context?.rotate(by: -annotation.rotation)
            context?.translateBy(x: -center.x, y: -center.y)
        }

        // Draw background if set
        if let bgColor = annotation.textBackgroundColor {
            let cornerRadius = annotation.textBackgroundCornerRadius
            let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)
            NSColor(bgColor).setFill()
            bgPath.fill()
        }

        string.draw(at: flippedDrawPoint)

        if annotation.rotation != 0 {
            context?.restoreGState()
        }
    }
}

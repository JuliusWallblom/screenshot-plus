import AppKit
import SwiftUI

@Observable
final class CropState {
    var isActive: Bool = false
    var cropRect: CGRect = .zero
    private var startPoint: CGPoint = .zero

    func startCrop(at point: CGPoint) {
        isActive = true
        startPoint = point
        cropRect = CGRect(origin: point, size: .zero)
    }

    func updateCrop(to point: CGPoint) {
        let minX = min(startPoint.x, point.x)
        let minY = min(startPoint.y, point.y)
        let maxX = max(startPoint.x, point.x)
        let maxY = max(startPoint.y, point.y)

        cropRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    func applyCrop(to image: NSImage) -> NSImage? {
        guard isActive, cropRect.width > 0, cropRect.height > 0 else { return nil }

        let croppedSize = cropRect.size
        let croppedImage = NSImage(size: croppedSize)

        croppedImage.lockFocus()

        let destRect = NSRect(origin: .zero, size: croppedSize)
        let sourceRect = NSRect(
            x: cropRect.origin.x,
            y: image.size.height - cropRect.origin.y - cropRect.height,
            width: cropRect.width,
            height: cropRect.height
        )

        image.draw(in: destRect, from: sourceRect, operation: .copy, fraction: 1.0)

        croppedImage.unlockFocus()

        isActive = false
        cropRect = .zero

        return croppedImage
    }

    func cancelCrop() {
        isActive = false
        cropRect = .zero
        startPoint = .zero
    }
}

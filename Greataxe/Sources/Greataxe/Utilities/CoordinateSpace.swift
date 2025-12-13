import Foundation

struct CoordinateSpace {
    let imageSize: CGSize
    let screenRect: CGRect

    var scale: CGFloat {
        guard imageSize.width > 0 else { return 1 }
        return screenRect.width / imageSize.width
    }

    func screenToImage(_ point: CGPoint) -> CGPoint {
        guard imageSize.width > 0, screenRect.width > 0 else { return point }
        let scale = imageSize.width / screenRect.width
        return CGPoint(
            x: (point.x - screenRect.minX) * scale,
            y: (point.y - screenRect.minY) * scale
        )
    }

    func imageToScreen(_ point: CGPoint) -> CGPoint {
        guard imageSize.width > 0, screenRect.width > 0 else { return point }
        let scale = screenRect.width / imageSize.width
        return CGPoint(
            x: point.x * scale + screenRect.minX,
            y: point.y * scale + screenRect.minY
        )
    }
}

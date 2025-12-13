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

enum DrawingTool: String, Equatable {
    case select
    case rectangle
    case oval
    case line
    case arrow
    case pen
    case text
    case crop
}

struct GradientBackground: Equatable {
    var startColor: Color = .purple
    var endColor: Color = .blue
    var angle: Double = 45 // degrees
}

struct ShadowOptions: Equatable {
    var enabled: Bool = true
    var radius: CGFloat = 20
    var opacity: CGFloat = 0.3
    var offsetY: CGFloat = 10
}

struct PaddingOptions: Equatable {
    var enabled: Bool = false
    var amount: CGFloat = 40
    var cornerRadius: CGFloat = 12
    var gradient: GradientBackground = GradientBackground()
    var shadow: ShadowOptions = ShadowOptions()
}

final class CanvasState: ObservableObject {
    @Published var currentTool: DrawingTool = .rectangle {
        didSet { saveSettings() }
    }
    @Published var strokeColor: Color = .red {
        didSet { saveSettings() }
    }
    @Published var strokeWidth: CGFloat = 2.0 {
        didSet { saveSettings() }
    }
    @Published var fillShapes: Bool = false {
        didSet { saveSettings() }
    }
    @Published var textBackgroundColor: Color? = nil {
        didSet { saveSettings() }
    }
    @Published var textBackgroundPaddingTop: CGFloat = 4 {
        didSet { saveSettings() }
    }
    @Published var textBackgroundPaddingRight: CGFloat = 4 {
        didSet { saveSettings() }
    }
    @Published var textBackgroundPaddingBottom: CGFloat = 4 {
        didSet { saveSettings() }
    }
    @Published var textBackgroundPaddingLeft: CGFloat = 4 {
        didSet { saveSettings() }
    }
    @Published var textBackgroundCornerRadius: CGFloat = 4 {
        didSet { saveSettings() }
    }
    @Published var textAlignment: TextAlignment = .left {
        didSet { saveSettings() }
    }
    @Published var textFontSize: CGFloat = 16 {
        didSet { saveSettings() }
    }
    @Published var textFontName: String = "System" {
        didSet { saveSettings() }
    }
    @Published var annotations: [Annotation] = []
    @Published var currentAnnotation: Annotation?
    @Published var selectedAnnotationIds: Set<UUID> = []
    @Published var imageSize: CGSize = .zero
    @Published var paddingOptions: PaddingOptions = PaddingOptions() {
        didSet { saveSettings() }
    }
    @Published var showPaddingPanel: Bool = false {
        didSet { saveSettings() }
    }

    private var undoStack: [[Annotation]] = []
    private var redoStack: [[Annotation]] = []
    private var isLoadingSettings = false

    init() {
        loadSettings()
    }

    private func saveSettings() {
        guard !isLoadingSettings else { return }
        let defaults = UserDefaults.standard

        // Save stroke color as RGB components
        if let nsColor = NSColor(strokeColor).usingColorSpace(.deviceRGB) {
            defaults.set(Double(nsColor.redComponent), forKey: "strokeColorR")
            defaults.set(Double(nsColor.greenComponent), forKey: "strokeColorG")
            defaults.set(Double(nsColor.blueComponent), forKey: "strokeColorB")
        }

        defaults.set(Double(strokeWidth), forKey: "strokeWidth")
        defaults.set(fillShapes, forKey: "fillShapes")
        defaults.set(currentTool.rawValue, forKey: "currentTool")
        defaults.set(showPaddingPanel, forKey: "showPaddingPanel")
        defaults.set(textAlignment.rawValue, forKey: "textAlignment")

        // Save text background color
        if let bgColor = textBackgroundColor, let nsColor = NSColor(bgColor).usingColorSpace(.deviceRGB) {
            defaults.set(true, forKey: "textBackgroundEnabled")
            defaults.set(Double(nsColor.redComponent), forKey: "textBackgroundR")
            defaults.set(Double(nsColor.greenComponent), forKey: "textBackgroundG")
            defaults.set(Double(nsColor.blueComponent), forKey: "textBackgroundB")
            defaults.set(Double(nsColor.alphaComponent), forKey: "textBackgroundA")
        } else {
            defaults.set(false, forKey: "textBackgroundEnabled")
        }
        defaults.set(Double(textBackgroundPaddingTop), forKey: "textBackgroundPaddingTop")
        defaults.set(Double(textBackgroundPaddingRight), forKey: "textBackgroundPaddingRight")
        defaults.set(Double(textBackgroundPaddingBottom), forKey: "textBackgroundPaddingBottom")
        defaults.set(Double(textBackgroundPaddingLeft), forKey: "textBackgroundPaddingLeft")
        defaults.set(Double(textBackgroundCornerRadius), forKey: "textBackgroundCornerRadius")
        defaults.set(Double(textFontSize), forKey: "textFontSize")
        defaults.set(textFontName, forKey: "textFontName")

        // Save padding options
        defaults.set(paddingOptions.enabled, forKey: "paddingEnabled")
        defaults.set(Double(paddingOptions.amount), forKey: "paddingAmount")
        defaults.set(Double(paddingOptions.cornerRadius), forKey: "paddingCornerRadius")

        // Save gradient
        if let startColor = NSColor(paddingOptions.gradient.startColor).usingColorSpace(.deviceRGB) {
            defaults.set(Double(startColor.redComponent), forKey: "gradientStartR")
            defaults.set(Double(startColor.greenComponent), forKey: "gradientStartG")
            defaults.set(Double(startColor.blueComponent), forKey: "gradientStartB")
        }
        if let endColor = NSColor(paddingOptions.gradient.endColor).usingColorSpace(.deviceRGB) {
            defaults.set(Double(endColor.redComponent), forKey: "gradientEndR")
            defaults.set(Double(endColor.greenComponent), forKey: "gradientEndG")
            defaults.set(Double(endColor.blueComponent), forKey: "gradientEndB")
        }
        defaults.set(paddingOptions.gradient.angle, forKey: "gradientAngle")

        // Save shadow
        defaults.set(paddingOptions.shadow.enabled, forKey: "shadowEnabled")
        defaults.set(Double(paddingOptions.shadow.radius), forKey: "shadowRadius")
        defaults.set(Double(paddingOptions.shadow.opacity), forKey: "shadowOpacity")
        defaults.set(Double(paddingOptions.shadow.offsetY), forKey: "shadowOffsetY")
    }

    private func loadSettings() {
        isLoadingSettings = true
        let defaults = UserDefaults.standard

        // Load stroke color
        if defaults.object(forKey: "strokeColorR") != nil {
            let r = defaults.double(forKey: "strokeColorR")
            let g = defaults.double(forKey: "strokeColorG")
            let b = defaults.double(forKey: "strokeColorB")
            strokeColor = Color(red: r, green: g, blue: b)
        }

        if defaults.object(forKey: "strokeWidth") != nil {
            strokeWidth = CGFloat(defaults.double(forKey: "strokeWidth"))
        }

        if defaults.object(forKey: "fillShapes") != nil {
            fillShapes = defaults.bool(forKey: "fillShapes")
        }

        if let toolStr = defaults.string(forKey: "currentTool"),
           let tool = DrawingTool(rawValue: toolStr) {
            currentTool = tool
        }

        if defaults.object(forKey: "showPaddingPanel") != nil {
            showPaddingPanel = defaults.bool(forKey: "showPaddingPanel")
        }

        if let alignmentStr = defaults.string(forKey: "textAlignment"),
           let alignment = TextAlignment(rawValue: alignmentStr) {
            textAlignment = alignment
        }

        if defaults.bool(forKey: "textBackgroundEnabled") {
            let r = defaults.double(forKey: "textBackgroundR")
            let g = defaults.double(forKey: "textBackgroundG")
            let b = defaults.double(forKey: "textBackgroundB")
            let a = defaults.object(forKey: "textBackgroundA") != nil ? defaults.double(forKey: "textBackgroundA") : 1.0
            textBackgroundColor = Color(red: r, green: g, blue: b, opacity: a)
        }
        if defaults.object(forKey: "textBackgroundPaddingTop") != nil {
            textBackgroundPaddingTop = CGFloat(defaults.double(forKey: "textBackgroundPaddingTop"))
        }
        if defaults.object(forKey: "textBackgroundPaddingRight") != nil {
            textBackgroundPaddingRight = CGFloat(defaults.double(forKey: "textBackgroundPaddingRight"))
        }
        if defaults.object(forKey: "textBackgroundPaddingBottom") != nil {
            textBackgroundPaddingBottom = CGFloat(defaults.double(forKey: "textBackgroundPaddingBottom"))
        }
        if defaults.object(forKey: "textBackgroundPaddingLeft") != nil {
            textBackgroundPaddingLeft = CGFloat(defaults.double(forKey: "textBackgroundPaddingLeft"))
        }
        if defaults.object(forKey: "textBackgroundCornerRadius") != nil {
            textBackgroundCornerRadius = CGFloat(defaults.double(forKey: "textBackgroundCornerRadius"))
        }
        if defaults.object(forKey: "textFontSize") != nil {
            textFontSize = CGFloat(defaults.double(forKey: "textFontSize"))
        }
        if let fontName = defaults.string(forKey: "textFontName") {
            textFontName = fontName
        }

        // Load padding options
        if defaults.object(forKey: "paddingEnabled") != nil {
            paddingOptions.enabled = defaults.bool(forKey: "paddingEnabled")
        }
        if defaults.object(forKey: "paddingAmount") != nil {
            paddingOptions.amount = CGFloat(defaults.double(forKey: "paddingAmount"))
        }
        if defaults.object(forKey: "paddingCornerRadius") != nil {
            paddingOptions.cornerRadius = CGFloat(defaults.double(forKey: "paddingCornerRadius"))
        }

        // Load gradient
        if defaults.object(forKey: "gradientStartR") != nil {
            let r = defaults.double(forKey: "gradientStartR")
            let g = defaults.double(forKey: "gradientStartG")
            let b = defaults.double(forKey: "gradientStartB")
            paddingOptions.gradient.startColor = Color(red: r, green: g, blue: b)
        }
        if defaults.object(forKey: "gradientEndR") != nil {
            let r = defaults.double(forKey: "gradientEndR")
            let g = defaults.double(forKey: "gradientEndG")
            let b = defaults.double(forKey: "gradientEndB")
            paddingOptions.gradient.endColor = Color(red: r, green: g, blue: b)
        }
        if defaults.object(forKey: "gradientAngle") != nil {
            paddingOptions.gradient.angle = defaults.double(forKey: "gradientAngle")
        }

        // Load shadow
        if defaults.object(forKey: "shadowEnabled") != nil {
            paddingOptions.shadow.enabled = defaults.bool(forKey: "shadowEnabled")
        }
        if defaults.object(forKey: "shadowRadius") != nil {
            paddingOptions.shadow.radius = CGFloat(defaults.double(forKey: "shadowRadius"))
        }
        if defaults.object(forKey: "shadowOpacity") != nil {
            paddingOptions.shadow.opacity = CGFloat(defaults.double(forKey: "shadowOpacity"))
        }
        if defaults.object(forKey: "shadowOffsetY") != nil {
            paddingOptions.shadow.offsetY = CGFloat(defaults.double(forKey: "shadowOffsetY"))
        }

        isLoadingSettings = false
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    var selectedAnnotations: [Annotation] {
        annotations.filter { selectedAnnotationIds.contains($0.id) }
    }

    var selectedAnnotation: Annotation? {
        guard selectedAnnotationIds.count == 1,
              let id = selectedAnnotationIds.first else { return nil }
        return annotations.first { $0.id == id }
    }

    func isSelected(_ annotation: Annotation) -> Bool {
        selectedAnnotationIds.contains(annotation.id)
    }

    func updateSelectedAnnotations(_ transform: (inout Annotation) -> Void) {
        for id in selectedAnnotationIds {
            if let index = annotations.firstIndex(where: { $0.id == id }) {
                transform(&annotations[index])
            }
        }
    }

    func saveState() {
        undoStack.append(annotations)
        redoStack.removeAll()
        // Limit undo stack size
        if undoStack.count > 50 {
            undoStack.removeFirst()
        }
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(annotations)
        annotations = previous
        // Keep selection only for annotations that still exist
        selectedAnnotationIds = selectedAnnotationIds.filter { id in
            annotations.contains { $0.id == id }
        }
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(annotations)
        annotations = next
        // Keep selection only for annotations that still exist
        selectedAnnotationIds = selectedAnnotationIds.filter { id in
            annotations.contains { $0.id == id }
        }
    }
}

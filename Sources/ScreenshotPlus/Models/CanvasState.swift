import Foundation
import SwiftUI
import AppKit

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

    /// Selects the annotation and updates the current tool and design settings to match.
    func selectAnnotation(_ annotation: Annotation) {
        selectedAnnotationIds = [annotation.id]
        currentTool = annotation.type.correspondingTool
        strokeColor = annotation.strokeColor
        strokeWidth = annotation.strokeWidth
        fillShapes = annotation.isFilled

        // Sync text-specific settings for text annotations
        if annotation.type == .text {
            textFontSize = annotation.fontSize
            textFontName = annotation.fontName
            textAlignment = annotation.textAlignment
            textBackgroundColor = annotation.textBackgroundColor
            textBackgroundPaddingTop = annotation.textBackgroundPaddingTop
            textBackgroundPaddingRight = annotation.textBackgroundPaddingRight
            textBackgroundPaddingBottom = annotation.textBackgroundPaddingBottom
            textBackgroundPaddingLeft = annotation.textBackgroundPaddingLeft
            textBackgroundCornerRadius = annotation.textBackgroundCornerRadius
        }
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

    // MARK: - AppSettings Integration

    /// Exports current canvas settings to an AppSettings instance.
    func exportSettings() -> AppSettings {
        var settings = AppSettings()

        // Stroke settings
        settings.strokeColor = strokeColor
        settings.strokeWidth = strokeWidth
        settings.fillShapes = fillShapes

        // Tool settings
        settings.currentTool = currentTool
        settings.showPaddingPanel = showPaddingPanel

        // Text settings
        settings.textAlignment = textAlignment
        settings.textFontSize = textFontSize
        settings.textFontName = textFontName
        settings.textBackgroundColor = textBackgroundColor
        settings.textBackgroundPaddingTop = textBackgroundPaddingTop
        settings.textBackgroundPaddingRight = textBackgroundPaddingRight
        settings.textBackgroundPaddingBottom = textBackgroundPaddingBottom
        settings.textBackgroundPaddingLeft = textBackgroundPaddingLeft
        settings.textBackgroundCornerRadius = textBackgroundCornerRadius

        // Padding options
        settings.paddingEnabled = paddingOptions.enabled
        settings.paddingAmount = paddingOptions.amount
        settings.paddingCornerRadius = paddingOptions.cornerRadius
        settings.gradientStartColor = paddingOptions.gradient.startColor
        settings.gradientEndColor = paddingOptions.gradient.endColor
        settings.gradientAngle = paddingOptions.gradient.angle
        settings.shadowEnabled = paddingOptions.shadow.enabled
        settings.shadowRadius = paddingOptions.shadow.radius
        settings.shadowOpacity = paddingOptions.shadow.opacity
        settings.shadowOffsetY = paddingOptions.shadow.offsetY

        return settings
    }

    /// Imports settings from an AppSettings instance.
    func importSettings(_ settings: AppSettings) {
        isLoadingSettings = true

        // Stroke settings
        strokeColor = settings.strokeColor
        strokeWidth = settings.strokeWidth
        fillShapes = settings.fillShapes

        // Tool settings
        currentTool = settings.currentTool
        showPaddingPanel = settings.showPaddingPanel

        // Text settings
        textAlignment = settings.textAlignment
        textFontSize = settings.textFontSize
        textFontName = settings.textFontName
        textBackgroundColor = settings.textBackgroundColor
        textBackgroundPaddingTop = settings.textBackgroundPaddingTop
        textBackgroundPaddingRight = settings.textBackgroundPaddingRight
        textBackgroundPaddingBottom = settings.textBackgroundPaddingBottom
        textBackgroundPaddingLeft = settings.textBackgroundPaddingLeft
        textBackgroundCornerRadius = settings.textBackgroundCornerRadius

        // Padding options
        paddingOptions.enabled = settings.paddingEnabled
        paddingOptions.amount = settings.paddingAmount
        paddingOptions.cornerRadius = settings.paddingCornerRadius
        paddingOptions.gradient.startColor = settings.gradientStartColor
        paddingOptions.gradient.endColor = settings.gradientEndColor
        paddingOptions.gradient.angle = settings.gradientAngle
        paddingOptions.shadow.enabled = settings.shadowEnabled
        paddingOptions.shadow.radius = settings.shadowRadius
        paddingOptions.shadow.opacity = settings.shadowOpacity
        paddingOptions.shadow.offsetY = settings.shadowOffsetY

        isLoadingSettings = false
    }
}

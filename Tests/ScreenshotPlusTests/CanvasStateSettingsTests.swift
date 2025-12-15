import Testing
import SwiftUI
@testable import Screenshot_

@Suite("CanvasState Settings Integration Tests")
struct CanvasStateSettingsTests {
    @Test("CanvasState can export settings to AppSettings")
    func canExportToAppSettings() {
        let canvasState = CanvasState()
        canvasState.strokeWidth = 5.0
        canvasState.fillShapes = true
        canvasState.currentTool = .oval

        let settings = canvasState.exportSettings()

        #expect(settings.strokeWidth == 5.0)
        #expect(settings.fillShapes == true)
        #expect(settings.currentTool == .oval)
    }

    @Test("CanvasState can import settings from AppSettings")
    func canImportFromAppSettings() {
        var settings = AppSettings()
        settings.strokeWidth = 8.0
        settings.fillShapes = true
        settings.currentTool = .arrow
        settings.textFontSize = 24.0

        let canvasState = CanvasState()
        canvasState.importSettings(settings)

        #expect(canvasState.strokeWidth == 8.0)
        #expect(canvasState.fillShapes == true)
        #expect(canvasState.currentTool == .arrow)
        #expect(canvasState.textFontSize == 24.0)
    }

    @Test("Selecting annotation updates currentTool to match annotation type")
    func selectAnnotationUpdatesCurrentTool() {
        let canvasState = CanvasState()
        canvasState.currentTool = .pen

        let rectangleAnnotation = Annotation(
            type: .rectangle,
            startPoint: .zero,
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .red,
            strokeWidth: 2
        )
        canvasState.annotations.append(rectangleAnnotation)

        canvasState.selectAnnotation(rectangleAnnotation)

        #expect(canvasState.selectedAnnotationIds.contains(rectangleAnnotation.id))
        #expect(canvasState.currentTool == .rectangle)
    }

    @Test("Selecting annotation updates design settings to match annotation")
    func selectAnnotationUpdatesDesignSettings() {
        let canvasState = CanvasState()
        canvasState.strokeColor = .blue
        canvasState.strokeWidth = 2.0
        canvasState.fillShapes = false

        var annotation = Annotation(
            type: .rectangle,
            startPoint: .zero,
            endPoint: CGPoint(x: 100, y: 100),
            strokeColor: .red,
            strokeWidth: 4.0
        )
        annotation.isFilled = true
        canvasState.annotations.append(annotation)

        canvasState.selectAnnotation(annotation)

        #expect(canvasState.strokeColor == .red)
        #expect(canvasState.strokeWidth == 4.0)
        #expect(canvasState.fillShapes == true)
    }

    @Test("Selecting text annotation updates text-specific settings")
    func selectTextAnnotationUpdatesTextSettings() {
        let canvasState = CanvasState()
        canvasState.textFontSize = 16
        canvasState.textFontName = "System"
        canvasState.textAlignment = .left
        canvasState.textBackgroundColor = nil

        var textAnnotation = Annotation(
            type: .text,
            startPoint: .zero,
            endPoint: .zero,
            strokeColor: .red,
            strokeWidth: 2
        )
        textAnnotation.fontSize = 24
        textAnnotation.fontName = "Helvetica"
        textAnnotation.textAlignment = .center
        textAnnotation.textBackgroundColor = .yellow
        canvasState.annotations.append(textAnnotation)

        canvasState.selectAnnotation(textAnnotation)

        #expect(canvasState.textFontSize == 24)
        #expect(canvasState.textFontName == "Helvetica")
        #expect(canvasState.textAlignment == .center)
        #expect(canvasState.textBackgroundColor == .yellow)
    }

    @Test("CanvasState has text stroke properties")
    func canvasStateHasTextStrokeProperties() {
        let canvasState = CanvasState()

        // Default values
        #expect(canvasState.textStrokeColor == nil)
        #expect(canvasState.textStrokeWidth == 1.0)

        // Set stroke properties
        canvasState.textStrokeColor = .red
        canvasState.textStrokeWidth = 2.0

        #expect(canvasState.textStrokeColor == .red)
        #expect(canvasState.textStrokeWidth == 2.0)
    }

    @Test("Selecting text annotation syncs text stroke settings")
    func selectTextAnnotationSyncsTextStrokeSettings() {
        let canvasState = CanvasState()
        canvasState.textStrokeColor = nil
        canvasState.textStrokeWidth = 1.0

        var textAnnotation = Annotation(
            type: .text,
            startPoint: .zero,
            endPoint: .zero,
            strokeColor: .black,
            strokeWidth: 1
        )
        textAnnotation.textStrokeColor = .blue
        textAnnotation.textStrokeWidth = 3.0
        canvasState.annotations.append(textAnnotation)

        canvasState.selectAnnotation(textAnnotation)

        #expect(canvasState.textStrokeColor == .blue)
        #expect(canvasState.textStrokeWidth == 3.0)
    }
}

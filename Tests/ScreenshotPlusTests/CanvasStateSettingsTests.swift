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
}

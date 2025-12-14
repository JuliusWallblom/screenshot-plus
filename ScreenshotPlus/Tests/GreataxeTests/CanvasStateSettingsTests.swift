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
}

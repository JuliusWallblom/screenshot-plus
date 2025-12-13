import Testing
import SwiftUI
@testable import Preview_

@Suite("AppSettings Tests")
struct AppSettingsTests {
    @Test("AppSettings can be instantiated with defaults")
    func canBeInstantiatedWithDefaults() {
        let settings = AppSettings()

        #expect(settings.strokeWidth == 2.0)
        #expect(settings.fillShapes == false)
        #expect(settings.currentTool == .rectangle)
    }

    @Test("AppSettings encodes and decodes correctly")
    func encodesAndDecodesCorrectly() throws {
        var settings = AppSettings()
        settings.strokeWidth = 5.0
        settings.fillShapes = true
        settings.currentTool = .oval
        settings.textFontSize = 24.0

        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppSettings.self, from: data)

        #expect(decoded.strokeWidth == 5.0)
        #expect(decoded.fillShapes == true)
        #expect(decoded.currentTool == .oval)
        #expect(decoded.textFontSize == 24.0)
    }

    @Test("AppSettings saves and loads from UserDefaults")
    func savesAndLoadsFromUserDefaults() throws {
        // Use a separate suite for testing
        let suiteName = "com.greataxe.test.\(UUID().uuidString)"
        guard let suite = UserDefaults(suiteName: suiteName) else {
            Issue.record("Could not create test UserDefaults suite")
            return
        }

        var settings = AppSettings()
        settings.strokeWidth = 8.0
        settings.currentTool = .arrow

        try settings.save(to: suite)

        let loaded = try AppSettings.load(from: suite)
        #expect(loaded.strokeWidth == 8.0)
        #expect(loaded.currentTool == .arrow)

        // Cleanup
        suite.removePersistentDomain(forName: suiteName)
    }
}

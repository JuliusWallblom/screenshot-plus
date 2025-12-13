import Testing
import Foundation
@testable import Preview_

@Suite("Screenshot Monitor Tests")
struct ScreenshotMonitorTests {
    @Test("Detects new screenshot file in watched directory")
    func detectsNewScreenshotFile() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let monitor = ScreenshotMonitor(watchDirectory: tempDir)
        var detectedFiles: [URL] = []

        monitor.onScreenshotDetected = { url in
            detectedFiles.append(url)
        }

        monitor.startMonitoring()

        let screenshotPath = tempDir.appendingPathComponent("Screenshot 2024-01-01 at 10.00.00.png")
        FileManager.default.createFile(atPath: screenshotPath.path, contents: Data(), attributes: nil)

        try await Task.sleep(for: .milliseconds(500))

        monitor.stopMonitoring()

        #expect(detectedFiles.count == 1)
        #expect(detectedFiles.first?.lastPathComponent == "Screenshot 2024-01-01 at 10.00.00.png")
    }
}

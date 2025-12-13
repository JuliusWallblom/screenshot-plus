import Foundation

final class ScreenshotMonitor {
    private let watchDirectory: URL
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var knownFiles: Set<String> = []

    /// Files saved by the app that should be ignored when detected
    private var ignoredFiles: Set<String> = []

    var onScreenshotDetected: ((URL) -> Void)?

    init(watchDirectory: URL) {
        self.watchDirectory = watchDirectory
    }

    /// Mark a file as saved by the app so it won't trigger screenshot detection
    func ignoreFile(_ url: URL) {
        ignoredFiles.insert(url.lastPathComponent)
        // Also add to known files immediately to prevent race conditions
        knownFiles.insert(url.lastPathComponent)
    }

    func startMonitoring() {
        knownFiles = Set(
            (try? FileManager.default.contentsOfDirectory(atPath: watchDirectory.path)) ?? []
        )

        fileDescriptor = open(watchDirectory.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: .main
        )

        source.setEventHandler { [weak self] in
            self?.checkForNewScreenshots()
        }

        source.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
                self?.fileDescriptor = -1
            }
        }

        source.resume()
        dispatchSource = source
    }

    func stopMonitoring() {
        dispatchSource?.cancel()
        dispatchSource = nil
    }

    private func checkForNewScreenshots() {
        guard let currentFiles = try? FileManager.default.contentsOfDirectory(atPath: watchDirectory.path) else {
            return
        }

        let newFiles = Set(currentFiles).subtracting(knownFiles)
        for filename in newFiles {
            // Skip files that were saved by the app
            if ignoredFiles.contains(filename) {
                ignoredFiles.remove(filename)
                continue
            }
            if isScreenshotFile(filename) {
                let fileURL = watchDirectory.appendingPathComponent(filename)
                onScreenshotDetected?(fileURL)
            }
        }
        knownFiles = Set(currentFiles)
    }

    private func isScreenshotFile(_ filename: String) -> Bool {
        filename.hasPrefix("Screenshot") && filename.hasSuffix(".png")
    }
}

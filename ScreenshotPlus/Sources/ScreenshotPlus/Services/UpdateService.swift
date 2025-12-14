import Foundation
import AppKit

final class UpdateService {
    static let shared = UpdateService()

    private let githubRepo = "JuliusWallblom/screenshot-plus"
    private let lastCheckKey = "lastUpdateCheck"
    private let autoCheckKey = "autoCheckUpdates"
    private let checkInterval: TimeInterval = 24 * 60 * 60 // 24 hours
    private var isUpdating = false

    private init() {}

    var autoCheckEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: autoCheckKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoCheckKey) }
    }

    private var lastCheckDate: Date? {
        get { UserDefaults.standard.object(forKey: lastCheckKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastCheckKey) }
    }

    func checkForUpdates(silent: Bool) {
        guard !isUpdating else { return }

        // For silent checks, respect rate limiting and auto-check preference
        if silent {
            guard autoCheckEnabled else { return }
            if let lastCheck = lastCheckDate,
               Date().timeIntervalSince(lastCheck) < checkInterval {
                return
            }
        }

        lastCheckDate = Date()

        let urlString = "https://api.github.com/repos/\(githubRepo)/releases/latest"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                if !silent {
                    self?.showError("Could not check for updates. Please try again later.")
                }
                return
            }

            do {
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                self.handleRelease(release, silent: silent)
            } catch {
                if !silent {
                    self.showError("Could not parse update information.")
                }
            }
        }.resume()
    }

    private func handleRelease(_ release: GitHubRelease, silent: Bool) {
        let remoteVersion = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let currentVersion = AppConfig.version

        if isNewerVersion(remoteVersion, than: currentVersion) {
            // Find the DMG asset
            guard let dmgAsset = release.assets.first(where: { $0.name.hasSuffix(".dmg") }) else {
                if !silent {
                    DispatchQueue.main.async {
                        self.showError("No downloadable update found.")
                    }
                }
                return
            }

            DispatchQueue.main.async {
                self.showUpdateAlert(version: remoteVersion, downloadURL: dmgAsset.browserDownloadURL)
            }
        } else if !silent {
            DispatchQueue.main.async {
                self.showUpToDateAlert()
            }
        }
    }

    private func isNewerVersion(_ remote: String, than current: String) -> Bool {
        let remoteComponents = remote.split(separator: ".").compactMap { Int($0) }
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(remoteComponents.count, currentComponents.count) {
            let r = i < remoteComponents.count ? remoteComponents[i] : 0
            let c = i < currentComponents.count ? currentComponents[i] : 0
            if r > c { return true }
            if r < c { return false }
        }
        return false
    }

    private func showUpdateAlert(version: String, downloadURL: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Screenshot+ \(version) is available. You are currently running \(AppConfig.version).\n\nThe app will restart after updating. Any unsaved changes will be lost."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Update Now")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            downloadAndInstallUpdate(from: downloadURL)
        }
    }

    private func downloadAndInstallUpdate(from urlString: String) {
        guard let url = URL(string: urlString) else {
            showError("Invalid download URL.")
            return
        }

        isUpdating = true

        // Create and show progress window
        let progressWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 80),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        progressWindow.title = "Updating..."
        progressWindow.isReleasedWhenClosed = false

        let progressIndicator = NSProgressIndicator(frame: NSRect(x: 20, y: 40, width: 260, height: 20))
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = true
        progressIndicator.startAnimation(nil)

        let label = NSTextField(labelWithString: "Downloading update...")
        label.frame = NSRect(x: 20, y: 15, width: 260, height: 20)
        label.alignment = .center

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 80))
        contentView.addSubview(progressIndicator)
        contentView.addSubview(label)
        progressWindow.contentView = contentView
        progressWindow.center()
        progressWindow.makeKeyAndOrderFront(nil)

        // Run download in background
        URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            DispatchQueue.main.async {
                progressWindow.close()
            }

            guard let self = self else { return }

            if let error = error {
                self.isUpdating = false
                self.showError("Download failed: \(error.localizedDescription)")
                return
            }

            guard let tempURL = tempURL else {
                self.isUpdating = false
                self.showError("Download failed: No file received.")
                return
            }

            self.installUpdateFromDMG(at: tempURL)
        }.resume()
    }

    private func installUpdateFromDMG(at dmgURL: URL) {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        do {
            // Create temp directory
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

            // Copy DMG to temp directory with .dmg extension
            let dmgPath = tempDir.appendingPathComponent("update.dmg")
            try fileManager.copyItem(at: dmgURL, to: dmgPath)

            // Mount the DMG
            let mountProcess = Process()
            mountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            mountProcess.arguments = ["attach", dmgPath.path, "-nobrowse", "-quiet"]

            let pipe = Pipe()
            mountProcess.standardOutput = pipe

            try mountProcess.run()
            mountProcess.waitUntilExit()

            guard mountProcess.terminationStatus == 0 else {
                throw NSError(domain: "UpdateService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to mount update DMG."])
            }

            // Find the mounted volume - look for Screenshot+ volume
            let volumesURL = URL(fileURLWithPath: "/Volumes")
            let volumes = try fileManager.contentsOfDirectory(at: volumesURL, includingPropertiesForKeys: nil)
            guard let mountedVolume = volumes.first(where: { $0.lastPathComponent.contains("Screenshot") }) else {
                throw NSError(domain: "UpdateService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not find mounted volume."])
            }

            // Find the .app in the mounted volume
            let volumeContents = try fileManager.contentsOfDirectory(at: mountedVolume, includingPropertiesForKeys: nil)
            guard let newAppURL = volumeContents.first(where: { $0.pathExtension == "app" }) else {
                // Unmount before throwing
                let unmountProcess = Process()
                unmountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
                unmountProcess.arguments = ["detach", mountedVolume.path, "-quiet"]
                try? unmountProcess.run()
                unmountProcess.waitUntilExit()

                throw NSError(domain: "UpdateService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No app found in update DMG."])
            }

            // Get current app location
            let currentAppURL = URL(fileURLWithPath: Bundle.main.bundlePath)

            // Create backup of current app
            let backupURL = currentAppURL.deletingLastPathComponent().appendingPathComponent("Screenshot+_backup.app")
            try? fileManager.removeItem(at: backupURL)
            try fileManager.copyItem(at: currentAppURL, to: backupURL)

            // Replace current app with new app
            try fileManager.removeItem(at: currentAppURL)
            try fileManager.copyItem(at: newAppURL, to: currentAppURL)

            // Unmount the DMG
            let unmountProcess = Process()
            unmountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            unmountProcess.arguments = ["detach", mountedVolume.path, "-quiet"]
            try? unmountProcess.run()
            unmountProcess.waitUntilExit()

            // Clean up backup and temp files
            try? fileManager.removeItem(at: backupURL)
            try? fileManager.removeItem(at: tempDir)

            // Relaunch the app
            DispatchQueue.main.async {
                self.relaunchApp(at: currentAppURL)
            }

        } catch {
            isUpdating = false
            showError("Installation failed: \(error.localizedDescription)")
        }
    }

    private func relaunchApp(at appURL: URL) {
        // Use a shell script to wait for this process to exit, then open the new app
        let script = """
            sleep 1
            open "\(appURL.path)"
            """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        try? process.run()

        // Terminate current app
        NSApp.terminate(nil)
    }

    private func showUpToDateAlert() {
        let alert = NSAlert()
        alert.messageText = "You're Up to Date"
        alert.informativeText = "Screenshot+ \(AppConfig.version) is the latest version."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Update Failed"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

private struct GitHubRelease: Codable {
    let tagName: String
    let htmlURL: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case assets
    }
}

private struct GitHubAsset: Codable {
    let name: String
    let browserDownloadURL: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

import Foundation
import AppKit

final class UpdateService {
    static let shared = UpdateService()

    private let githubRepo = "JuliusWallblom/screenshot-plus"
    private let lastCheckKey = "lastUpdateCheck"
    private let autoCheckKey = "autoCheckUpdates"
    private let checkInterval: TimeInterval = 24 * 60 * 60 // 24 hours

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
            DispatchQueue.main.async {
                self.showUpdateAlert(version: remoteVersion, releaseURL: release.htmlURL)
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

    private func showUpdateAlert(version: String, releaseURL: String) {
        let alert = NSAlert()
        alert.messageText = "Update Available"
        alert.informativeText = "Screenshot+ \(version) is available. You are currently running \(AppConfig.version)."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: releaseURL) {
                NSWorkspace.shared.open(url)
            }
        }
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
            alert.messageText = "Update Check Failed"
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

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

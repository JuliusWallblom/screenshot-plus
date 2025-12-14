import AppKit

final class MenuBarController {
    private(set) var statusItem: NSStatusItem?
    let menu: NSMenu
    private var thumbnailItem: NSMenuItem?
    private var launchAtLoginItem: NSMenuItem?

    init() {
        menu = NSMenu()
        menu.delegate = nil
        setupMenu()
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "app.background.dotted", accessibilityDescription: "Screenshot+")
        }
        statusItem?.menu = menu
    }

    private func setupMenu() {
        let bringToFrontItem = NSMenuItem(title: "Bring to Front", action: #selector(bringToFront), keyEquivalent: "")
        bringToFrontItem.target = self
        menu.addItem(bringToFrontItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences submenu
        let preferencesItem = NSMenuItem(title: "Preferences", action: nil, keyEquivalent: "")
        let preferencesSubmenu = NSMenu()

        let thumbnailMenuItem = NSMenuItem(title: "Show Screenshot Preview", action: #selector(toggleThumbnail), keyEquivalent: "")
        thumbnailMenuItem.target = self
        thumbnailMenuItem.state = isThumbnailEnabled() ? .on : .off
        thumbnailItem = thumbnailMenuItem
        preferencesSubmenu.addItem(thumbnailMenuItem)

        let launchAtLoginMenuItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginMenuItem.target = self
        launchAtLoginMenuItem.state = LaunchAtLoginService.shared.isEnabled ? .on : .off
        launchAtLoginItem = launchAtLoginMenuItem
        preferencesSubmenu.addItem(launchAtLoginMenuItem)

        preferencesItem.submenu = preferencesSubmenu
        menu.addItem(preferencesItem)

        menu.addItem(NSMenuItem.separator())

        let checkUpdatesItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        checkUpdatesItem.target = self
        menu.addItem(checkUpdatesItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func checkForUpdates() {
        UpdateService.shared.checkForUpdates(silent: false)
    }

    private func isThumbnailEnabled() -> Bool {
        guard let domain = UserDefaults.standard.persistentDomain(forName: "com.apple.screencapture"),
              let showThumbnail = domain["show-thumbnail"] as? Bool else {
            return true // Default is enabled
        }
        return showThumbnail
    }

    @objc private func toggleThumbnail() {
        let newValue = !isThumbnailEnabled()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["write", "com.apple.screencapture", "show-thumbnail", "-bool", newValue ? "true" : "false"]
        try? process.run()
        process.waitUntilExit()

        thumbnailItem?.state = newValue ? .on : .off
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLoginService.shared.toggle()
        launchAtLoginItem?.state = LaunchAtLoginService.shared.isEnabled ? .on : .off
    }

    @objc private func bringToFront() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.isVisible {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

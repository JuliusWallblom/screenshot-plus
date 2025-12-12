import AppKit

final class MenuBarController {
    private(set) var statusItem: NSStatusItem?
    let menu: NSMenu

    init() {
        menu = NSMenu()
        setupMenu()
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "Greataxe")
        }
        statusItem?.menu = menu
    }

    private func setupMenu() {
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct GreataxeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

private class WindowContext: NSObject, NSWindowDelegate {
    let windowState: AnnotationWindowState
    let canvasState: CanvasState
    weak var appDelegate: AppDelegate?
    var toolbarController: ToolbarController?

    init(windowState: AnnotationWindowState, canvasState: CanvasState) {
        self.windowState = windowState
        self.canvasState = canvasState
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            sender.contentView = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.appDelegate?.removeWindow(sender)
            }
        }
        return false
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var screenshotMonitor: ScreenshotMonitor?
    private var windowContexts: [NSWindow: WindowContext] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        menuBarController = MenuBarController()
        menuBarController?.setupStatusItem()

        let screenshotDirectory = getScreenshotDirectory()
        screenshotMonitor = ScreenshotMonitor(watchDirectory: screenshotDirectory)
        screenshotMonitor?.onScreenshotDetected = { [weak self] url in
            DispatchQueue.main.async {
                self?.openAnnotationWindow(for: url)
            }
        }
        screenshotMonitor?.startMonitoring()

        setupEditMenu()
    }

    private func setupEditMenu() {
        let editMenu = NSMenu(title: "Edit")

        let undoItem = NSMenuItem(title: "Undo", action: #selector(performUndo), keyEquivalent: "z")
        undoItem.target = self
        editMenu.addItem(undoItem)

        let redoItem = NSMenuItem(title: "Redo", action: #selector(performRedo), keyEquivalent: "Z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        redoItem.target = self
        editMenu.addItem(redoItem)

        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = editMenu

        if let mainMenu = NSApp.mainMenu {
            mainMenu.addItem(editMenuItem)
        } else {
            let mainMenu = NSMenu()
            mainMenu.addItem(editMenuItem)
            NSApp.mainMenu = mainMenu
        }
    }

    @objc private func performUndo() {
        if let window = NSApp.keyWindow,
           let context = windowContexts[window] {
            context.canvasState.undo()
        }
    }

    @objc private func performRedo() {
        if let window = NSApp.keyWindow,
           let context = windowContexts[window] {
            context.canvasState.redo()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        screenshotMonitor?.stopMonitoring()
        windowContexts.removeAll()
    }

    func removeWindow(_ window: NSWindow) {
        windowContexts.removeValue(forKey: window)
    }

    /// Mark a file as saved by the app so it won't trigger screenshot detection
    func ignoreSavedFile(_ url: URL) {
        screenshotMonitor?.ignoreFile(url)
    }

    private func getScreenshotDirectory() -> URL {
        if let customPath = UserDefaults.standard.persistentDomain(forName: "com.apple.screencapture")?["location"] as? String {
            return URL(fileURLWithPath: customPath)
        }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    }

    private func openAnnotationWindow(for imageURL: URL) {
        let windowState = AnnotationWindowState(imageURL: imageURL)
        let canvasState = CanvasState()
        let context = WindowContext(windowState: windowState, canvasState: canvasState)
        context.appDelegate = self

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false

        let contentView = AnnotationContentView(state: windowState, canvasState: canvasState)
        window.contentView = NSHostingView(rootView: contentView)

        let toolbar = NSToolbar(identifier: "AnnotationToolbar")
        let toolbarController = ToolbarController(canvasState: canvasState, windowState: windowState)
        context.toolbarController = toolbarController
        toolbar.delegate = toolbarController
        toolbarController.setToolbar(toolbar)
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        window.titleVisibility = .hidden

        window.title = imageURL.lastPathComponent
        window.delegate = context
        window.center()
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)

        windowContexts[window] = context
    }
}

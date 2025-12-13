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
    var toolbarDelegate: ToolbarDelegate?

    init(windowState: AnnotationWindowState, canvasState: CanvasState) {
        self.windowState = windowState
        self.canvasState = canvasState
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide instead of close, then clean up safely
        sender.orderOut(nil)

        // Clean up after animations complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            sender.contentView = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.appDelegate?.removeWindow(sender)
            }
        }
        return false // Don't actually close the window
    }
}

private func createLineWidthImage(width: CGFloat, color: NSColor, size: NSSize = NSSize(width: 40, height: 16)) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    color.setFill()
    let rect = NSRect(x: 4, y: (size.height - width) / 2, width: size.width - 8, height: width)
    NSBezierPath(roundedRect: rect, xRadius: width / 2, yRadius: width / 2).fill()
    image.unlockFocus()
    return image
}

private struct SettingsPopoverContent: View {
    @ObservedObject var canvasState: CanvasState

    private let widths: [CGFloat] = [1, 2, 4, 8]

    private var isShapeTool: Bool {
        canvasState.currentTool == .rectangle || canvasState.currentTool == .oval
    }

    private var isStrokeTool: Bool {
        [.rectangle, .oval, .line, .arrow, .pen].contains(canvasState.currentTool)
    }

    private func updateSelectedAnnotations(_ update: (inout Annotation) -> Void) {
        guard !canvasState.selectedAnnotationIds.isEmpty else { return }
        canvasState.saveState()
        canvasState.updateSelectedAnnotations(update)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Color picker - always shown
            HStack {
                Text("Color")
                    .frame(width: 70, alignment: .leading)
                ColorPicker("", selection: $canvasState.strokeColor, supportsOpacity: false)
                    .labelsHidden()
                    .onChange(of: canvasState.strokeColor) { _, newColor in
                        updateSelectedAnnotations { $0.strokeColor = newColor }
                    }
            }

            // Line width - for stroke-based tools
            if isStrokeTool {
                HStack {
                    Text("Line Width")
                        .frame(width: 70, alignment: .leading)
                    Menu {
                        ForEach(widths, id: \.self) { width in
                            Button {
                                canvasState.strokeWidth = width
                                updateSelectedAnnotations { $0.strokeWidth = width }
                            } label: {
                                let img = createLineWidthImage(width: width, color: NSColor(canvasState.strokeColor))
                                Label {
                                    Text(width == 1 ? "Thin" : width == 2 ? "Medium" : width == 4 ? "Thick" : "Extra Thick")
                                } icon: {
                                    Image(nsImage: img)
                                }
                            }
                        }
                    } label: {
                        Image(nsImage: createLineWidthImage(width: canvasState.strokeWidth, color: NSColor(canvasState.strokeColor)))
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 50)
                }
            }

            // Fill toggle - for shapes only
            if isShapeTool {
                HStack {
                    Text("Fill Shape")
                        .frame(width: 70, alignment: .leading)
                    Toggle("", isOn: $canvasState.fillShapes)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: canvasState.fillShapes) { _, newValue in
                            updateSelectedAnnotations { annotation in
                                if annotation.type == .rectangle || annotation.type == .oval {
                                    annotation.isFilled = newValue
                                }
                            }
                        }
                }
            }

            // Text options
            if canvasState.currentTool == .text {
                HStack {
                    Text("Font")
                        .frame(width: 70, alignment: .leading)
                    Picker("", selection: $canvasState.textFontName) {
                        Text("System").tag("System")
                        Divider()
                        ForEach(NSFontManager.shared.availableFontFamilies, id: \.self) { fontName in
                            Text(fontName).tag(fontName)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }
                .onChange(of: canvasState.textFontName) { _, newValue in
                    updateSelectedAnnotations { annotation in
                        if annotation.type == .text {
                            annotation.fontName = newValue
                        }
                    }
                }

                HStack {
                    Text("Font Size")
                        .frame(width: 70, alignment: .leading)
                    Slider(value: $canvasState.textFontSize, in: 8...72, step: 1)
                        .frame(width: 80)
                    Text("\(Int(canvasState.textFontSize))")
                        .frame(width: 25)
                }
                .onChange(of: canvasState.textFontSize) { _, newValue in
                    updateSelectedAnnotations { annotation in
                        if annotation.type == .text {
                            annotation.fontSize = newValue
                        }
                    }
                }

                HStack {
                    Text("Background")
                        .frame(width: 70, alignment: .leading)
                    HStack(spacing: 8) {
                        Toggle("", isOn: Binding(
                            get: { canvasState.textBackgroundColor != nil },
                            set: { enabled in
                                canvasState.textBackgroundColor = enabled ? .yellow.opacity(0.5) : nil
                                updateSelectedAnnotations { annotation in
                                    if annotation.type == .text {
                                        annotation.textBackgroundColor = canvasState.textBackgroundColor
                                    }
                                }
                            }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)

                        if canvasState.textBackgroundColor != nil {
                            ColorPicker("", selection: Binding(
                                get: { canvasState.textBackgroundColor ?? .yellow },
                                set: { newColor in
                                    canvasState.textBackgroundColor = newColor
                                    updateSelectedAnnotations { annotation in
                                        if annotation.type == .text {
                                            annotation.textBackgroundColor = newColor
                                        }
                                    }
                                }
                            ), supportsOpacity: true)
                            .labelsHidden()
                        }
                    }
                }

                if canvasState.textBackgroundColor != nil {
                    // Padding grid with icons
                    VStack(spacing: 4) {
                        Text("Padding")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Grid(horizontalSpacing: 8, verticalSpacing: 4) {
                            GridRow {
                                // Top padding
                                HStack(spacing: 4) {
                                    Text("T")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("", value: $canvasState.textBackgroundPaddingTop, format: FloatingPointFormatStyle<CGFloat>().precision(.fractionLength(0)))
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 40)
                                        .font(.caption.monospacedDigit())
                                }
                                .onChange(of: canvasState.textBackgroundPaddingTop) { _, newValue in
                                    updateSelectedAnnotations { annotation in
                                        if annotation.type == .text {
                                            annotation.textBackgroundPaddingTop = newValue
                                        }
                                    }
                                }

                                // Right padding
                                HStack(spacing: 4) {
                                    Text("R")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("", value: $canvasState.textBackgroundPaddingRight, format: FloatingPointFormatStyle<CGFloat>().precision(.fractionLength(0)))
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 40)
                                        .font(.caption.monospacedDigit())
                                }
                                .onChange(of: canvasState.textBackgroundPaddingRight) { _, newValue in
                                    updateSelectedAnnotations { annotation in
                                        if annotation.type == .text {
                                            annotation.textBackgroundPaddingRight = newValue
                                        }
                                    }
                                }
                            }
                            GridRow {
                                // Bottom padding
                                HStack(spacing: 4) {
                                    Text("B")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("", value: $canvasState.textBackgroundPaddingBottom, format: FloatingPointFormatStyle<CGFloat>().precision(.fractionLength(0)))
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 40)
                                        .font(.caption.monospacedDigit())
                                }
                                .onChange(of: canvasState.textBackgroundPaddingBottom) { _, newValue in
                                    updateSelectedAnnotations { annotation in
                                        if annotation.type == .text {
                                            annotation.textBackgroundPaddingBottom = newValue
                                        }
                                    }
                                }

                                // Left padding
                                HStack(spacing: 4) {
                                    Text("L")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("", value: $canvasState.textBackgroundPaddingLeft, format: FloatingPointFormatStyle<CGFloat>().precision(.fractionLength(0)))
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 40)
                                        .font(.caption.monospacedDigit())
                                }
                                .onChange(of: canvasState.textBackgroundPaddingLeft) { _, newValue in
                                    updateSelectedAnnotations { annotation in
                                        if annotation.type == .text {
                                            annotation.textBackgroundPaddingLeft = newValue
                                        }
                                    }
                                }
                            }
                        }
                    }

                    HStack {
                        Text("Radius")
                            .frame(width: 70, alignment: .leading)
                        Slider(value: $canvasState.textBackgroundCornerRadius, in: 0...20, step: 1)
                            .frame(width: 80)
                        Text("\(Int(canvasState.textBackgroundCornerRadius))")
                            .frame(width: 20)
                    }
                    .onChange(of: canvasState.textBackgroundCornerRadius) { _, newValue in
                        updateSelectedAnnotations { annotation in
                            if annotation.type == .text {
                                annotation.textBackgroundCornerRadius = newValue
                            }
                        }
                    }
                }

                HStack {
                    Text("Alignment")
                        .frame(width: 70, alignment: .leading)
                    Picker("", selection: $canvasState.textAlignment) {
                        Image(systemName: "text.alignleft").tag(TextAlignment.left)
                        Image(systemName: "text.aligncenter").tag(TextAlignment.center)
                        Image(systemName: "text.alignright").tag(TextAlignment.right)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 100)
                    .onChange(of: canvasState.textAlignment) { oldAlignment, newAlignment in
                        updateSelectedAnnotations { annotation in
                            if annotation.type == .text {
                                // Calculate actual text width using same method as boundingRect
                                let font: NSFont
                                if annotation.fontName == "System" {
                                    font = NSFont.systemFont(ofSize: annotation.fontSize, weight: .medium)
                                } else {
                                    font = NSFont(name: annotation.fontName, size: annotation.fontSize)
                                        ?? NSFont.systemFont(ofSize: annotation.fontSize, weight: .medium)
                                }
                                let attributes: [NSAttributedString.Key: Any] = [.font: font]
                                let lines = annotation.text.components(separatedBy: "\n")
                                let textWidth = max(
                                    lines.map { ($0 as NSString).size(withAttributes: attributes).width }.max() ?? 10,
                                    10
                                )

                                // Calculate current visual center of text based on old alignment
                                let oldTextCenterX: CGFloat
                                switch oldAlignment {
                                case .left: oldTextCenterX = annotation.startPoint.x + textWidth / 2
                                case .center: oldTextCenterX = annotation.startPoint.x
                                case .right: oldTextCenterX = annotation.startPoint.x - textWidth / 2
                                }

                                // Calculate new startPoint to maintain same visual center
                                let newStartX: CGFloat
                                switch newAlignment {
                                case .left: newStartX = oldTextCenterX - textWidth / 2
                                case .center: newStartX = oldTextCenterX
                                case .right: newStartX = oldTextCenterX + textWidth / 2
                                }

                                annotation.startPoint.x = newStartX
                                annotation.textAlignment = newAlignment
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
    }
}

private class ToolbarDelegate: NSObject, NSToolbarDelegate, NSPopoverDelegate, NSToolbarItemValidation {
    let canvasState: CanvasState
    let windowState: AnnotationWindowState
    private let exporter = ImageExporter()
    private var toolsGroup: NSToolbarItemGroup?
    private var paddingItem: NSToolbarItem?
    private var settingsButton: NSButton?
    private var settingsPopover: NSPopover?
    private var undoItem: NSToolbarItem?
    private var redoItem: NSToolbarItem?
    private weak var toolbar: NSToolbar?

    private let itemIdentifiers: [NSToolbarItem.Identifier] = [
        .init("padding"),
        .flexibleSpace,
        .init("toolsGroup"),
        .init("settings"),
        .flexibleSpace,
        .init("undo"),
        .init("redo"),
        .space,
        .init("copy"),
        .init("save")
    ]

    init(canvasState: CanvasState, windowState: AnnotationWindowState) {
        self.canvasState = canvasState
        self.windowState = windowState
    }

    func setToolbar(_ toolbar: NSToolbar) {
        self.toolbar = toolbar
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        itemIdentifiers
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        itemIdentifiers
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "undo":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.image = NSImage(systemSymbolName: "arrow.uturn.backward", accessibilityDescription: "Undo")
            item.label = "Undo"
            item.toolTip = "Undo (⌘Z)"
            item.target = self
            item.action = #selector(undoAction)
            item.autovalidates = true
            undoItem = item
            return item

        case "redo":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.image = NSImage(systemSymbolName: "arrow.uturn.forward", accessibilityDescription: "Redo")
            item.label = "Redo"
            item.toolTip = "Redo (⇧⌘Z)"
            item.target = self
            item.action = #selector(redoAction)
            item.autovalidates = true
            redoItem = item
            return item

        case "settings":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            let button = NSButton(frame: NSRect(x: 0, y: 0, width: 30, height: 24))
            button.bezelStyle = .texturedRounded
            button.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "Settings")
            button.toolTip = "Annotation Settings"
            button.target = self
            button.action = #selector(showSettingsPopover(_:))
            item.view = button
            item.label = "Settings"
            item.toolTip = "Annotation Settings"
            settingsButton = button
            return item

        case "toolsGroup":
            let tools: [(String, String, String)] = [
                ("rectangle.dashed", "Select", "Select & Move (V)"),
                ("rectangle", "Rectangle", "Rectangle Tool (R)"),
                ("oval", "Oval", "Oval Tool (O)"),
                ("line.diagonal", "Line", "Line Tool (L)"),
                ("arrow.up.right", "Arrow", "Arrow Tool (A)"),
                ("pencil", "Pen", "Pen Tool (P)"),
                ("textformat", "Text", "Text Tool (T)")
            ]

            let group = NSToolbarItemGroup(itemIdentifier: itemIdentifier, images: tools.map { NSImage(systemSymbolName: $0.0, accessibilityDescription: $0.1)! }, selectionMode: .selectOne, labels: tools.map { $0.1 }, target: self, action: #selector(toolGroupChanged(_:)))

            // Set tooltips for each tool in the group
            for (index, tool) in tools.enumerated() {
                group.subitems[index].toolTip = tool.2
            }

            // Set selected index based on persisted tool
            let toolOrder: [DrawingTool] = [.select, .rectangle, .oval, .line, .arrow, .pen, .text]
            group.selectedIndex = toolOrder.firstIndex(of: canvasState.currentTool) ?? 1

            group.label = "Tools"
            toolsGroup = group
            return group

        case "padding":
            let group = NSToolbarItemGroup(itemIdentifier: itemIdentifier, images: [NSImage(systemSymbolName: "sidebar.squares.left", accessibilityDescription: "Padding")!], selectionMode: .selectAny, labels: ["Padding"], target: self, action: #selector(togglePaddingPanel(_:)))
            group.label = "Padding"
            group.subitems[0].toolTip = "Toggle Padding Panel"
            if canvasState.showPaddingPanel {
                group.setSelected(true, at: 0)
            }
            paddingItem = group
            return group

        case "copy":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Copy")
            item.label = "Copy"
            item.toolTip = "Copy to Clipboard (⌘C)"
            item.target = self
            item.action = #selector(copyImage)
            return item

        case "save":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: "Save")
            item.label = "Save"
            item.toolTip = "Save Image (⌘S)"
            item.target = self
            item.action = #selector(saveImage)
            return item

        default:
            return nil
        }
    }

    @objc private func toolGroupChanged(_ sender: NSToolbarItemGroup) {
        let tools: [DrawingTool] = [.select, .rectangle, .oval, .line, .arrow, .pen, .text]
        let index = sender.selectedIndex
        if index >= 0 && index < tools.count {
            canvasState.currentTool = tools[index]
        }
    }

    @objc private func showSettingsPopover(_ sender: NSButton) {
        if let popover = settingsPopover, popover.isShown {
            popover.close()
            return
        }

        let popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: SettingsPopoverContent(canvasState: canvasState))
        popover.behavior = .transient
        popover.delegate = self
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        settingsPopover = popover
    }

    func popoverDidClose(_ notification: Notification) {
        settingsPopover = nil
    }

    @objc func togglePaddingPanel(_ sender: NSToolbarItemGroup) {
        canvasState.showPaddingPanel = sender.isSelected(at: 0)
    }

    @objc private func undoAction() {
        canvasState.undo()
        toolbar?.validateVisibleItems()
    }

    @objc private func redoAction() {
        canvasState.redo()
        toolbar?.validateVisibleItems()
    }

    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier.rawValue {
        case "undo":
            return canvasState.canUndo
        case "redo":
            return canvasState.canRedo
        default:
            return true
        }
    }

    @objc private func copyImage() {
        guard let baseImage = windowState.loadImage(),
              let rendered = exporter.renderImage(baseImage, with: canvasState.annotations, paddingOptions: canvasState.paddingOptions) else {
            return
        }
        _ = exporter.copyToClipboard(rendered)
    }

    @objc private func saveImage() {
        guard let baseImage = windowState.loadImage(),
              let rendered = exporter.renderImage(baseImage, with: canvasState.annotations, paddingOptions: canvasState.paddingOptions) else {
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = windowState.imageURL.deletingPathExtension().lastPathComponent + "_annotated.png"

        if panel.runModal() == .OK, let url = panel.url {
            _ = exporter.saveToFile(rendered, at: url)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var screenshotMonitor: ScreenshotMonitor?
    private var windowContexts: [NSWindow: WindowContext] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - run as menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // Set up menu bar
        menuBarController = MenuBarController()
        menuBarController?.setupStatusItem()

        // Start monitoring for screenshots
        let screenshotDirectory = getScreenshotDirectory()
        screenshotMonitor = ScreenshotMonitor(watchDirectory: screenshotDirectory)
        screenshotMonitor?.onScreenshotDetected = { [weak self] url in
            DispatchQueue.main.async {
                self?.openAnnotationWindow(for: url)
            }
        }
        screenshotMonitor?.startMonitoring()

        // Set up Edit menu for keyboard shortcuts
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

    private func disableScreenshotThumbnail() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["write", "com.apple.screencapture", "show-thumbnail", "-bool", "false"]
        try? process.run()
        process.waitUntilExit()
    }

    func applicationWillTerminate(_ notification: Notification) {
        screenshotMonitor?.stopMonitoring()
        windowContexts.removeAll()
    }

    func removeWindow(_ window: NSWindow) {
        windowContexts.removeValue(forKey: window)
    }

    private func getScreenshotDirectory() -> URL {
        // Try to get custom screenshot location from macOS defaults
        if let customPath = UserDefaults.standard.persistentDomain(forName: "com.apple.screencapture")?["location"] as? String {
            return URL(fileURLWithPath: customPath)
        }
        // Default to Desktop
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

        // Content view without toolbar
        let contentView = AnnotationContentView(state: windowState, canvasState: canvasState)
        window.contentView = NSHostingView(rootView: contentView)

        // Create NSToolbar
        let toolbar = NSToolbar(identifier: "AnnotationToolbar")
        let toolbarDelegate = ToolbarDelegate(canvasState: canvasState, windowState: windowState)
        context.toolbarDelegate = toolbarDelegate
        toolbar.delegate = toolbarDelegate
        toolbarDelegate.setToolbar(toolbar)
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        window.titleVisibility = .hidden

        window.title = imageURL.lastPathComponent
        window.delegate = context
        window.center()
        window.makeKeyAndOrderFront(nil)

        // Bring app to front
        NSApp.activate(ignoringOtherApps: true)

        // Store context to keep state alive
        windowContexts[window] = context
    }
}

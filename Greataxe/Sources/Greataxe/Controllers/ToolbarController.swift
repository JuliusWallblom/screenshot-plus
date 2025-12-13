import AppKit
import SwiftUI

func createLineWidthImage(width: CGFloat, color: NSColor, size: NSSize = NSSize(width: 40, height: 16)) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()
    color.setFill()
    let rect = NSRect(x: 4, y: (size.height - width) / 2, width: size.width - 8, height: width)
    NSBezierPath(roundedRect: rect, xRadius: width / 2, yRadius: width / 2).fill()
    image.unlockFocus()
    return image
}

class ToolbarController: NSObject, NSToolbarDelegate, NSPopoverDelegate, NSToolbarItemValidation {
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

            for (index, tool) in tools.enumerated() {
                group.subitems[index].toolTip = tool.2
            }

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
            // Mark file as saved by app to prevent screenshot monitor from reopening it
            ScreenshotMonitor.ignoreSavedFile(url)
            _ = exporter.saveToFile(rendered, at: url)
            // Close the window after saving (defer to let save panel fully dismiss)
            DispatchQueue.main.async {
                // Find window with our toolbar and close it
                for window in NSApp.windows {
                    if window.toolbar === self.toolbar {
                        window.close()
                        break
                    }
                }
            }
        }
    }
}

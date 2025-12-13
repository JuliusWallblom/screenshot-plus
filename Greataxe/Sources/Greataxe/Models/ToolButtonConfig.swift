import Foundation

struct ToolButtonConfig: Identifiable {
    let id = UUID()
    let tool: DrawingTool
    let iconName: String
    let label: String

    static let allTools: [ToolButtonConfig] = [
        ToolButtonConfig(tool: .pen, iconName: "pencil", label: "Pen"),
        ToolButtonConfig(tool: .rectangle, iconName: "rectangle", label: "Rectangle"),
        ToolButtonConfig(tool: .oval, iconName: "circle", label: "Oval"),
        ToolButtonConfig(tool: .line, iconName: "line.diagonal", label: "Line"),
        ToolButtonConfig(tool: .arrow, iconName: "arrow.up.right", label: "Arrow"),
        ToolButtonConfig(tool: .text, iconName: "textformat", label: "Text"),
        ToolButtonConfig(tool: .crop, iconName: "crop", label: "Crop")
    ]
}

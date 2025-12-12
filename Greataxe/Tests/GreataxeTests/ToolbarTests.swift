import Testing
import SwiftUI
@testable import Greataxe

@Suite("Toolbar Tests")
struct ToolbarTests {
    @Test("ToolbarState has all drawing tools")
    func toolbarStateHasAllDrawingTools() {
        let allTools: [DrawingTool] = [.pen, .rectangle, .oval, .line, .arrow, .text, .crop]

        for tool in allTools {
            let state = CanvasState()
            state.currentTool = tool
            #expect(state.currentTool == tool)
        }
    }

    @Test("ToolButton represents each tool type")
    func toolButtonRepresentsEachToolType() {
        let toolConfigs = ToolButtonConfig.allTools

        #expect(toolConfigs.count >= 6)
        #expect(toolConfigs.contains { $0.tool == .rectangle })
        #expect(toolConfigs.contains { $0.tool == .oval })
        #expect(toolConfigs.contains { $0.tool == .line })
        #expect(toolConfigs.contains { $0.tool == .arrow })
        #expect(toolConfigs.contains { $0.tool == .pen })
        #expect(toolConfigs.contains { $0.tool == .text })
    }

    @Test("ToolButtonConfig has icon name and tool")
    func toolButtonConfigHasIconNameAndTool() {
        let config = ToolButtonConfig(tool: .rectangle, iconName: "rectangle", label: "Rectangle")

        #expect(config.tool == .rectangle)
        #expect(config.iconName == "rectangle")
        #expect(config.label == "Rectangle")
    }
}

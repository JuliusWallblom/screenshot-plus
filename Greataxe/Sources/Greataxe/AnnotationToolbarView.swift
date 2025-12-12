import SwiftUI

struct AnnotationToolbarView: View {
    @Bindable var canvasState: CanvasState

    var body: some View {
        HStack(spacing: 4) {
            StrokeWidthPicker(strokeWidth: $canvasState.strokeWidth)

            Divider()
                .frame(height: 24)

            ForEach(ToolButtonConfig.allTools) { config in
                ToolButton(
                    config: config,
                    isSelected: canvasState.currentTool == config.tool
                ) {
                    canvasState.currentTool = config.tool
                }
            }

            Divider()
                .frame(height: 24)

            ColorPickerButton(color: $canvasState.strokeColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: NSColor.windowBackgroundColor))
    }
}

struct ToolButton: View {
    let config: ToolButtonConfig
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: config.iconName)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 28, height: 28)
                .background(isSelected ? Color.accentColor : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(config.label)
    }
}

struct StrokeWidthPicker: View {
    @Binding var strokeWidth: CGFloat

    private let widths: [CGFloat] = [1, 2, 4, 8]

    var body: some View {
        Menu {
            ForEach(widths, id: \.self) { width in
                Button(action: { strokeWidth = width }) {
                    HStack {
                        RoundedRectangle(cornerRadius: width / 2)
                            .frame(width: 30, height: width)
                        Text("\(Int(width))px")
                        if strokeWidth == width {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: strokeWidth / 2)
                    .frame(width: 20, height: strokeWidth)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .frame(width: 44, height: 28)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct ColorPickerButton: View {
    @Binding var color: Color

    private let presetColors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .black, .white
    ]

    var body: some View {
        Menu {
            ForEach(presetColors, id: \.self) { presetColor in
                Button(action: { color = presetColor }) {
                    HStack {
                        Circle()
                            .fill(presetColor)
                            .frame(width: 16, height: 16)
                        if color == presetColor {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .frame(width: 44, height: 28)
            .background(Color(nsColor: NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

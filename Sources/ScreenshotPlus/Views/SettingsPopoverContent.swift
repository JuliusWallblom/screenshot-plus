import SwiftUI
import AppKit

struct SettingsPopoverContent: View {
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

                // Text stroke (outline) settings
                HStack {
                    Text("Stroke")
                        .frame(width: 70, alignment: .leading)
                    HStack(spacing: 8) {
                        Toggle("", isOn: Binding(
                            get: { canvasState.textStrokeColor != nil },
                            set: { enabled in
                                canvasState.textStrokeColor = enabled ? .black : nil
                                updateSelectedAnnotations { annotation in
                                    if annotation.type == .text {
                                        annotation.textStrokeColor = canvasState.textStrokeColor
                                    }
                                }
                            }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)

                        if canvasState.textStrokeColor != nil {
                            ColorPicker("", selection: Binding(
                                get: { canvasState.textStrokeColor ?? .black },
                                set: { newColor in
                                    canvasState.textStrokeColor = newColor
                                    updateSelectedAnnotations { annotation in
                                        if annotation.type == .text {
                                            annotation.textStrokeColor = newColor
                                        }
                                    }
                                }
                            ), supportsOpacity: false)
                            .labelsHidden()
                        }
                    }
                }

                if canvasState.textStrokeColor != nil {
                    HStack {
                        Text("Thickness")
                            .frame(width: 70, alignment: .leading)
                        Slider(value: $canvasState.textStrokeWidth, in: 0.5...5, step: 0.5)
                            .frame(width: 80)
                        Text(String(format: "%.1f", canvasState.textStrokeWidth))
                            .frame(width: 25)
                    }
                    .onChange(of: canvasState.textStrokeWidth) { _, newValue in
                        updateSelectedAnnotations { annotation in
                            if annotation.type == .text {
                                annotation.textStrokeWidth = newValue
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
    }
}

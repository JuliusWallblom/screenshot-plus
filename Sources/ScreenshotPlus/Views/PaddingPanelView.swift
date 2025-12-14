import SwiftUI

struct PaddingPanelView: View {
    @ObservedObject var canvasState: CanvasState

    private let gradientPresets: [(String, Color, Color, Double)] = [
        ("Purple Blue", .purple, .blue, 45),
        ("Pink Orange", .pink, .orange, 135),
        ("Green Teal", .green, .teal, 90),
        ("Indigo Purple", .indigo, .purple, 0),
        ("Orange Red", .orange, .red, 45),
        ("Cyan Blue", .cyan, .blue, 180),
        ("Gray", Color(.systemGray), Color(.darkGray), 90),
        ("Black", .black, Color(.darkGray), 45)
    ]

    private var isEnabled: Bool { canvasState.paddingOptions.enabled }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Background")
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: $canvasState.paddingOptions.enabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Padding amount
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Padding")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            Slider(value: $canvasState.paddingOptions.amount, in: 20...120, step: 10)
                            Text("\(Int(canvasState.paddingOptions.amount))px")
                                .font(.caption)
                                .monospacedDigit()
                                .frame(width: 40)
                        }
                    }

                    // Corner radius
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Corner Radius")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            Slider(value: $canvasState.paddingOptions.cornerRadius, in: 0...32, step: 4)
                            Text("\(Int(canvasState.paddingOptions.cornerRadius))px")
                                .font(.caption)
                                .monospacedDigit()
                                .frame(width: 40)
                        }
                    }

                    Divider()

                    // Shadow section
                    HStack {
                        Text("Shadow")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Toggle("", isOn: $canvasState.paddingOptions.shadow.enabled)
                            .toggleStyle(.switch)
                            .scaleEffect(0.8)
                            .labelsHidden()
                    }

                    if canvasState.paddingOptions.shadow.enabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Blur")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                Slider(value: $canvasState.paddingOptions.shadow.radius, in: 0...50, step: 5)
                                Text("\(Int(canvasState.paddingOptions.shadow.radius))")
                                    .font(.caption)
                                    .monospacedDigit()
                                    .frame(width: 30)
                            }
                            HStack {
                                Text("Opacity")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                Slider(value: $canvasState.paddingOptions.shadow.opacity, in: 0...1, step: 0.1)
                                Text("\(Int(canvasState.paddingOptions.shadow.opacity * 100))%")
                                    .font(.caption)
                                    .monospacedDigit()
                                    .frame(width: 30)
                            }
                            HStack {
                                Text("Offset")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .leading)
                                Slider(value: $canvasState.paddingOptions.shadow.offsetY, in: 0...30, step: 2)
                                Text("\(Int(canvasState.paddingOptions.shadow.offsetY))")
                                    .font(.caption)
                                    .monospacedDigit()
                                    .frame(width: 30)
                            }
                        }
                    }

                    Divider()

                    // Gradient presets
                    Text("Gradient")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 8) {
                        ForEach(gradientPresets, id: \.0) { preset in
                            GradientPresetButton(
                                startColor: preset.1,
                                endColor: preset.2,
                                angle: preset.3,
                                isSelected: isPresetSelected(preset),
                                action: {
                                    canvasState.paddingOptions.gradient = GradientBackground(
                                        startColor: preset.1,
                                        endColor: preset.2,
                                        angle: preset.3
                                    )
                                }
                            )
                        }
                    }

                    Divider()

                    // Custom colors
                    Text("Custom")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ColorPicker("", selection: $canvasState.paddingOptions.gradient.startColor, supportsOpacity: false)
                                .labelsHidden()
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("End")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ColorPicker("", selection: $canvasState.paddingOptions.gradient.endColor, supportsOpacity: false)
                                .labelsHidden()
                        }

                        Spacer()
                    }

                    // Angle
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Angle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            Slider(value: $canvasState.paddingOptions.gradient.angle, in: 0...360, step: 15)
                            Text("\(Int(canvasState.paddingOptions.gradient.angle))°")
                                .font(.caption)
                                .monospacedDigit()
                                .frame(width: 40)
                        }
                    }
                }
                .opacity(isEnabled ? 1 : 0.4)
                .disabled(!isEnabled)
            }
            .padding()
        }
        .frame(width: 220)
        .background(Color(nsColor: NSColor.windowBackgroundColor))
    }

    private func isPresetSelected(_ preset: (String, Color, Color, Double)) -> Bool {
        let gradient = canvasState.paddingOptions.gradient
        return gradient.startColor == preset.1 &&
               gradient.endColor == preset.2 &&
               gradient.angle == preset.3
    }
}

struct GradientPresetButton: View {
    let startColor: Color
    let endColor: Color
    let angle: Double
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [startColor, endColor],
                        startPoint: gradientStartPoint,
                        endPoint: gradientEndPoint
                    )
                )
                .frame(width: 50, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    private var gradientStartPoint: UnitPoint {
        let radians = angle * .pi / 180
        return UnitPoint(x: 0.5 - cos(radians) * 0.5, y: 0.5 - sin(radians) * 0.5)
    }

    private var gradientEndPoint: UnitPoint {
        let radians = angle * .pi / 180
        return UnitPoint(x: 0.5 + cos(radians) * 0.5, y: 0.5 + sin(radians) * 0.5)
    }
}

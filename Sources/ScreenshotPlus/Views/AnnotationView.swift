import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AnnotationView: View {
    let state: AnnotationWindowState
    let canvasState: CanvasState
    private let exporter = ImageExporter()

    init(state: AnnotationWindowState, canvasState: CanvasState = CanvasState()) {
        self.state = state
        self.canvasState = canvasState
    }

    var body: some View {
        VStack(spacing: 0) {
            AnnotationToolbarView(
                canvasState: canvasState,
                onSave: saveImage,
                onCopy: copyImage
            )
            AnnotationCanvasWithOverlay(state: state, canvasState: canvasState)
        }
        .background(Color.black)
    }

    private func copyImage() {
        guard let baseImage = state.loadImage(),
              let rendered = exporter.renderImage(baseImage, with: canvasState.annotations, paddingOptions: canvasState.paddingOptions) else {
            return
        }
        _ = exporter.copyToClipboard(rendered)
    }

    private func saveImage() {
        guard let baseImage = state.loadImage(),
              let rendered = exporter.renderImage(baseImage, with: canvasState.annotations, paddingOptions: canvasState.paddingOptions) else {
            return
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = state.imageURL.deletingPathExtension().lastPathComponent + "_annotated.png"

        if panel.runModal() == .OK, let url = panel.url {
            // Mark file as saved by app to prevent screenshot monitor from reopening it
            ScreenshotMonitor.ignoreSavedFile(url)
            _ = exporter.saveToFile(rendered, at: url)
            // Close the window after saving
            NSApp.keyWindow?.close()
        }
    }
}

struct AnnotationContentView: View {
    let state: AnnotationWindowState
    @ObservedObject var canvasState: CanvasState

    var body: some View {
        HStack(spacing: 0) {
            if canvasState.showPaddingPanel {
                PaddingPanelView(canvasState: canvasState)
            }
            AnnotationCanvasWithOverlay(state: state, canvasState: canvasState)
                .background(Color.black)
        }
    }
}

struct AnnotationCanvasWithOverlay: View {
    let state: AnnotationWindowState
    @ObservedObject var canvasState: CanvasState
    @State private var image: NSImage?

    var body: some View {
        GeometryReader { geometry in
            let paddingEnabled = canvasState.paddingOptions.enabled
            let padding = paddingEnabled ? canvasState.paddingOptions.amount : 0
            let cornerRadius = paddingEnabled ? canvasState.paddingOptions.cornerRadius : 0
            let gradient = canvasState.paddingOptions.gradient

            ZStack {
                if paddingEnabled {
                    // Gradient background
                    LinearGradient(
                        colors: [gradient.startColor, gradient.endColor],
                        startPoint: gradientStartPoint(for: gradient.angle),
                        endPoint: gradientEndPoint(for: gradient.angle)
                    )
                }

                if let image = image {
                    let imageRect = calculateImageRect(
                        imageSize: image.size,
                        in: geometry.size,
                        padding: padding
                    )
                    let shadow = canvasState.paddingOptions.shadow

                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .shadow(
                            color: .black.opacity(paddingEnabled && shadow.enabled ? shadow.opacity : 0),
                            radius: shadow.radius,
                            x: 0,
                            y: shadow.offsetY
                        )
                        .frame(width: imageRect.width, height: imageRect.height)
                        .position(x: imageRect.midX, y: imageRect.midY)

                    DrawingCanvasView(canvasState: canvasState, imageRect: imageRect)
                } else {
                    Color.black
                }
            }
        }
        .onAppear {
            image = state.loadImage()
            if let img = image {
                canvasState.imageSize = img.size
            }
        }
    }

    private func gradientStartPoint(for angle: Double) -> UnitPoint {
        let radians = angle * .pi / 180
        return UnitPoint(x: 0.5 - cos(radians) * 0.5, y: 0.5 - sin(radians) * 0.5)
    }

    private func gradientEndPoint(for angle: Double) -> UnitPoint {
        let radians = angle * .pi / 180
        return UnitPoint(x: 0.5 + cos(radians) * 0.5, y: 0.5 + sin(radians) * 0.5)
    }

    private func calculateImageRect(imageSize: CGSize, in containerSize: CGSize, padding: CGFloat = 0) -> CGRect {
        let availableSize = CGSize(
            width: containerSize.width - padding * 2,
            height: containerSize.height - padding * 2
        )

        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = availableSize.width / availableSize.height

        var displaySize: CGSize
        if imageAspect > containerAspect {
            // Image is wider - fit to width
            displaySize = CGSize(width: availableSize.width, height: availableSize.width / imageAspect)
        } else {
            // Image is taller - fit to height
            displaySize = CGSize(width: availableSize.height * imageAspect, height: availableSize.height)
        }

        let x = (containerSize.width - displaySize.width) / 2
        let y = (containerSize.height - displaySize.height) / 2

        return CGRect(x: x, y: y, width: displaySize.width, height: displaySize.height)
    }
}

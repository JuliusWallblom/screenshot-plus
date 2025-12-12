import SwiftUI
import AppKit

struct AnnotationView: View {
    let state: AnnotationWindowState
    @State var canvasState = CanvasState()

    var body: some View {
        VStack(spacing: 0) {
            AnnotationToolbarView(canvasState: canvasState)
            AnnotationCanvasWithOverlay(state: state, canvasState: canvasState)
        }
        .background(Color.black)
    }
}

struct AnnotationCanvasWithOverlay: View {
    let state: AnnotationWindowState
    @Bindable var canvasState: CanvasState
    @State private var image: NSImage?

    var body: some View {
        ZStack {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.black
            }

            DrawingCanvasView(canvasState: canvasState)
        }
        .onAppear {
            image = state.loadImage()
        }
    }
}

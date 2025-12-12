import SwiftUI
import AppKit

struct AnnotationView: View {
    let state: AnnotationWindowState

    var body: some View {
        VStack(spacing: 0) {
            AnnotationToolbar()
            AnnotationCanvas(state: state)
        }
        .background(Color.black)
    }
}

struct AnnotationToolbar: View {
    var body: some View {
        HStack(spacing: 12) {
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: NSColor.windowBackgroundColor).opacity(0.95))
    }
}

struct AnnotationCanvas: View {
    let state: AnnotationWindowState
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.black
            }
        }
        .onAppear {
            image = state.loadImage()
        }
    }
}

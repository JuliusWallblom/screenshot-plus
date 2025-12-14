import AppKit
import SwiftUI

final class AnnotationWindowState: ObservableObject {
    let imageURL: URL

    init(imageURL: URL) {
        self.imageURL = imageURL
    }

    func loadImage() -> NSImage? {
        NSImage(contentsOf: imageURL)
    }
}

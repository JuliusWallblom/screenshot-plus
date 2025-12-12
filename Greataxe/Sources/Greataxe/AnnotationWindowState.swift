import AppKit
import SwiftUI

@Observable
final class AnnotationWindowState {
    let imageURL: URL

    init(imageURL: URL) {
        self.imageURL = imageURL
    }

    func loadImage() -> NSImage? {
        NSImage(contentsOf: imageURL)
    }
}

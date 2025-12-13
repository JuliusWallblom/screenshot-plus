import Testing
import AppKit
@testable import Preview_

@Suite("Crop Tool Tests")
struct CropToolTests {
    @Test("CropState tracks crop region")
    func cropStateTracksCropRegion() {
        let cropState = CropState()

        #expect(cropState.isActive == false)
        #expect(cropState.cropRect == .zero)

        cropState.startCrop(at: CGPoint(x: 10, y: 10))
        cropState.updateCrop(to: CGPoint(x: 100, y: 100))

        #expect(cropState.isActive == true)
        #expect(cropState.cropRect.origin.x == 10)
        #expect(cropState.cropRect.origin.y == 10)
        #expect(cropState.cropRect.width == 90)
        #expect(cropState.cropRect.height == 90)
    }

    @Test("CropState applies crop to image")
    func cropStateAppliesToImage() throws {
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()

        let cropState = CropState()
        cropState.startCrop(at: CGPoint(x: 25, y: 25))
        cropState.updateCrop(to: CGPoint(x: 75, y: 75))

        let croppedImage = cropState.applyCrop(to: image)

        #expect(croppedImage != nil)
        #expect(croppedImage?.size.width == 50)
        #expect(croppedImage?.size.height == 50)
    }

    @Test("CropState can cancel crop")
    func cropStateCanCancelCrop() {
        let cropState = CropState()

        cropState.startCrop(at: CGPoint(x: 0, y: 0))
        cropState.updateCrop(to: CGPoint(x: 50, y: 50))

        #expect(cropState.isActive == true)

        cropState.cancelCrop()

        #expect(cropState.isActive == false)
        #expect(cropState.cropRect == .zero)
    }
}

import Testing
import AppKit
@testable import Greataxe

@Suite("WindowFactory Tests")
struct WindowFactoryTests {
    @Test("WindowFactory can be instantiated")
    func canBeInstantiated() {
        let factory = WindowFactory()
        #expect(factory.defaultSize.width == 800)
        #expect(factory.defaultSize.height == 600)
    }
}

import Testing
import AppKit
@testable import Preview_

@Suite("Menu Bar Tests")
struct MenuBarTests {
    @Test("MenuBarController creates menu")
    func menuBarControllerCreatesMenu() {
        let controller = MenuBarController()
        #expect(controller.menu.items.count > 0)
    }

    @Test("MenuBarController has menu with quit action")
    func menuBarControllerHasMenuWithQuitAction() {
        let controller = MenuBarController()

        let menu = controller.menu
        let quitItem = menu.items.first { $0.title == "Quit" }
        #expect(quitItem != nil)
    }
}

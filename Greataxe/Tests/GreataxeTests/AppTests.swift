import Testing
@testable import Greataxe

@Suite("App Structure Tests")
struct AppTests {
    @Test("App name is Greataxe")
    func appNameIsGreataxe() {
        #expect(AppConfig.appName == "Greataxe")
    }
}

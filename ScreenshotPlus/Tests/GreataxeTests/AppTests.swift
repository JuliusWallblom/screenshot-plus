import Testing
@testable import Screenshot_

@Suite("App Structure Tests")
struct AppTests {
    @Test("App name is Screenshot+")
    func appNameIsScreenshotPlus() {
        #expect(AppConfig.appName == "Screenshot+")
    }
}

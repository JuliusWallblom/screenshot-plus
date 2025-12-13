import Testing
@testable import Preview_

@Suite("App Structure Tests")
struct AppTests {
    @Test("App name is Preview+")
    func appNameIsPreviewPlus() {
        #expect(AppConfig.appName == "Preview+")
    }
}

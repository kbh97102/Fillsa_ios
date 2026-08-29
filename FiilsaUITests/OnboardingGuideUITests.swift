import XCTest

final class OnboardingGuideUITests: XCTestCase {
    @MainActor
    func testTestLaunchConfigurationShowsTheFirstOnboardingGuidePage() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-onboarding-guide"]
        app.launch()

        XCTAssertTrue(app.buttons["건너뛰기"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["다음"].exists)
        attachScreenshot(app, named: "onboarding-guide-page-1-runtime")

        app.buttons["다음"].tap()
        XCTAssertTrue(app.buttons["다음"].waitForExistence(timeout: 2))
        attachScreenshot(app, named: "onboarding-guide-page-2-runtime")

        app.buttons["다음"].tap()
        XCTAssertTrue(app.buttons["필사 시작하기"].waitForExistence(timeout: 2))
        attachScreenshot(app, named: "onboarding-guide-page-3-runtime")
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

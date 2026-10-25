import XCTest

final class TypingResultUITests: XCTestCase {
    @MainActor
    func testLightResultsAndConfirmation() throws {
        try verifyResults(dark: false)
    }

    @MainActor
    func testDarkResultsAndConfirmation() throws {
        try verifyResults(dark: true)
    }

    @MainActor
    private func verifyResults(dark: Bool) throws {
        let app = XCUIApplication()
        for (result, title) in [
            ("completed", "필사 완료!"),
            ("streak", "연속 필사 완료!"),
            ("encouragement", "오늘도 이어서 필사를 해주세요!"),
            ("incomplete", "필사가 완료되지 않았어요.")
        ] {
            app.launchArguments = ["-ui-testing-home", "-ui-testing-typing-result=\(result)"]
                + (dark ? ["ui-testing-theme-dark"] : [])
            app.launch()
            XCTAssertTrue(app.buttons["home.quoteCard"].waitForExistence(timeout: 3))
            app.buttons["home.quoteCard"].tap()
            let save = app.buttons["저장하기"]
            XCTAssertTrue(save.waitForExistence(timeout: 3))
            save.tap()
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 3))
            XCTAssertFalse(app.keyboards.firstMatch.exists)
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "typing-\(result)-\(dark ? "dark" : "light")-full-frame"
            capture.lifetime = .keepAlways
            add(capture)
            if result == "incomplete" {
                app.buttons["취소"].tap()
                XCTAssertTrue(save.waitForExistence(timeout: 3))
                XCTAssertFalse(app.staticTexts[title].exists)
                save.tap()
                XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 3))
                app.buttons["필사하기"].tap()
                XCTAssertTrue(save.waitForExistence(timeout: 3))
                XCTAssertFalse(app.staticTexts[title].exists)
            } else {
                app.buttons["확인"].tap()
                XCTAssertTrue(app.buttons["home.quoteCard"].waitForExistence(timeout: 3))
                XCTAssertFalse(app.staticTexts[title].exists)
            }
            app.terminate()
        }
    }
}

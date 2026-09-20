import XCTest

final class HomeUITests: XCTestCase {
    @MainActor
    func testHomeRendersTheFigmaQuestionAndAnswerState() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-home"]
        app.launch()

        XCTAssertTrue(app.buttons["home.quoteCard"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["오늘의 질문"].exists)
        XCTAssertTrue(app.textViews["home.answer"].exists)
        XCTAssertTrue(app.buttons["home.answerRecord"].exists)
        XCTAssertTrue(app.buttons["home.registerImage"].exists)
        XCTAssertFalse(app.staticTexts["광고가 들어가는 영역입니다."].exists)
    }

    @MainActor
    func testHomeFixtureStaysLightAfterTheAppStartupTask() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-home"]
        app.launch()

        XCTAssertTrue(app.buttons["home.quoteCard"].waitForExistence(timeout: 2))
        let startupSettled = expectation(description: "startup task settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startupSettled.fulfill() }
        wait(for: [startupSettled], timeout: 1)

        let image = app.screenshot().image
        XCTAssertEqual(rgb(at: CGPoint(x: 10, y: 100), in: image, appFrame: app.frame), "255,239,204")
    }

    @MainActor
    func testDarkTypingSaveButtonUsesVisibleWhiteFill() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-home", "ui-testing-theme-dark"]
        app.launch()

        let quoteCard = app.buttons["home.quoteCard"]
        XCTAssertTrue(quoteCard.waitForExistence(timeout: 2))
        quoteCard.tap()

        let save = app.buttons["저장하기"]
        XCTAssertTrue(save.waitForExistence(timeout: 2))
        let image = app.screenshot().image
        XCTAssertEqual(
            rgb(
                at: CGPoint(x: save.frame.minX + 4, y: save.frame.midY),
                in: image,
                appFrame: app.frame
            ),
            "255,255,255"
        )
    }

    @MainActor
    func testLightTypingSaveButtonUsesDarkBorder() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-home"]
        app.launch()

        let quoteCard = app.buttons["home.quoteCard"]
        XCTAssertTrue(quoteCard.waitForExistence(timeout: 2))
        quoteCard.tap()

        let save = app.buttons["저장하기"]
        XCTAssertTrue(save.waitForExistence(timeout: 2))
        let image = app.screenshot().image
        XCTAssertEqual(
            rgb(
                at: CGPoint(x: save.frame.minX + 0.5, y: save.frame.midY),
                in: image,
                appFrame: app.frame
            ),
            "33,33,33"
        )
    }

    @MainActor
    func testHomeCalendarAndQuestionRemainInHome() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-home"]
        app.launch()

        XCTAssertTrue(app.buttons["home.calendarTrigger"].waitForExistence(timeout: 2))
        app.buttons["home.calendarTrigger"].tap()
        XCTAssertTrue(app.otherElements["home.calendarPopup"].waitForExistence(timeout: 2))

        app.buttons["home.calendarTrigger"].tap()
        XCTAssertFalse(app.otherElements["home.calendarPopup"].exists)

        let answer = app.textViews["home.answer"]
        answer.tap()
        answer.typeText("홈에 남기는 답변")
        app.buttons["home.answerRecord"].tap()
        XCTAssertTrue(app.buttons["home.answerEdit"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["답변을 기록했어요."].exists)
    }

    private func rgb(at point: CGPoint, in image: UIImage, appFrame: CGRect) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let scale = CGFloat(cgImage.width) / appFrame.width
        let x = Int((point.x * scale).rounded())
        let y = Int((point.y * scale).rounded())
        guard x >= 0, x < cgImage.width, y >= 0, y < cgImage.height,
              let data = cgImage.dataProvider?.data else { return nil }
        let bytes = CFDataGetBytePtr(data)
        let offset = y * cgImage.bytesPerRow + x * 4
        return "\(bytes![offset]),\(bytes![offset + 1]),\(bytes![offset + 2])"
    }
}

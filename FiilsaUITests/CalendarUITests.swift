import XCTest

final class CalendarUITests: XCTestCase {
    @MainActor
    func testDarkCalendarNoWritingShowsRenewalNavigationAndAd() throws {
        let app = launchCalendar(theme: "dark", state: "no-writing")

        XCTAssertTrue(app.descendants(matching: .any)["calendarMonthCard"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["100일"].exists)
        XCTAssertTrue(app.staticTexts["필사하지 않은 날이에요.\n아래 필사를 선택하여 기록해주세요!"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["bottomNavigation"].exists)
        XCTAssertTrue(app.buttons["Home"].exists)
        XCTAssertTrue(app.buttons["Calendar"].exists)
        XCTAssertTrue(app.buttons["My page"].exists)
        XCTAssertFalse(app.buttons["List"].exists)
        XCTAssertTrue(app.staticTexts["광고가 들어가는 영역입니다."].exists)
    }

    @MainActor
    func testDarkCalendarCompletedWritingShowsQuoteActionsAndQuestion() throws {
        let app = launchCalendar(theme: "dark", state: "completed")

        XCTAssertTrue(app.descendants(matching: .any)["calendarMonthCard"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["영광은 먼지와 땀과 피로 얼굴이 얼룩진 채 경기장에 서 있는 사람의 것이다."].exists)
        XCTAssertTrue(app.staticTexts["오늘의 질문"].exists)
        XCTAssertTrue(app.buttons["내 답변 기록하기"].exists)
    }

    @MainActor
    private func launchCalendar(theme: String, state: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["ui-testing-calendar", "ui-testing-theme-\(theme)", "ui-testing-calendar-\(state)"]
        app.launch()
        return app
    }
}

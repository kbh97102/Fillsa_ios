import XCTest

final class CalendarUITests: XCTestCase {
    @MainActor
    func testLightCalendarShowsStreakAndHidesBottomNavigation() throws {
        let app = launchCalendar(theme: "light")

        XCTAssertTrue(app.descendants(matching: .any)["calendarMonthCard"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["calendarStreak"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["bottomNavigation"].exists)
    }

    @MainActor
    func testDarkCalendarHidesStreakAndShowsBottomNavigation() throws {
        let app = launchCalendar(theme: "dark")

        XCTAssertTrue(app.descendants(matching: .any)["calendarMonthCard"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.descendants(matching: .any)["calendarStreak"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["bottomNavigation"].exists)
    }

    @MainActor
    private func launchCalendar(theme: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["ui-testing-calendar", "ui-testing-theme-\(theme)"]
        app.launch()
        return app
    }
}

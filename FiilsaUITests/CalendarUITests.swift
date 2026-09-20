import UIKit
import XCTest

final class CalendarUITests: XCTestCase {
    @MainActor
    func testDarkCalendarNoWritingShowsRenewalNavigationWithoutAd() throws {
        let app = launchCalendar(theme: "dark", state: "no-writing")

        XCTAssertTrue(app.descendants(matching: .any)["calendarMonthCard"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["100일"].exists)
        XCTAssertTrue(app.staticTexts["필사하지 않은 날이에요.\n아래 필사를 선택하여 기록해주세요!"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["bottomNavigation"].exists)
        XCTAssertTrue(app.buttons["Home"].exists)
        XCTAssertTrue(app.buttons["Calendar"].exists)
        XCTAssertTrue(app.buttons["My page"].exists)
        XCTAssertFalse(app.buttons["List"].exists)
        XCTAssertFalse(app.staticTexts["광고가 들어가는 영역입니다."].exists)
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
    func testLightCalendarCompletedActionLabelUsesFigmaColor() throws {
        assertCompletedActionLabelColor(
            theme: "light",
            expected: (86, 81, 73)
        )
    }

    @MainActor
    func testDarkCalendarCompletedActionLabelUsesFigmaColor() throws {
        assertCompletedActionLabelColor(
            theme: "dark",
            expected: (158, 158, 158)
        )
    }

    @MainActor
    private func assertCompletedActionLabelColor(
        theme: String,
        expected: (UInt8, UInt8, UInt8)
    ) {
        let app = launchCalendar(theme: theme, state: "completed")
        let actions = app.descendants(matching: .any)["명언 작업"]
        XCTAssertTrue(actions.waitForExistence(timeout: 3))

        let labelArea = CGRect(
            x: actions.frame.minX + 60,
            y: actions.frame.minY + 13,
            width: 14,
            height: 18
        )
        XCTAssertGreaterThan(
            pixelCount(in: labelArea, image: app.screenshot().image, appFrame: app.frame, near: expected),
            5
        )
    }

    @MainActor
    private func launchCalendar(theme: String, state: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["ui-testing-calendar", "ui-testing-theme-\(theme)", "ui-testing-calendar-\(state)"]
        app.launch()
        return app
    }

    private func pixelCount(
        in area: CGRect,
        image: UIImage,
        appFrame: CGRect,
        near target: (UInt8, UInt8, UInt8)
    ) -> Int {
        guard let cgImage = image.cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else { return 0 }
        let scale = CGFloat(cgImage.width) / appFrame.width
        let bounds = area.applying(CGAffineTransform(scaleX: scale, y: scale)).integral
        var matches = 0

        for y in max(0, Int(bounds.minY))..<min(cgImage.height, Int(bounds.maxY)) {
            for x in max(0, Int(bounds.minX))..<min(cgImage.width, Int(bounds.maxX)) {
                let offset = y * cgImage.bytesPerRow + x * 4
                if abs(Int(bytes[offset]) - Int(target.0)) <= 3,
                   abs(Int(bytes[offset + 1]) - Int(target.1)) <= 3,
                   abs(Int(bytes[offset + 2]) - Int(target.2)) <= 3 {
                    matches += 1
                }
            }
        }
        return matches
    }
}

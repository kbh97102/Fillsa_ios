import UIKit
import XCTest

final class CalendarUITests: XCTestCase {
    @MainActor
    func testCopyShowsConfirmationAndLikedRecordShowsSelection() throws {
        let app = launchCalendar(theme: "light", state: "completed")
        let like = app.buttons["calendar.like"]
        XCTAssertTrue(like.waitForExistence(timeout: 3))
        XCTAssertEqual(like.value as? String, "선택됨")
        app.buttons["calendar.copy"].tap()
        XCTAssertTrue(app.staticTexts["복사되었습니다."].waitForExistence(timeout: 2))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "calendar-copy-full-frame"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

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
    func testSavedCalendarAnswerFixtureShowsEditState() throws {
        let app = XCUIApplication()
        app.launchArguments = ["ui-testing-calendar", "ui-testing-theme-light",
                               "ui-testing-calendar-completed", "ui-testing-calendar-answer-saved"]
        app.launch()
        app.swipeUp()

        XCTAssertTrue(app.textViews["home.answer"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.textViews["home.answer"].value as? String, "오늘의 질문에 답을 기록했어요.")
        XCTAssertTrue(app.buttons["내 답변 수정하기"].exists)
    }

    @MainActor
    func testCompletedQuoteActionsAreTappableForTheSelectedDay() throws {
        let app = launchCalendar(theme: "light", state: "completed")
        XCTAssertTrue(app.descendants(matching: .any)["calendarMonthCard"].waitForExistence(timeout: 3))

        for identifier in ["calendar.copy", "calendar.share", "calendar.like", "calendar.image"] {
            XCTAssertTrue(app.buttons[identifier].exists, "Missing action button: \(identifier)")
        }

        app.buttons["calendar.copy"].tap()
        app.buttons["calendar.share"].tap()
        XCTAssertTrue(app.staticTexts["배경을 선택해주세요."].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["영광은 먼지와 땀과 피로 얼굴이 얼룩진 채 경기장에 서 있는 사람의 것이다."].exists)
    }

    @MainActor
    func testCompletedCalendarImageActionOpensTheExistingDialog() throws {
        let app = launchCalendar(theme: "dark", state: "completed")
        let image = app.buttons["calendar.image"]
        XCTAssertTrue(image.waitForExistence(timeout: 3))
        image.tap()
        XCTAssertTrue(app.otherElements["home.imageDialog"].waitForExistence(timeout: 3))

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
        let copyAction = app.buttons["calendar.copy"]
        XCTAssertTrue(copyAction.waitForExistence(timeout: 3))

        let labelArea = copyAction.frame.insetBy(dx: 2, dy: 2)
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

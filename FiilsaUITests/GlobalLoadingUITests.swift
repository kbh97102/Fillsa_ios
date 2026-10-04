import XCTest

final class GlobalLoadingUITests: XCTestCase {
    @MainActor
    func testHomeKeyboardClosesWhenGlobalLoadingStarts() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-home", "-ui-testing-global-loading-on-keyboard"]
        app.launch()

        let answer = app.textViews["home.answer"]
        XCTAssertTrue(answer.waitForExistence(timeout: 3))
        answer.tap()
        XCTAssertTrue(app.images["globalLoading.spinner"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.keyboards.firstMatch.exists)
    }

    @MainActor
    func testTypingKeyboardStillAppearsWithoutGlobalLoading() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-home"]
        app.launch()

        let quoteCard = app.buttons["home.quoteCard"]
        XCTAssertTrue(quoteCard.waitForExistence(timeout: 3))
        quoteCard.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3))
    }

    @MainActor
    func testTypingKeyboardIsUnavailableWhileGlobalLoading() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-global-loading",
            "-ui-testing-global-loading-screen=typing"
        ]
        app.launch()

        XCTAssertTrue(app.images["globalLoading.spinner"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.keyboards.firstMatch.exists, "System keyboard must not accept touches above the loading overlay")
    }

    @MainActor
    func testSplashDoesNotShowGlobalSpinnerWhileLoadingScopeIsActive() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-global-loading",
            "-ui-testing-global-loading-screen=splash"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["나만의 필사로 채우다,"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.images["globalLoading.spinner"].exists)
    }

    @MainActor
    func testSpinnerCoversRoutableScreensExceptSplash() throws {
        let routes: [(name: String, marker: String)] = [
            ("login", "login.kakao"),
            ("onboardingGuide", "건너뛰기"),
            ("home", "home.quoteCard"),
            ("quoteList", "quoteList.dateSelector"),
            ("calendar", "calendarMonthCard"),
            ("myPage", "myPage.screen"),
            ("typing", "저장하기"),
            ("share", "배경을 선택해주세요."),
            ("quoteDetail", "메모"),
            ("memoInsert", "memo.editor"),
            ("notice", "공지사항"),
            ("noticeDetail", "noticeDetail.title"),
            ("alert", "알림")
        ]

        for route in routes {
            let app = XCUIApplication()
            app.launchArguments = [
                "-ui-testing-global-loading",
                "-ui-testing-global-loading-screen=\(route.name)"
            ]
            app.launch()

            XCTAssertTrue(
                app.descendants(matching: .any)[route.marker].waitForExistence(timeout: 3),
                "Wrong or unreachable screen: \(route.name)"
            )
            let spinner = app.images["globalLoading.spinner"]
            XCTAssertTrue(spinner.waitForExistence(timeout: 3), "Missing spinner on \(route.name)")
            if spinner.exists {
                XCTAssertEqual(spinner.frame.midX, app.frame.midX, accuracy: 1, route.name)
                XCTAssertEqual(spinner.frame.midY, app.frame.midY, accuracy: 1, route.name)
            }
            app.terminate()
        }
    }
}

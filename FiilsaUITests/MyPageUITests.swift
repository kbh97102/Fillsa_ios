import XCTest

final class MyPageUITests: XCTestCase {
    private let app = XCUIApplication()

    func test_guestLightFramePresenceAndThemeArrowAbsence() {
        launchMyPage(isMember: false, isDark: false)

        assertSingleScreenInset(app.buttons[Identifier.guestCard], height: 114)
        XCTAssertFalse(app.otherElements[Identifier.memberCard].exists)
        assertMenuFrames()
        XCTAssertEqual(app.images.matching(identifier: Identifier.menuArrow).count, 2)
    }

    func test_memberLightFramePresence() {
        launchMyPage(isMember: true, isDark: false)

        assertSingleScreenInset(app.otherElements[Identifier.memberCard], height: 80)
        XCTAssertFalse(app.buttons[Identifier.guestCard].exists)
    }

    func test_guestDarkFramePresence() {
        launchMyPage(isMember: false, isDark: true)

        assertSingleScreenInset(app.buttons[Identifier.guestCard], height: 114)
        XCTAssertFalse(app.otherElements[Identifier.memberCard].exists)
    }

    func test_memberDarkFramePresence() {
        launchMyPage(isMember: true, isDark: true)

        assertSingleScreenInset(app.otherElements[Identifier.memberCard], height: 80)
        XCTAssertFalse(app.buttons[Identifier.guestCard].exists)
    }

    func test_memberSeesDirectAccountDeletionAndGuestDoesNot() {
        launchMyPage(isMember: true, isDark: false)

        let resign = app.buttons[Identifier.resign]
        XCTAssertTrue(resign.waitForExistence(timeout: 2))
        XCTAssertEqual(resign.label, "회원탈퇴")

        launchMyPage(isMember: false, isDark: false)

        XCTAssertFalse(app.buttons[Identifier.resign].exists)
    }

    func test_themeDialogShowsSelectsAndConfirms() {
        launchMyPage(isMember: false, isDark: false)

        app.buttons[Identifier.themeMenu].tap()

        let dialog = app.otherElements[Identifier.themeDialog]
        XCTAssertTrue(dialog.waitForExistence(timeout: 2))
        XCTAssertEqual(dialog.frame.height, 237, accuracy: 1)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "My Page theme dialog"
        attachment.lifetime = .keepAlways
        add(attachment)

        let darkTheme = app.buttons[Identifier.themeDark]
        XCTAssertEqual(darkTheme.value as? String, "unselected")
        darkTheme.tap()

        app.buttons[Identifier.themeConfirm].tap()
        XCTAssertFalse(dialog.waitForExistence(timeout: 1))
    }

    private func launchMyPage(isMember: Bool, isDark: Bool) {
        app.terminate()
        app.launchArguments = [
            "-ui-testing-my-page",
            isMember ? "-ui-testing-my-page-member" : "-ui-testing-my-page-guest",
            isDark ? "-ui-testing-my-page-dark" : "-ui-testing-my-page-light"
        ]
        app.launch()
        XCTAssertTrue(app.otherElements[Identifier.screen].waitForExistence(timeout: 3))
    }

    private func assertMenuFrames(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertSingleScreenInset(app.buttons[Identifier.noticeMenu], height: 60, file: file, line: line)
        assertSingleScreenInset(app.buttons[Identifier.alertMenu], height: 60, file: file, line: line)
        assertSingleScreenInset(app.buttons[Identifier.themeMenu], height: 60, file: file, line: line)
    }

    private func assertSingleScreenInset(
        _ element: XCUIElement,
        height: CGFloat,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let inset: CGFloat = 20
        assertFrame(
            element,
            width: app.frame.width - (inset * 2),
            height: height,
            file: file,
            line: line
        )
        XCTAssertEqual(element.frame.minX, inset, accuracy: 1, file: file, line: line)
    }

    private func assertFrame(
        _ element: XCUIElement,
        width: CGFloat,
        height: CGFloat,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: 2), file: file, line: line)
        XCTAssertEqual(element.frame.width, width, accuracy: 1, file: file, line: line)
        XCTAssertEqual(element.frame.height, height, accuracy: 1, file: file, line: line)
    }
}

private enum Identifier {
    static let screen = "myPage.screen"
    static let memberCard = "myPage.memberCard"
    static let guestCard = "myPage.guestCard"
    static let noticeMenu = "myPage.noticeMenu"
    static let alertMenu = "myPage.alertMenu"
    static let themeMenu = "myPage.themeMenu"
    static let menuArrow = "myPage.menuArrow"
    static let themeDialog = "myPage.themeDialog"
    static let themeLight = "myPage.theme.light"
    static let themeDark = "myPage.theme.dark"
    static let themeConfirm = "myPage.themeConfirm"
    static let resign = "myPage.resign"
}

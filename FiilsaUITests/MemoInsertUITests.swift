import XCTest

final class MemoInsertUITests: XCTestCase {
    @MainActor
    func testLightMemoMatchesFigmaEmptyState() throws {
        let app = launchMemo(dark: false)

        XCTAssertTrue(app.textViews["memo.editor"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["memo.exit"].exists)
        XCTAssertTrue(app.buttons["memo.back"].exists)

        XCTAssertTrue(app.staticTexts["메모를 남겨주세요."].exists)
        attachScreenshot(of: app, named: "memo-light-empty")
    }

    @MainActor
    func testDarkMemoMatchesFigmaEmptyState() throws {
        let app = launchMemo(dark: true)

        XCTAssertTrue(app.textViews["memo.editor"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["memo.exit"].exists)
        XCTAssertTrue(app.buttons["memo.back"].exists)

        XCTAssertTrue(app.staticTexts["메모를 남겨주세요."].exists)
        attachScreenshot(of: app, named: "memo-dark-empty")
    }

    @MainActor
    func testMemoFilledStateShowsSavedText() throws {
        let app = launchMemo(dark: true, filled: true)

        XCTAssertTrue(app.textViews["memo.editor"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.textViews["memo.editor"].value as? String, "명언을 보면 삶에 동기부여가 되어서 좋아요.")
        XCTAssertFalse(app.staticTexts["메모를 남겨주세요."].exists)
        attachScreenshot(of: app, named: "memo-dark-filled")
    }

    @MainActor
    private func launchMemo(dark: Bool, filled: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-memo"]
            + (dark ? ["-ui-testing-memo-dark"] : [])
            + (filled ? ["-ui-testing-memo-filled"] : [])
        app.launch()
        return app
    }

    @MainActor
    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(image: app.screenshot().image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

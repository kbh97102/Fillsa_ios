import XCTest

final class TypingLayoutUITests: XCTestCase {
    @MainActor
    func testCopyButtonCanBeTappedOnTypingScreen() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-home", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()
        let card = app.buttons["home.quoteCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        let copy = app.buttons["복사"]
        XCTAssertTrue(copy.waitForExistence(timeout: 3))
        copy.tap()
        XCTAssertTrue(app.buttons["저장하기"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "typing-copy-button-tapped-full-frame"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testPromptAndSaveRemainAccessibleWithKeyboard() throws {
        for theme in ["light", "dark"] {
            for longQuote in [false, true] {
                let app = XCUIApplication()
                app.launchArguments = ["-ui-testing-home", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
                    + (theme == "dark" ? ["ui-testing-theme-dark"] : [])
                    + (longQuote ? ["-ui-testing-home-long-quote"] : [])
                app.launch()
                let card = app.buttons["home.quoteCard"]
                XCTAssertTrue(card.waitForExistence(timeout: 5))
                card.tap()
                let prompt = app.staticTexts["오늘의 문장을 따라 써주세요."]
                let keyboard = app.keyboards.firstMatch
                let save = app.buttons["저장하기"]
                XCTAssertTrue(prompt.waitForExistence(timeout: 3))
                XCTAssertTrue(keyboard.waitForExistence(timeout: 3))
                let quoteScroll = app.scrollViews["typing.quoteScroll"]
                XCTAssertTrue(quoteScroll.exists)
                XCTAssertTrue(save.isHittable)
                XCTAssertGreaterThan(prompt.frame.minY, app.frame.minY)
                XCTAssertLessThanOrEqual(save.frame.maxY, keyboard.frame.minY + 1)
                XCTAssertLessThan(prompt.frame.maxY, save.frame.minY)
                XCTAssertGreaterThanOrEqual(prompt.frame.minX, app.frame.minX)
                XCTAssertLessThanOrEqual(prompt.frame.maxX, app.frame.maxX)
                capture(app, "typing-layout-\(theme)-\(longQuote ? "long" : "normal")")

                if longQuote && quoteScroll.exists {
                    let promptBefore = prompt.frame
                    let saveBefore = save.frame
                    let quoteBefore = app.staticTexts["typing.quote"].frame
                    quoteScroll.swipeUp()
                    XCTAssertEqual(prompt.frame.minY, promptBefore.minY, accuracy: 1)
                    XCTAssertEqual(save.frame.minY, saveBefore.minY, accuracy: 1)
                    if quoteBefore.height > quoteScroll.frame.height + 1 {
                        XCTAssertLessThan(app.staticTexts["typing.quote"].frame.minY, quoteBefore.minY)
                    }
                    capture(app, "typing-layout-\(theme)-long-scrolled")
                }

                app.buttons["typing.locale"].tap()
                let quote = app.staticTexts["typing.quote"]
                XCTAssertTrue(quote.waitForExistence(timeout: 3))
                XCTAssertTrue(quote.label.contains("Love is a gift"))
                XCTAssertTrue(prompt.exists)
                XCTAssertTrue(save.isHittable)
                if !longQuote { capture(app, "typing-layout-\(theme)-english") }
                app.buttons["typing.locale"].tap()
                XCTAssertTrue(quote.label.contains("사랑"))
                app.terminate()
            }
        }
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

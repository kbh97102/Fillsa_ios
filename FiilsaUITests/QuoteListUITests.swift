import XCTest

final class QuoteListUITests: XCTestCase {
    @MainActor
    func testDateOverlayDoesNotMoveCardsAndClosesFromOutsideTap() throws {
        let app = launchQuoteList()
        let selector = app.buttons["quoteList.dateSelector"]
        let firstCard = app.otherElements["quoteList.cardFrame.1"]

        XCTAssertTrue(selector.waitForExistence(timeout: 2))
        XCTAssertTrue(firstCard.waitForExistence(timeout: 2))
        let originalFrame = firstCard.frame
        attachScreenshot(app)

        selector.tap()
        XCTAssertTrue(app.otherElements["quoteList.durationCalendar"].waitForExistence(timeout: 2))
        XCTAssertEqual(firstCard.frame.minY, originalFrame.minY, accuracy: 0.5)
        attachScreenshot(app)

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.85)).tap()
        XCTAssertFalse(app.otherElements["quoteList.durationCalendar"].waitForExistence(timeout: 1))
    }

    @MainActor
    func testDateOverlayUsesFigmaFrameBelowTheSelector() throws {
        let app = launchQuoteList()
        let selector = app.buttons["quoteList.dateSelector"]

        XCTAssertTrue(selector.waitForExistence(timeout: 2))
        selector.tap()

        let calendar = app.otherElements["quoteList.durationCalendar"]
        XCTAssertTrue(calendar.waitForExistence(timeout: 2))
        XCTAssertEqual(calendar.frame.minX, selector.frame.minX - 10, accuracy: 0.5)
        XCTAssertEqual(calendar.frame.minY, selector.frame.maxY + 10, accuracy: 1.5)
        XCTAssertEqual(calendar.frame.width, 340, accuracy: 1.5)
        XCTAssertEqual(calendar.frame.height, 393, accuracy: 1.5)
    }

    @MainActor
    func testCardsUseFigmaFixedSize() throws {
        let app = launchQuoteList()
        let firstCard = app.otherElements["quoteList.cardFrame.1"]
        let secondCard = app.otherElements["quoteList.cardFrame.2"]

        XCTAssertTrue(firstCard.waitForExistence(timeout: 2))
        XCTAssertTrue(secondCard.waitForExistence(timeout: 2))
        XCTAssertEqual(firstCard.frame.width, 150, accuracy: 0.5)
        XCTAssertEqual(firstCard.frame.height, 200, accuracy: 0.5)
        XCTAssertEqual(secondCard.frame.minX - firstCard.frame.maxX, 20, accuracy: 0.5)
    }

    @MainActor
    func testDarkCardsKeepTheFigmaTwoColumnFrame() throws {
        let app = launchQuoteList(dark: true)
        let firstCard = app.otherElements["quoteList.cardFrame.1"]
        let secondCard = app.otherElements["quoteList.cardFrame.2"]

        XCTAssertTrue(firstCard.waitForExistence(timeout: 2))
        XCTAssertTrue(secondCard.waitForExistence(timeout: 2))
        XCTAssertEqual(firstCard.frame.minX, 20, accuracy: 0.5)
        XCTAssertEqual(secondCard.frame.minX, 190, accuracy: 0.5)
        XCTAssertEqual(firstCard.frame.width, 150, accuracy: 0.5)
        XCTAssertEqual(secondCard.frame.width, 150, accuracy: 0.5)
        XCTAssertEqual(firstCard.frame.height, 200, accuracy: 0.5)
        XCTAssertEqual(secondCard.frame.height, 200, accuracy: 0.5)
    }

    @MainActor
    func testDateSelectorRendersInLightAndDarkThemes() throws {
        let lightApp = launchQuoteList()
        XCTAssertTrue(lightApp.buttons["quoteList.dateSelector"].waitForExistence(timeout: 2))
        attachScreenshot(lightApp)

        let darkApp = launchQuoteList(dark: true)
        XCTAssertTrue(darkApp.buttons["quoteList.dateSelector"].waitForExistence(timeout: 2))
        attachScreenshot(darkApp)
    }

    @MainActor
    func testGeneralAndFilteredEmptyStatesUseDistinctFigmaCopy() throws {
        let generalApp = launchQuoteList(arguments: ["-uiTestingQuoteListGeneralEmpty"])
        XCTAssertTrue(generalApp.images["quoteList.empty.general"].waitForExistence(timeout: 2))
        XCTAssertTrue(generalApp.staticTexts["텅 비었어요!"].exists)
        let generalIcon = generalApp.images["quoteList.empty.general"]
        XCTAssertTrue(generalIcon.waitForExistence(timeout: 2))
        XCTAssertEqual(generalIcon.frame.size, CGSize(width: 100, height: 100))
        attachScreenshot(generalApp)

        let filteredApp = launchQuoteList(arguments: ["-uiTestingQuoteListFilteredEmpty"])
        XCTAssertTrue(filteredApp.images["quoteList.empty.searchResult"].waitForExistence(timeout: 2))
        XCTAssertTrue(filteredApp.staticTexts["조회 결과가 없어요 :("].exists)
        XCTAssertTrue(filteredApp.staticTexts["기간을 다시 선택해주세요."].exists)
        attachScreenshot(filteredApp)
    }

    @MainActor
    private func launchQuoteList(dark: Bool = false, arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingQuoteList"] + (dark ? ["-uiTestingDark"] : []) + arguments
        app.launch()
        return app
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

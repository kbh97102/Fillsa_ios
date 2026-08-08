import XCTest

final class QuoteListUITests: XCTestCase {
    @MainActor
    func testDateOverlayDoesNotMoveCardsAndClosesFromOutsideTap() throws {
        let app = launchQuoteList()
        let selector = app.buttons["quoteList.dateSelector"]
        let firstCard = app.otherElements["quoteList.card.1"]

        XCTAssertTrue(selector.waitForExistence(timeout: 2))
        XCTAssertTrue(firstCard.waitForExistence(timeout: 2))
        let originalFrame = firstCard.frame

        selector.tap()
        XCTAssertTrue(app.otherElements["quoteList.durationCalendar"].waitForExistence(timeout: 2))
        XCTAssertEqual(firstCard.frame.minY, originalFrame.minY, accuracy: 0.5)

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.85)).tap()
        XCTAssertFalse(app.otherElements["quoteList.durationCalendar"].waitForExistence(timeout: 1))
    }

    @MainActor
    func testCardsUseFigmaFixedSize() throws {
        let app = launchQuoteList()
        let firstCard = app.otherElements["quoteList.card.1"]
        let secondCard = app.otherElements["quoteList.card.2"]

        XCTAssertTrue(firstCard.waitForExistence(timeout: 2))
        XCTAssertTrue(secondCard.waitForExistence(timeout: 2))
        XCTAssertEqual(firstCard.frame.width, 150, accuracy: 0.5)
        XCTAssertEqual(firstCard.frame.height, 200, accuracy: 0.5)
        XCTAssertEqual(secondCard.frame.minX - firstCard.frame.maxX, 20, accuracy: 0.5)
    }

    @MainActor
    func testDateSelectorRendersInLightAndDarkThemes() throws {
        let lightApp = launchQuoteList()
        XCTAssertTrue(lightApp.buttons["quoteList.dateSelector"].waitForExistence(timeout: 2))
        add(XCTAttachment(screenshot: lightApp.screenshot()))

        let darkApp = launchQuoteList(dark: true)
        XCTAssertTrue(darkApp.buttons["quoteList.dateSelector"].waitForExistence(timeout: 2))
        add(XCTAttachment(screenshot: darkApp.screenshot()))
    }

    @MainActor
    func testGeneralAndFilteredEmptyStatesUseDistinctFigmaCopy() throws {
        let generalApp = launchQuoteList(arguments: ["-uiTestingQuoteListGeneralEmpty"])
        XCTAssertTrue(generalApp.otherElements["quoteList.empty.general"].waitForExistence(timeout: 2))
        XCTAssertTrue(generalApp.staticTexts["텅 비었어요!"].exists)

        let filteredApp = launchQuoteList(arguments: ["-uiTestingQuoteListFilteredEmpty"])
        XCTAssertTrue(filteredApp.otherElements["quoteList.empty.searchResult"].waitForExistence(timeout: 2))
        XCTAssertTrue(filteredApp.staticTexts["조회 결과가 없어요 :("].exists)
        XCTAssertTrue(filteredApp.staticTexts["기간을 다시 선택해주세요."].exists)
    }

    @MainActor
    private func launchQuoteList(dark: Bool = false, arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestingQuoteList"] + (dark ? ["-uiTestingDark"] : []) + arguments
        app.launch()
        return app
    }
}

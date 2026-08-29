import XCTest

final class HomeUITests: XCTestCase {
    @MainActor
    func testHomeRendersTheFigmaQuestionAndAnswerState() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-home"]
        app.launch()

        XCTAssertTrue(app.otherElements["home.quoteCard"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["오늘의 질문"].exists)
        XCTAssertTrue(app.textViews["home.answer"].exists)
        XCTAssertTrue(app.buttons["home.recordAnswer"].exists)
        XCTAssertTrue(app.buttons["home.registerImage"].exists)
    }

    @MainActor
    func testHomeFixtureStaysLightAfterTheAppStartupTask() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-home"]
        app.launch()

        XCTAssertTrue(app.otherElements["home.quoteCard"].waitForExistence(timeout: 2))
        let startupSettled = expectation(description: "startup task settled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startupSettled.fulfill() }
        wait(for: [startupSettled], timeout: 1)

        let image = app.screenshot().image
        XCTAssertEqual(rgb(at: CGPoint(x: 10, y: 100), in: image, appFrame: app.frame), "255,239,204")
    }

    private func rgb(at point: CGPoint, in image: UIImage, appFrame: CGRect) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let scale = CGFloat(cgImage.width) / appFrame.width
        let x = Int((point.x * scale).rounded())
        let y = Int((point.y * scale).rounded())
        guard x >= 0, x < cgImage.width, y >= 0, y < cgImage.height,
              let data = cgImage.dataProvider?.data else { return nil }
        let bytes = CFDataGetBytePtr(data)
        let offset = y * cgImage.bytesPerRow + x * 4
        return "\(bytes![offset]),\(bytes![offset + 1]),\(bytes![offset + 2])"
    }
}

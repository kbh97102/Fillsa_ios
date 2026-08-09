import UIKit
import XCTest

final class AlertUITests: XCTestCase {
    @MainActor
    func testDarkAlertSettingsUsesWhiteNotificationText() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-my-page",
            "-ui-testing-my-page-member",
            "-ui-testing-my-page-dark"
        ]
        app.launch()

        let alertMenu = app.buttons["myPage.alertMenu"]
        XCTAssertTrue(alertMenu.waitForExistence(timeout: 2))
        alertMenu.tap()

        let title = app.staticTexts["오늘의 필사 알림"]
        let description = app.staticTexts["매일 오전 9시에 새로운 문장 알림을 받을 수 있습니다."]
        XCTAssertTrue(title.waitForExistence(timeout: 2))
        XCTAssertTrue(description.exists)

        let screenshot = app.screenshot().image
        XCTAssertGreaterThan(whitePixelCount(in: title.frame, image: screenshot, appFrame: app.frame), 20)
        XCTAssertGreaterThan(whitePixelCount(in: description.frame, image: screenshot, appFrame: app.frame), 20)
    }

    private func whitePixelCount(in area: CGRect, image: UIImage, appFrame: CGRect) -> Int {
        guard let cgImage = image.cgImage else {
            XCTFail("Unable to read Alert screenshot pixels")
            return 0
        }

        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            XCTFail("Unable to rasterize Alert screenshot")
            return 0
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let scale = CGFloat(width) / appFrame.width
        let bounds = area.applying(CGAffineTransform(scaleX: scale, y: scale)).integral
        var matches = 0

        for y in max(0, Int(bounds.minY))..<min(height, Int(bounds.maxY)) {
            for x in max(0, Int(bounds.minX))..<min(width, Int(bounds.maxX)) {
                let offset = (y * width + x) * 4
                if pixels[offset] >= 252, pixels[offset + 1] >= 252, pixels[offset + 2] >= 252 {
                    matches += 1
                }
            }
        }
        return matches
    }
}

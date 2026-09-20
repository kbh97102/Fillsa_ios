import UIKit
import XCTest

final class BottomNavigationUITests: XCTestCase {
    @MainActor
    func testDarkBottomNavigationUsesThreeFigmaTabsAndUpdatesSelection() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-home", "ui-testing-theme-dark"]
        app.launch()

        let home = app.buttons["Home"]
        let calendar = app.buttons["Calendar"]
        XCTAssertTrue(home.waitForExistence(timeout: 2))
        XCTAssertTrue(calendar.waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["My page"].exists)
        XCTAssertFalse(app.buttons["List"].exists)

        let screenshot = app.screenshot().image
        let attachment = XCTAttachment(image: screenshot)
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertGreaterThan(
            pixelCount(
                in: iconArea(of: home),
                image: screenshot,
                appFrame: app.frame,
                near: .white
            ),
            40
        )
        XCTAssertGreaterThan(
            pixelCount(
                in: iconArea(of: calendar),
                image: screenshot,
                appFrame: app.frame,
                near: UIColor(red: 158 / 255, green: 158 / 255, blue: 158 / 255, alpha: 1)
            ),
            40
        )

        calendar.tap()
        XCTAssertTrue(app.descendants(matching: .any)["calendarMonthCard"].waitForExistence(timeout: 2))
        let selectedCalendarScreenshot = app.screenshot().image
        let selectedCalendarAttachment = XCTAttachment(image: selectedCalendarScreenshot)
        selectedCalendarAttachment.lifetime = .keepAlways
        add(selectedCalendarAttachment)
        XCTAssertGreaterThan(
            pixelCount(
                in: iconArea(of: home),
                image: selectedCalendarScreenshot,
                appFrame: app.frame,
                near: UIColor(red: 158 / 255, green: 158 / 255, blue: 158 / 255, alpha: 1)
            ),
            40
        )
        XCTAssertGreaterThan(
            pixelCount(
                in: iconArea(of: calendar),
                image: selectedCalendarScreenshot,
                appFrame: app.frame,
                near: .white
            ),
            40
        )
    }

    private func iconArea(of element: XCUIElement) -> CGRect {
        CGRect(x: element.frame.minX, y: element.frame.minY, width: element.frame.width, height: 36)
    }

    private func pixelCount(
        in area: CGRect,
        image: UIImage,
        appFrame: CGRect,
        near color: UIColor
    ) -> Int {
        guard let cgImage = image.cgImage else {
            XCTFail("Unable to read bottom navigation screenshot pixels")
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
            XCTFail("Unable to rasterize bottom navigation screenshot")
            return 0
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let scale = CGFloat(width) / appFrame.width
        let bounds = area.applying(CGAffineTransform(scaleX: scale, y: scale)).integral
        var targetRed: CGFloat = 0
        var targetGreen: CGFloat = 0
        var targetBlue: CGFloat = 0
        var targetAlpha: CGFloat = 0
        guard color.getRed(
            &targetRed,
            green: &targetGreen,
            blue: &targetBlue,
            alpha: &targetAlpha
        ) else {
            XCTFail("Unable to resolve expected bottom navigation color")
            return 0
        }
        let targetRGB = [Int(targetRed * 255), Int(targetGreen * 255), Int(targetBlue * 255)]
        var matches = 0

        for y in max(0, Int(bounds.minY))..<min(height, Int(bounds.maxY)) {
            for x in max(0, Int(bounds.minX))..<min(width, Int(bounds.maxX)) {
                let offset = (y * width + x) * 4
                let red = Int(pixels[offset])
                let green = Int(pixels[offset + 1])
                let blue = Int(pixels[offset + 2])

                if abs(red - targetRGB[0]) <= 3,
                   abs(green - targetRGB[1]) <= 3,
                   abs(blue - targetRGB[2]) <= 3 {
                    matches += 1
                }
            }
        }

        return matches
    }
}

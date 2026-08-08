import XCTest
import UIKit

final class CalendarUITests: XCTestCase {
    @MainActor
    func testLightCalendarShowsStreakAndHidesBottomNavigation() throws {
        let app = launchCalendar(theme: "light")

        XCTAssertTrue(app.descendants(matching: .any)["calendarMonthCard"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["calendarStreak"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["bottomNavigation"].exists)
    }

    @MainActor
    func testDarkCalendarHidesStreakAndShowsBottomNavigation() throws {
        let app = launchCalendar(theme: "dark")

        XCTAssertTrue(app.descendants(matching: .any)["calendarMonthCard"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.descendants(matching: .any)["calendarStreak"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["bottomNavigation"].exists)
    }

    @MainActor
    func testCalendarCardsRemainFigmaWidthAndCenteredOnWideDevice() throws {
        let app = launchCalendar(theme: "light")
        XCTAssertTrue(app.descendants(matching: .any)["calendarMonthCard"].waitForExistence(timeout: 3))

        let raster = rasterize(app.screenshot().image)
        let scale = CGFloat(raster.width) / app.frame.width
        let expectedX = (app.frame.width - 320) / 2

        let monthBounds = coloredBounds(
            in: raster,
            yRange: Int(110 * scale)...Int(500 * scale),
            matches: { red, green, blue in red > 220 && green > 150 && green < 240 && blue < 160 }
        )
        let quoteBounds = longestRun(
            in: raster,
            y: Int(620 * scale),
            matches: { red, green, blue in red > 230 && green > 230 && blue > 230 }
        )

        XCTAssertEqual(CGFloat(monthBounds.width) / scale, 320, accuracy: 1.5)
        XCTAssertEqual(CGFloat(monthBounds.minX) / scale, expectedX, accuracy: 1.5)
        XCTAssertEqual(CGFloat(quoteBounds.width) / scale, 320, accuracy: 1.5)
        XCTAssertEqual(CGFloat(quoteBounds.minX) / scale, expectedX, accuracy: 1.5)
    }

    @MainActor
    private func rasterize(_ image: UIImage) -> (pixels: [UInt8], width: Int, height: Int) {
        guard let cgImage = image.cgImage else {
            XCTFail("Unable to rasterize UI screenshot")
            return ([], 0, 0)
        }

        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (pixels, width, height)
    }

    private func coloredBounds(
        in raster: (pixels: [UInt8], width: Int, height: Int),
        yRange: ClosedRange<Int>,
        matches: (UInt8, UInt8, UInt8) -> Bool
    ) -> (minX: Int, width: Int) {
        var minX = raster.width
        var maxX = 0
        for y in yRange where y < raster.height {
            for x in 0..<raster.width {
                let index = (y * raster.width + x) * 4
                if matches(raster.pixels[index], raster.pixels[index + 1], raster.pixels[index + 2]) {
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                }
            }
        }
        return (minX, maxX - minX + 1)
    }

    private func longestRun(
        in raster: (pixels: [UInt8], width: Int, height: Int),
        y: Int,
        matches: (UInt8, UInt8, UInt8) -> Bool
    ) -> (minX: Int, width: Int) {
        var best = (minX: 0, width: 0)
        var runStart: Int?
        for x in 0..<raster.width {
            let index = (y * raster.width + x) * 4
            if matches(raster.pixels[index], raster.pixels[index + 1], raster.pixels[index + 2]) {
                runStart = runStart ?? x
            } else if let start = runStart {
                if x - start > best.width {
                    best = (start, x - start)
                }
                runStart = nil
            }
        }
        if let runStart, raster.width - runStart > best.width {
            best = (runStart, raster.width - runStart)
        }
        return best
    }

    @MainActor
    private func launchCalendar(theme: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["ui-testing-calendar", "ui-testing-theme-\(theme)"]
        app.launch()
        return app
    }
}

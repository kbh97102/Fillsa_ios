import UIKit
import XCTest

final class NoticeDetailUITests: XCTestCase {
    @MainActor
    func testDarkNoticeDetailUsesFigmaTypographyColors() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-notice-detail", "-ui-testing-notice-detail-dark"]
        app.launch()

        let title = app.staticTexts["noticeDetail.title"]
        let date = app.staticTexts["noticeDetail.date"]
        let content = app.staticTexts["noticeDetail.content"]

        XCTAssertTrue(title.waitForExistence(timeout: 2))
        XCTAssertTrue(date.exists)
        XCTAssertTrue(content.exists)

        let screenshot = app.screenshot().image
        let attachment = XCTAttachment(image: screenshot)
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertGreaterThan(pixelCount(in: title.frame, image: screenshot, appFrame: app.frame, near: .white), 20)
        XCTAssertGreaterThan(
            pixelCount(
                in: date.frame,
                image: screenshot,
                appFrame: app.frame,
                near: UIColor(red: 224 / 255, green: 224 / 255, blue: 224 / 255, alpha: 1)
            ),
            10
        )
        XCTAssertGreaterThan(pixelCount(in: content.frame, image: screenshot, appFrame: app.frame, near: .white), 20)
    }

    private func pixelCount(
        in area: CGRect,
        image: UIImage,
        appFrame: CGRect,
        near color: UIColor
    ) -> Int {
        guard let cgImage = image.cgImage else {
            XCTFail("Unable to read Notice Detail screenshot pixels")
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
            XCTFail("Unable to rasterize Notice Detail screenshot")
            return 0
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let scale = CGFloat(width) / appFrame.width
        let bounds = area.applying(CGAffineTransform(scaleX: scale, y: scale)).integral
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            XCTFail("Unable to resolve expected Notice Detail color")
            return 0
        }
        let expected = [Int(red * 255), Int(green * 255), Int(blue * 255)]
        var matches = 0

        for y in max(0, Int(bounds.minY))..<min(height, Int(bounds.maxY)) {
            for x in max(0, Int(bounds.minX))..<min(width, Int(bounds.maxX)) {
                let offset = (y * width + x) * 4
                if abs(Int(pixels[offset]) - expected[0]) <= 3,
                   abs(Int(pixels[offset + 1]) - expected[1]) <= 3,
                   abs(Int(pixels[offset + 2]) - expected[2]) <= 3 {
                    matches += 1
                }
            }
        }
        return matches
    }
}

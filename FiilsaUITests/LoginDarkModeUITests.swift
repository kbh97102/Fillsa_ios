import XCTest
import UIKit

final class LoginDarkModeUITests: XCTestCase {
    @MainActor
    func testDarkLoginUsesFigmaLogoAndButtonColors() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-login", "-ui-testing-login-dark"]
        app.launch()

        let logo = app.images["login.logo.dark"]
        let apple = app.buttons["login.apple"]
        let kakao = app.buttons["login.kakao"]
        let guest = app.buttons["login.guest"]

        XCTAssertTrue(logo.waitForExistence(timeout: 3))
        XCTAssertTrue(apple.exists)
        XCTAssertTrue(kakao.exists)
        XCTAssertTrue(guest.exists)

        let screenshot = app.screenshot().image
        assertColor(at: CGPoint(x: 80, y: 380), in: screenshot, equals: .white)
        assertColor(at: CGPoint(x: 80, y: 330), in: screenshot, equals: UIColor(red: 1, green: 230 / 255, blue: 0, alpha: 1))
        assertColor(at: CGPoint(x: 80, y: 435), in: screenshot, equals: UIColor(red: 92 / 255, green: 101 / 255, blue: 1, alpha: 1))
    }

    @MainActor
    private func assertColor(at point: CGPoint, in image: UIImage, equals expected: UIColor) {
        var actualRed: CGFloat = 0
        var actualGreen: CGFloat = 0
        var actualBlue: CGFloat = 0
        var actualAlpha: CGFloat = 0
        var expectedRed: CGFloat = 0
        var expectedGreen: CGFloat = 0
        var expectedBlue: CGFloat = 0
        var expectedAlpha: CGFloat = 0
        XCTAssertTrue(color(at: point, in: image).getRed(&actualRed, green: &actualGreen, blue: &actualBlue, alpha: &actualAlpha))
        XCTAssertTrue(expected.getRed(&expectedRed, green: &expectedGreen, blue: &expectedBlue, alpha: &expectedAlpha))
        XCTAssertEqual(actualRed, expectedRed, accuracy: 0.01)
        XCTAssertEqual(actualGreen, expectedGreen, accuracy: 0.01)
        XCTAssertEqual(actualBlue, expectedBlue, accuracy: 0.01)
        XCTAssertEqual(actualAlpha, expectedAlpha, accuracy: 0.01)
    }

    @MainActor
    private func color(at point: CGPoint, in image: UIImage) -> UIColor {
        guard let cgImage = image.cgImage else {
            XCTFail("Unable to read login screenshot")
            return .clear
        }

        let scale = CGFloat(cgImage.width) / UIScreen.main.bounds.width
        let x = Int(point.x * scale)
        let y = Int(point.y * scale)
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow
        let offset = y * bytesPerRow + x * bytesPerPixel
        guard let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data),
              offset + 3 < CFDataGetLength(data) else {
            XCTFail("Unable to read login screenshot pixels")
            return .clear
        }

        return UIColor(
            red: CGFloat(bytes[offset]) / 255,
            green: CGFloat(bytes[offset + 1]) / 255,
            blue: CGFloat(bytes[offset + 2]) / 255,
            alpha: CGFloat(bytes[offset + 3]) / 255
        )
    }
}

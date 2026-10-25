import XCTest
import UIKit

final class LoginDarkModeUITests: XCTestCase {
    @MainActor
    func testLightLoginShowsThreeProvidersAndLinkedTerms() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-login"]
        app.launch()
        XCTAssertTrue(app.images["login.logo.light"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["login.google"].exists)
        XCTAssertTrue(app.links["이용약관"].exists)
        XCTAssertTrue(app.links["개인정보 처리방침"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "login-light-full-frame"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testKakaoLoginShowsInstallKakaoTalkDialogWhenUnavailable() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing-login"]
        app.launch()

        let kakao = app.buttons["login.kakao"]
        XCTAssertTrue(kakao.waitForExistence(timeout: 3))
        kakao.tap()

        let message = app.staticTexts["카카오톡 설치 후 이용해주세요."]
        XCTAssertTrue(message.waitForExistence(timeout: 2))

        let confirm = app.buttons["확인"]
        XCTAssertTrue(confirm.exists)
        confirm.tap()
        XCTAssertFalse(message.exists)
    }

    @MainActor
    func testDarkLoginShowsMemberButtonsWithoutGuestButton() throws {
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
        XCTAssertFalse(guest.exists)
        let google = app.buttons["login.google"]
        XCTAssertTrue(google.exists)
        XCTAssertLessThan(apple.frame.midY, kakao.frame.midY)
        XCTAssertLessThan(kakao.frame.midY, google.frame.midY)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "login-dark-full-frame"
        attachment.lifetime = .keepAlways
        add(attachment)

        let screenshot = app.screenshot().image
        assertColor(at: CGPoint(x: apple.frame.minX + 12, y: apple.frame.midY), in: screenshot, appFrame: app.frame, equals: .white)
        assertColor(at: CGPoint(x: kakao.frame.minX + 12, y: kakao.frame.midY), in: screenshot, appFrame: app.frame, equals: UIColor(red: 1, green: 230 / 255, blue: 0, alpha: 1))
    }

    @MainActor
    private func assertColor(at point: CGPoint, in image: UIImage, appFrame: CGRect, equals expected: UIColor) {
        var actualRed: CGFloat = 0
        var actualGreen: CGFloat = 0
        var actualBlue: CGFloat = 0
        var actualAlpha: CGFloat = 0
        var expectedRed: CGFloat = 0
        var expectedGreen: CGFloat = 0
        var expectedBlue: CGFloat = 0
        var expectedAlpha: CGFloat = 0
        XCTAssertTrue(color(at: point, in: image, appFrame: appFrame).getRed(&actualRed, green: &actualGreen, blue: &actualBlue, alpha: &actualAlpha))
        XCTAssertTrue(expected.getRed(&expectedRed, green: &expectedGreen, blue: &expectedBlue, alpha: &expectedAlpha))
        XCTAssertEqual(actualRed, expectedRed, accuracy: 0.01)
        XCTAssertEqual(actualGreen, expectedGreen, accuracy: 0.01)
        XCTAssertEqual(actualBlue, expectedBlue, accuracy: 0.01)
        XCTAssertEqual(actualAlpha, expectedAlpha, accuracy: 0.01)
    }

    @MainActor
    private func color(at point: CGPoint, in image: UIImage, appFrame: CGRect) -> UIColor {
        guard let cgImage = image.cgImage else {
            XCTFail("Unable to read login screenshot")
            return .clear
        }

        let scale = CGFloat(cgImage.width) / appFrame.width
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

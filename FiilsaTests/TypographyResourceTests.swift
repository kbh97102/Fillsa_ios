import UIKit
import XCTest
import SwiftUI
@testable import Fiilsa

@MainActor
final class TypographyResourceTests: XCTestCase {
    func testPretendardRegularLoadsFromAppBundle() throws {
        let font = try XCTUnwrap(UIFont(name: "Pretendard-Regular", size: 20))
        XCTAssertEqual(font.fontName, "Pretendard-Regular")
    }

    func testPretendardBoldLoadsFromAppBundle() throws {
        let font = try XCTUnwrap(UIFont(name: "Pretendard-Bold", size: 16))
        XCTAssertEqual(font.fontName, "Pretendard-Bold")
        for scheme in [ColorScheme.light, .dark] {
            for width in [320.0, 350.0] {
                let content = VStack(spacing: 20) {
                    TypingPromptSection()
                    TypingQuoteBodySection(
                        quote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
                        write: .constant("상황을 가장 잘 "),
                        isInputEnabled: false
                    )
                }
                .frame(width: width)
                .background(scheme == .dark ? FillsaColor.gray700 : .white)
                .environment(\.colorScheme, scheme)
                let renderer = ImageRenderer(content: content)
                renderer.scale = 3
                let image = try XCTUnwrap(renderer.uiImage)
                let attachment = XCTAttachment(image: image)
                attachment.name = "typing-components-\(scheme)-\(Int(width))"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }
}

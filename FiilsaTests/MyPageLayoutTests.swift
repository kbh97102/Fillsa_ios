import XCTest
@testable import Fiilsa

final class MyPageLayoutTests: XCTestCase {
    func test_figmaFixedDimensionsMatchMyPageFixedElements() {
        XCTAssertEqual(MyPageLayout.logoSize.width, 64)
        XCTAssertEqual(MyPageLayout.logoSize.height, 30)
        XCTAssertEqual(MyPageLayout.memberCardHeight, 80)
        XCTAssertEqual(MyPageLayout.guestCardHeight, 114)
        XCTAssertEqual(MyPageLayout.menuHeight, 60)
        XCTAssertEqual(MyPageLayout.themeDialogSize.width, 320)
        XCTAssertEqual(MyPageLayout.themeDialogSize.height, 237)
        XCTAssertEqual(MyPageLayout.confirmButtonSize.width, 296)
        XCTAssertEqual(MyPageLayout.confirmButtonSize.height, 49)
    }
}

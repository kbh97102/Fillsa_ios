import XCTest
@testable import Fiilsa

final class MyPageLayoutTests: XCTestCase {
    func test_figmaFixedDimensionsMatchMyPageFrames() {
        XCTAssertEqual(MyPageLayout.logoSize.width, 64)
        XCTAssertEqual(MyPageLayout.logoSize.height, 30)
        XCTAssertEqual(MyPageLayout.memberCardSize.width, 320)
        XCTAssertEqual(MyPageLayout.memberCardSize.height, 80)
        XCTAssertEqual(MyPageLayout.guestCardSize.width, 320)
        XCTAssertEqual(MyPageLayout.guestCardSize.height, 114)
        XCTAssertEqual(MyPageLayout.menuSize.width, 320)
        XCTAssertEqual(MyPageLayout.menuSize.height, 60)
        XCTAssertEqual(MyPageLayout.themeDialogSize.width, 320)
        XCTAssertEqual(MyPageLayout.themeDialogSize.height, 237)
        XCTAssertEqual(MyPageLayout.confirmButtonSize.width, 296)
        XCTAssertEqual(MyPageLayout.confirmButtonSize.height, 49)
    }
}

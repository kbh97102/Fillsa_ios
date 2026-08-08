import UIKit
import XCTest
@testable import Fiilsa

final class MyPageArrowAssetTests: XCTestCase {
    func test_darkTrailingArrowIncludesFigmaWhiteOverlayAsset() {
        XCTAssertEqual(MyPageArrowAsset.darkOverlay, "my_page_arrow_dark_overlay")
        XCTAssertNotNil(UIImage(named: MyPageArrowAsset.darkOverlay))
    }
}

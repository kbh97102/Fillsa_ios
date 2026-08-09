import ComposableArchitecture
import XCTest
@testable import Fiilsa

@MainActor
final class LoginFeatureTests: XCTestCase {
    func testKakaoTapShowsComingSoonDialogWithoutStartingLogin() async {
        let store = TestStore(initialState: LoginFeature.State()) {
            LoginFeature()
        }

        await store.send(.kakaoTapped) {
            $0.isKakaoComingSoonDialogPresented = true
        }

        await store.send(.kakaoComingSoonDialogDismissed) {
            $0.isKakaoComingSoonDialogPresented = false
        }
    }
}

import ComposableArchitecture
import XCTest
@testable import Fiilsa

@MainActor
final class AppFeatureTests: XCTestCase {
    func test_accountDeletionFromMyPageReturnsToFreshHomeState() async {
        var state = AppFeature.State()
        state.screen = .main
        state.selectedTab = .myPage
        state.myPage = MyPageFeature.State(isLoggedIn: true, userName: "필사")
        state.alert = AlertFeature.State(isAlarmOn: true)

        let store = TestStore(initialState: state) {
            AppFeature()
        }
        store.exhaustivity = .off

        await store.send(.myPage(.delegate(.resignCompleted))) {
            $0.selectedTab = .home
            $0.myPage = MyPageFeature.State(selectedTheme: $0.selectedTheme)
            $0.alert = AlertFeature.State()
        }
    }
}

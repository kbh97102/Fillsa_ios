import ComposableArchitecture
import XCTest
@testable import Fiilsa

@MainActor
final class AppFeatureTests: XCTestCase {
    func test_homeAnswerCTASeedsCappedTypingDraftWhileEmptyAnswerUsesExistingTypingRoute() async {
        let answer = String(repeating: "👨🏽‍💻", count: 201)
        let cappedAnswer = String(repeating: "👨🏽‍💻", count: 200)
        var state = AppFeature.State()
        state.home.quote = DailyQuote(
            likeYn: "N",
            dailyQuoteSeq: 42,
            korQuote: "명언",
            engQuote: "Quote",
            korAuthor: "작가",
            engAuthor: "Author"
        )

        let store = TestStore(initialState: state) {
            AppFeature()
        }
        store.exhaustivity = .off

        await store.send(.homeAnswerTypingSelected(answer))
        XCTAssertEqual(store.state.screen, .typing)
        XCTAssertEqual(store.state.typing.dailyQuoteSeq, 42)
        XCTAssertEqual(store.state.typing.korTyping, cappedAnswer)
        XCTAssertEqual(store.state.typing.engTyping, "")

        await store.send(.homeTypingSelected)
        XCTAssertEqual(store.state.screen, .typing)
        XCTAssertEqual(store.state.typing.korTyping, "")
        XCTAssertEqual(store.state.typing.engTyping, "")
    }

    func test_prefilledTypingDraftDoesNotReloadAndOverwriteTheHomeAnswer() async {
        let store = TestStore(
            initialState: TypingFeature.State(dailyQuoteSeq: 42, korTyping: "홈 답변")
        ) {
            TypingFeature()
        }

        await store.send(.onAppear) {
            $0.hasLoaded = true
        }
    }

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

import ComposableArchitecture
import XCTest
@testable import Fiilsa

@MainActor
final class AppFeatureTests: XCTestCase {
    func test_homeAnswerCTAOpensTheDedicatedEditorWithoutChangingQuoteTyping() async {
        let answer = String(repeating: "👨🏽‍💻", count: 201)
        let cappedAnswer = String(repeating: "👨🏽‍💻", count: 200)
        var state = AppFeature.State()
        state.home.date = ISO8601DateFormatter().date(from: "2026-08-29T12:00:00Z")!
        state.typing.korTyping = "기존 인용문 필사"

        let store = TestStore(initialState: state) {
            AppFeature()
        }
        store.exhaustivity = .off

        await store.send(.homeAnswerSelected(answer))

        XCTAssertEqual(store.state.screen, .homeAnswerEditor)
        XCTAssertEqual(store.state.homeAnswerEditor.answer, cappedAnswer)
        XCTAssertEqual(
            store.state.homeAnswerEditor.dateKey,
            HomeCompletionDateKey.make(for: state.home.date)
        )
        XCTAssertEqual(store.state.homeAnswerEditor.question, HomeQuestionAnswerContent.question)
        XCTAssertEqual(store.state.typing.korTyping, "기존 인용문 필사")
    }

    func test_quoteTypingLoadsItsExistingTranscriptRatherThanTreatingItAsAHomeAnswer() async {
        let response = MemberTypingQuoteResponse(
            korQuote: "명언",
            engQuote: "Quote",
            typingKorQuote: "서버에 저장된 필사",
            typingEngQuote: "Saved transcript",
            likeYn: "Y"
        )
        let store = TestStore(
            initialState: TypingFeature.State(dailyQuoteSeq: 42, korTyping: "잘못 주입된 홈 답변")
        ) {
            TypingFeature()
        } withDependencies: {
            $0.sessionClient.isLoggedIn = { true }
            $0.typingClient.getTyping = { _ in response }
        }

        await store.send(.onAppear)
        await store.receive(.typingLoaded(.success(response))) {
            $0.korQuote = "명언"
            $0.engQuote = "Quote"
            $0.korTyping = "서버에 저장된 필사"
            $0.engTyping = "Saved transcript"
            $0.likeYn = "Y"
            $0.hasLoaded = true
        }
        await store.finish()
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

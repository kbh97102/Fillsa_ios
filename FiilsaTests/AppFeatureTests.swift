import ComposableArchitecture
import XCTest
@testable import Fiilsa

@MainActor
final class AppFeatureTests: XCTestCase {
    func test_firstLoginShowsGuideAndCompletionSurvivesAnotherLogin() async {
        let completed = LockIsolated(false)
        var state = AppFeature.State()
        state.screen = .login
        state.memberAccess = .loginRequired
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.sessionClient.isOnboardingCompleted = { completed.value }
            $0.sessionClient.completeOnboarding = { completed.setValue(true) }
            $0.hiddenPopupClient.clearAllIfNeeded = {}
            $0.commonClient.getPopupGeneral = { throw ErrorResponse.defaultError }
            $0.commonClient.getPopupVersionUpdate = { _ in throw ErrorResponse.defaultError }

        }
        store.exhaustivity = .off
        await store.send(.login(.delegate(.moveHome)))
        await store.receive(.onboardingStatusLoaded(false))
        XCTAssertEqual(store.state.screen, .onboardingGuide)
        await store.send(.onboardingGuideFinished)
        await store.receive(.onboardingCompletionSaved)
        await store.finish()
        XCTAssertTrue(completed.value)
        XCTAssertEqual(store.state.screen, .main)
        await store.send(.myPage(.delegate(.loggedOut)))
        await store.send(.login(.delegate(.moveHome)))
        await store.receive(.onboardingStatusLoaded(true))
        await store.finish()
        XCTAssertEqual(store.state.screen, .main)
    }

    func test_lateOnboardingResponseAfterLogoutCannotOpenHome() async {
        var state = AppFeature.State()
        state.memberAccess = .loginRequired
        state.screen = .login
        let store = TestStore(initialState: state) { AppFeature() }
        await store.send(.onboardingStatusLoaded(true))
        await store.send(.onboardingCompletionSaved)
    }

    func test_guestGuideCompletionCannotOpenHome() async {
        var state = AppFeature.State()
        state.screen = .onboardingGuide
        let store = TestStore(initialState: state) { AppFeature() }
        store.exhaustivity = .off

        await store.send(.onboardingGuideFinished)

        XCTAssertEqual(store.state.screen, .login)
    }

    func test_lateSplashHomeResultCannotReopenMemberScreen() async {
        var state = AppFeature.State()
        state.screen = .login
        state.memberAccess = .loginRequired
        let store = TestStore(initialState: state) { AppFeature() }
        store.exhaustivity = .off

        await store.send(.splash(.delegate(.move(.home))))

        XCTAssertEqual(store.state.screen, .login)
        XCTAssertEqual(store.state.memberAccess, .loginRequired)
    }

    func test_accountDeletionReturnsToLoginInsteadOfGuestHome() async {
        var state = AppFeature.State()
        state.screen = .main
        state.selectedTab = .myPage
        state.home.answerDraft = "private answer"
        let store = TestStore(initialState: state) { AppFeature() }
        store.exhaustivity = .off

        await store.send(.myPage(.delegate(.resignCompleted)))

        XCTAssertEqual(store.state.screen, .login)
        XCTAssertEqual(store.state.home.answerDraft, "")
    }

    func test_lateNavigationAfterLogoutCannotReopenHome() async {
        var state = AppFeature.State()
        state.screen = .login
        let store = TestStore(initialState: state) { AppFeature() }
        store.exhaustivity = .off

        await store.send(.selectedTabChanged(.home))
        await store.send(.notice(.delegate(.back)))
        await store.send(.homeTypingSelected)

        XCTAssertEqual(store.state.screen, .login)
    }

    func test_sessionExpirationReturnsMemberToLogin() async {
        var state = AppFeature.State()
        state.memberAccess = .member
        state.screen = .main
        state.home.answerDraft = "private answer"
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.sessionClient.getAccessToken = { "" }
            $0.sessionClient.logout = {}
        }
        store.exhaustivity = .off

        await store.send(.sessionExpired(SessionExpirationEvent(statusCode: 401, reason: .missingRefreshToken)))
        await store.receive(.sessionExpiredHandled)

        XCTAssertEqual(store.state.screen, .login)
        XCTAssertEqual(store.state.home.answerDraft, "")
    }

    func test_unidentifiedExpirationDoesNotClearNewSession() async {
        var state = AppFeature.State()
        state.memberAccess = .member
        state.screen = .main
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.sessionClient.getAccessToken = { "new-session-token" }
            $0.sessionClient.logout = { XCTFail("New session must stay signed in") }
        }
        store.exhaustivity = .off

        await store.send(.sessionExpired(SessionExpirationEvent(statusCode: 401, reason: .retryRejected)))
        await store.receive(.sessionExpirationIgnored)
        XCTAssertEqual(store.state.screen, .main)
    }

    func test_matchingSessionExpirationClearsMemberSession() async {
        var state = AppFeature.State()
        state.memberAccess = .member
        state.screen = .main
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.sessionClient.getAccessToken = { "old-session-token" }
            $0.sessionClient.logout = {}
        }
        store.exhaustivity = .off
        let event = SessionExpirationEvent(
            statusCode: 403, reason: .refreshFailed,
            failedAccessTokenFingerprint: SessionExpirationEvent.fingerprint(of: "old-session-token")
        )

        await store.send(.sessionExpired(event))
        await store.receive(.sessionExpiredHandled)

        XCTAssertEqual(store.state.screen, .login)
    }

    func test_calendarAuthenticationLossReturnsToLogin() async {
        var state = AppFeature.State()
        state.memberAccess = .member
        state.screen = .main
        state.selectedTab = .calendar
        let store = TestStore(initialState: state) { AppFeature() } withDependencies: {
            $0.sessionClient.logout = {}
        }
        store.exhaustivity = .off

        await store.send(.calendar(.delegate(.memberAccessLost)))
        await store.receive(.memberAccessLost)
        await store.receive(.memberAccessLostHandled)

        XCTAssertEqual(store.state.screen, .login)
    }

    func test_logoutFromMyPageOpensLoginAndClearsMemberScreens() async {
        var state = AppFeature.State()
        state.screen = .main
        state.selectedTab = .myPage
        state.selectedTheme = .dark
        state.login.isProcessing = true
        state.home.answerDraft = "private answer"
        state.quoteList.hasLoaded = true
        state.calendar.recordedAnswer = "private answer"
        state.myPage = MyPageFeature.State(isLoggedIn: true, userName: "필사", selectedTheme: .dark)
        state.notice.hasLoaded = true
        state.alert.isAlarmOn = true
        state.memoInsert.savedMemo = "private memo"
        state.typing.korTyping = "private typing"
        state.share.quote = "private quote"
        state.generalPopup.hasLoaded = true
        let store = TestStore(initialState: state) { AppFeature() }
        store.exhaustivity = .off

        await store.send(.myPage(.delegate(.loggedOut)))

        XCTAssertEqual(store.state.screen, .login)
        XCTAssertEqual(store.state.selectedTab, .home)
        XCTAssertEqual(store.state.selectedTheme, .dark)
        XCTAssertFalse(store.state.login.isProcessing)
        XCTAssertEqual(store.state.home.answerDraft, "")
        XCTAssertFalse(store.state.quoteList.hasLoaded)
        XCTAssertNil(store.state.calendar.recordedAnswer)
        XCTAssertFalse(store.state.myPage.isLoggedIn)
        XCTAssertEqual(store.state.myPage.userName, "")
        XCTAssertEqual(store.state.myPage.selectedTheme, .dark)
        XCTAssertFalse(store.state.notice.hasLoaded)
        XCTAssertFalse(store.state.alert.isAlarmOn)
        XCTAssertEqual(store.state.memoInsert.savedMemo, "")
        XCTAssertEqual(store.state.typing.korTyping, "")
        XCTAssertEqual(store.state.share.quote, "")
        XCTAssertFalse(store.state.generalPopup.hasLoaded)
    }

    func test_answerSaveInvalidatesTheOtherTabsCachedData() async {
        let saved = AnswerResponse(memberQuoteSeq: 42, answer: "서버 답변", answeredAt: "2025-03-21T12:00:00")
        var state = AppFeature.State()
        state.memberAccess = .member
        state.home.quote = DailyQuote(dailyQuoteSeq: 42)
        state.home.isLoggedIn = true
        state.home.hasLoaded = true
        state.calendar.hasLoaded = true
        let store = TestStore(initialState: state) { AppFeature() }
        store.exhaustivity = .off

        await store.send(.home(.answerSaved(42, .success(saved))))
        XCTAssertFalse(store.state.calendar.hasLoaded)

        var calendarState = AppFeature.State()
        calendarState.memberAccess = .member
        calendarState.home.hasLoaded = true
        calendarState.calendar.hasLoaded = true
        calendarState.calendar.memberQuotes = [
            MemberQuotesData(dailyQuoteSeq: 42, quoteDate: FillsaCalendarDateSupport.quoteDateString(for: calendarState.calendar.selectedDay),
                             quote: "명언", author: "작가", completed: true, likeYn: "N", todayCompleted: true)
        ]
        let reverseStore = TestStore(initialState: calendarState) { AppFeature() }
        reverseStore.exhaustivity = .off

        await reverseStore.send(.calendar(.answerSaved(42, .success(saved))))
        XCTAssertFalse(reverseStore.state.home.hasLoaded)
    }
    func test_loadingCountControlsGlobalVisibility() async {
        var state = AppFeature.State()
        state.screen = .login
        let store = TestStore(initialState: state) {
            AppFeature()
        }
        XCTAssertFalse(store.state.isGlobalLoading)
        await store.send(.loadingCountChanged(2)) {
            $0.activeLoadingCount = 2
        }
        XCTAssertTrue(store.state.isGlobalLoading)
        await store.send(.loadingCountChanged(1)) {
            $0.activeLoadingCount = 1
        }
        XCTAssertTrue(store.state.isGlobalLoading)
        await store.send(.loadingCountChanged(0)) {
            $0.activeLoadingCount = 0
        }
        XCTAssertFalse(store.state.isGlobalLoading)
    }

    func test_splashHidesGlobalLoadingWithoutDiscardingActiveScope() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.loadingCountChanged(1)) {
            $0.activeLoadingCount = 1
        }
        XCTAssertFalse(store.state.isGlobalLoading)
        XCTAssertEqual(store.state.activeLoadingCount, 1)
    }

    func test_startupSubscribesToCurrentLoadingCountWithoutRegisteringScope() async {
        let registry = LoadingRegistry()
        let token = await registry.begin()
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.settingsClient.getDarkModeType = { .system }
            $0.sessionExpirationClient.events = { AsyncStream { $0.finish() } }
            $0.pushTokenClient.tokenUpdates = { AsyncStream { $0.finish() } }
            $0.pushRegistrationClient.synchronizeIfNeeded = {}
        }
        store.exhaustivity = .off
        let task = await store.send(.task)
        await store.receive(.loadingCountChanged(1)) {
            $0.activeLoadingCount = 1
        }
        let activeScopes = await loadingCount(registry)
        XCTAssertEqual(activeScopes, 1)
        await registry.end(token)
        await store.receive(.loadingCountChanged(0)) {
            $0.activeLoadingCount = 0
        }
        await task.cancel()
    }

    func test_homeTypingUsesTheExistingQuoteRouteWithAnEmptyTranscript() async {
        var state = AppFeature.State()
        state.memberAccess = .member
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

        await store.send(.homeTypingSelected)
        XCTAssertEqual(store.state.screen, .typing)
        XCTAssertEqual(store.state.typing.dailyQuoteSeq, 42)
        XCTAssertEqual(store.state.typing.korTyping, "")
        XCTAssertEqual(store.state.typing.engTyping, "")
    }

    func test_quoteTypingLoadsItsExistingTranscript() async {
        let response = MemberTypingQuoteResponse(
            korQuote: "명언",
            engQuote: "Quote",
            typingKorQuote: "서버에 저장된 필사",
            typingEngQuote: "Saved transcript",
            likeYn: "Y"
        )
        let store = TestStore(
            initialState: TypingFeature.State(dailyQuoteSeq: 42, korTyping: "이전 필사")
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

    func test_typingDoesNotReadLocalQuoteWhenSessionLookupFails() async {
        let response = MemberTypingQuoteResponse(
            korQuote: "명언", engQuote: "Quote", typingKorQuote: "서버 필사",
            typingEngQuote: "Server typing", likeYn: "N"
        )
        let store = TestStore(initialState: TypingFeature.State(dailyQuoteSeq: 42)) {
            TypingFeature()
        } withDependencies: {
            $0.sessionClient.isLoggedIn = { throw ErrorResponse.defaultError }
            $0.typingClient.getTyping = { _ in response }
        }
        store.exhaustivity = .off

        await store.send(.onAppear)
        await store.receive(.typingLoaded(.success(response)))
    }

    func test_typingSaveFailureKeepsEditorOpen() async {
        let store = TestStore(initialState: TypingFeature.State(dailyQuoteSeq: 42, korTyping: "필사")) {
            TypingFeature()
        } withDependencies: {
            $0.typingClient.postTyping = { _, _ in throw ErrorResponse.defaultError }
        }
        store.exhaustivity = .off

        await store.send(.saveAndBack)
        await store.receive(.typingSaved(.failure(.defaultError)))

        XCTAssertFalse(store.state.isSaving)
        XCTAssertEqual(store.state.korTyping, "필사")
    }

    func test_accountDeletionFromMyPageReturnsToLogin() async {
        var state = AppFeature.State()
        state.memberAccess = .member
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
        XCTAssertEqual(store.state.screen, .login)
    }

    func test_streakTooltipCalendarLinkClearsHomeOverlayBeforeSelectingCalendar() async {
        var state = AppFeature.State()
        state.memberAccess = .member
        state.screen = .main
        state.home.isStreakTooltipPresented = true
        let store = TestStore(initialState: state) {
            AppFeature()
        }

        await store.send(.home(.streakTooltipDismissed)) {
            $0.home.isStreakTooltipPresented = false
        }
        await store.send(.selectedTabChanged(.calendar)) {
            $0.selectedTab = .calendar
        }
    }
}

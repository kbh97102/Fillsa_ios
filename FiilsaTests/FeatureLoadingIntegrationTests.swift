import ComposableArchitecture
import Foundation
import Testing
import UserNotifications
@testable import Fiilsa

@Suite("Feature loading integration")
struct FeatureLoadingIntegrationTests {
    @Test @MainActor
    func popupCancellationDoesNotStartVersionLookup() async {
        let registry = LoadingRegistry()
        let store = TestStore(initialState: GeneralPopupFeature.State()) {
            GeneralPopupFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.hiddenPopupClient.clearAllIfNeeded = {}
            $0.commonClient.getPopupGeneral = { throw CancellationError() }
            $0.commonClient.getPopupVersionUpdate = { _ in
                Issue.record("Version lookup must not start after cancellation")
                throw CancellationError()
            }
        }
        let task = await store.send(.loadIfNeeded) { $0.isLoading = true }
        await store.receive(.loadCancelled) { $0.isLoading = false }
        await task.finish()
        #expect(await loadingCount(registry) == 0)
    }

    @Test @MainActor
    func resignationCancellationDoesNotShowFailureToast() async {
        let registry = LoadingRegistry()
        let store = TestStore(initialState: MyPageFeature.State(isLoggedIn: true)) {
            MyPageFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.commonClient.deleteResign = { throw CancellationError() }
            $0.sessionClient.logout = { Issue.record("Logout must not follow cancellation") }
        }
        let task = await store.send(.resignConfirmed) { $0.isProcessing = true }
        await store.receive(.resignCancelled) { $0.isProcessing = false }
        await task.finish()
        #expect(store.state.toastMessage == nil)
        #expect(await loadingCount(registry) == 0)
    }

    @Test @MainActor
    func typingSaveCancellationDoesNotFallBackToLocalWrite() async {
        let registry = LoadingRegistry()
        let store = TestStore(initialState: TypingFeature.State(dailyQuoteSeq: 7)) {
            TypingFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.sessionClient.isLoggedIn = { throw CancellationError() }
            $0.localQuoteClient.findById = { _ in
                Issue.record("Local write path must not follow cancellation")
                return nil
            }
        }
        let task = await store.send(.saveAndBack) { $0.isSaving = true }
        await store.receive(.saveCancelled) { $0.isSaving = false }
        await task.finish()
        #expect(await loadingCount(registry) == 0)
    }

    @Test @MainActor
    func typingLocalLoadUsesOneScope() async {
        let registry = LoadingRegistry()
        let gate = AsyncStream<Void>.makeStream()
        let started = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: TypingFeature.State(dailyQuoteSeq: 7)) {
            TypingFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.sessionClient.isLoggedIn = { false }
            $0.localQuoteClient.findById = { _ in
                started.continuation.yield(())
                for await _ in gate.stream {}
                return nil
            }
        }
        let task = await store.send(.onAppear)
        var events = started.stream.makeAsyncIterator()
        _ = await events.next()
        #expect(await loadingCount(registry) == 1)
        gate.continuation.finish()
        await store.receive(.localTypingLoaded(nil)) { $0.hasLoaded = true }
        await task.finish()
        #expect(await loadingCount(registry) == 0)
    }

    @Test @MainActor
    func alertPermissionWaitIsUnscopedButServerSyncIsScoped() async {
        let registry = LoadingRegistry()
        let permissionGate = AsyncStream<Void>.makeStream()
        let syncGate = AsyncStream<Void>.makeStream()
        let permissionStarted = AsyncStream<Void>.makeStream()
        let syncStarted = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: AlertFeature.State()) {
            AlertFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.notificationPermissionClient = NotificationPermissionClient(
                authorizationStatus: {
                    permissionStarted.continuation.yield(())
                    for await _ in permissionGate.stream {}
                    return .authorized
                },
                requestAuthorization: { true },
                scheduleDailyQuoteNotification: {},
                cancelDailyQuoteNotification: {}
            )
            $0.settingsClient.setAlarm = { _ in }
            $0.pushRegistrationClient.synchronize = { _ in
                syncStarted.continuation.yield(())
                for await _ in syncGate.stream {}
            }
        }
        let task = await store.send(.alarmToggled(true)) { $0.isProcessing = true }
        var permissionEvents = permissionStarted.stream.makeAsyncIterator()
        _ = await permissionEvents.next()
        #expect(await loadingCount(registry) == 0)
        permissionGate.continuation.finish()
        await store.receive(.alarmUpdateCompleted(.success(true))) {
            $0.isAlarmOn = true
            $0.isProcessing = false
            $0.toastMessage = "알림이 설정되었습니다."
        }
        var syncEvents = syncStarted.stream.makeAsyncIterator()
        _ = await syncEvents.next()
        #expect(await loadingCount(registry) == 1)
        syncGate.continuation.finish()
        await task.finish()
        #expect(await loadingCount(registry) == 0)
    }

    @Test @MainActor
    func socialSDKWaitDoesNotLoadButBackendLoginDoes() async {
        let registry = LoadingRegistry()
        let sdkGate = AsyncStream<Void>.makeStream()
        let backendGate = AsyncStream<Void>.makeStream()
        let sdkStarted = AsyncStream<Void>.makeStream()
        let backendStarted = AsyncStream<Void>.makeStream()
        let user = SocialAuthUser(provider: "KAKAO", oauthID: "42", nickname: "필사", profileImageURL: "")
        let response = LoginResponse(accessToken: "access", refreshToken: "refresh", memberSeq: 1, nickname: "필사", profileImageUrl: "")
        let store = TestStore(initialState: LoginFeature.State()) {
            LoginFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.socialAuthClient.signInWithKakao = {
                sdkStarted.continuation.yield(())
                for await _ in sdkGate.stream {}
                return user
            }
            $0.authUseCases.login = { _ in
                backendStarted.continuation.yield(())
                for await _ in backendGate.stream {}
                return response
            }
            $0.pushRegistrationClient.synchronize = { _ in }
        }
        let task = await store.send(.kakaoTapped) { $0.isProcessing = true }
        var sdkEvents = sdkStarted.stream.makeAsyncIterator()
        _ = await sdkEvents.next()
        #expect(await loadingCount(registry) == 0)
        sdkGate.continuation.finish()
        await store.receive(.kakaoAuthenticationCompleted(.success(user)))
        var backendEvents = backendStarted.stream.makeAsyncIterator()
        _ = await backendEvents.next()
        #expect(await loadingCount(registry) == 1)
        backendGate.continuation.finish()
        await store.receive(.socialLoginCompleted(.success(response))) { $0.isProcessing = false }
        await store.receive(.delegate(.moveHome))
        await task.finish()
        #expect(await loadingCount(registry) == 0)
    }

    @Test @MainActor
    func memoSaveOwnsOneScope() async {
        let registry = LoadingRegistry()
        let gate = AsyncStream<Void>.makeStream()
        let started = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: MemoInsertFeature.State(memberQuoteSeq: 7)) {
            MemoInsertFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.quoteListUseCases.saveMemo = { _, _ in
                started.continuation.yield(())
                for await _ in gate.stream {}
                return 1
            }
        }
        let task = await store.send(.saveAndBack("메모")) {
            $0.savedMemo = "메모"
            $0.isSaving = true
        }
        var events = started.stream.makeAsyncIterator()
        _ = await events.next()
        #expect(await loadingCount(registry) == 1)
        gate.continuation.finish()
        await store.receive(.memoSaved(.success(1))) { $0.isSaving = false }
        await store.receive(.delegate(.back))
        await task.finish()
        #expect(await loadingCount(registry) == 0)
    }

    @Test @MainActor
    func noticeFetchOwnsOneScope() async {
        let registry = LoadingRegistry()
        let gate = AsyncStream<Void>.makeStream()
        let started = AsyncStream<Void>.makeStream()
        let response = PageResponseNoticeResponse(content: [], totalElements: 0, totalPages: 0, currentPage: 0)
        let store = TestStore(initialState: NoticeFeature.State()) {
            NoticeFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.commonClient.getNotice = { _, _ in
                started.continuation.yield(())
                for await _ in gate.stream {}
                return response
            }
        }
        let task = await store.send(.onAppear) { $0.isLoading = true }
        var events = started.stream.makeAsyncIterator()
        _ = await events.next()
        #expect(await loadingCount(registry) == 1)
        gate.continuation.finish()
        await store.receive(.noticesLoaded(.success(response))) {
            $0.hasLoaded = true
            $0.isLoading = false
        }
        await task.finish()
        #expect(await loadingCount(registry) == 0)
    }

    @Test @MainActor
    func quoteListReplacementKeepsNewRequestScopeAfterOldCancellation() async {
        let registry = LoadingRegistry()
        let ordinal = RequestOrdinal()
        let firstGate = AsyncStream<Void>.makeStream()
        let secondGate = AsyncStream<Void>.makeStream()
        let firstStarted = AsyncStream<Void>.makeStream()
        let secondStarted = AsyncStream<Void>.makeStream()
        let response = PageResponseMemberQuotesResponse(
            content: [], totalElements: 0, totalPages: 0, currentPage: 0
        )
        let store = TestStore(initialState: QuoteListFeature.State()) {
            QuoteListFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.quoteListUseCases.loadList = { _, _, _, _, _ in
                if await ordinal.take() == 0 {
                    firstStarted.continuation.yield(())
                    for await _ in firstGate.stream {}
                } else {
                    secondStarted.continuation.yield(())
                    for await _ in secondGate.stream {}
                }
                return response
            }
        }
        await store.send(.onAppear) { $0.isLoading = true }
        var firstEvents = firstStarted.stream.makeAsyncIterator()
        _ = await firstEvents.next()
        #expect(await loadingCount(registry) == 1)
        let task = await store.send(.refresh)
        var secondEvents = secondStarted.stream.makeAsyncIterator()
        _ = await secondEvents.next()
        #expect(await loadingCount(registry) == 1)
        secondGate.continuation.finish()
        await store.receive(.quotesLoaded(.success(response))) {
            $0.hasLoaded = true
            $0.isLoading = false
            $0.totalPages = 0
        }
        await task.finish()
        #expect(await loadingCount(registry) == 0)
        firstGate.continuation.finish()
    }

    @Test @MainActor
    func calendarMonthRequestOwnsOneScope() async {
        let registry = LoadingRegistry()
        let gate = AsyncStream<Void>.makeStream()
        let started = AsyncStream<Void>.makeStream()
        let response = MemberMonthlyQuoteResponse(
            memberQuotes: [],
            monthlySummary: MonthlySummaryData(typingCount: 0, likeCount: 0, streakCount: 4)
        )
        let store = TestStore(initialState: CalendarFeature.State()) {
            CalendarFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.calendarUseCases.loadMonth = { _ in
                started.continuation.yield(())
                for await _ in gate.stream {}
                return response
            }
        }
        let task = await store.send(.onAppear) { $0.isLoading = true }
        var events = started.stream.makeAsyncIterator()
        _ = await events.next()
        #expect(await loadingCount(registry) == 1)
        gate.continuation.finish()
        await store.receive(.monthlyQuotesLoaded(.success(response))) {
            $0.monthlySummary = response.monthlySummary
            $0.displayStreakCount = 4
            $0.hasLoaded = true
            $0.isLoading = false
        }
        await task.finish()
        #expect(await loadingCount(registry) == 0)
    }

    @Test @MainActor
    func generalPopupFailureStillWaitsForVersionLookup() async {
        let registry = LoadingRegistry()
        let versionGate = AsyncStream<Void>.makeStream()
        let versionStarted = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: GeneralPopupFeature.State()) {
            GeneralPopupFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.hiddenPopupClient.clearAllIfNeeded = {}
            $0.commonClient.getPopupGeneral = { throw ErrorResponse.defaultError }
            $0.commonClient.getPopupVersionUpdate = { _ in
                versionStarted.continuation.yield(())
                for await _ in versionGate.stream {}
                throw ErrorResponse.defaultError
            }
        }
        let task = await store.send(.loadIfNeeded) { $0.isLoading = true }
        var events = versionStarted.stream.makeAsyncIterator()
        _ = await events.next()
        #expect(await loadingCount(registry) == 1)
        versionGate.continuation.finish()
        await store.receive(.loaded([])) {
            $0.hasLoaded = true
            $0.isLoading = false
        }
        await task.finish()
        #expect(await loadingCount(registry) == 0)
    }

    @Test @MainActor
    func resignationScopeIncludesSessionCleanup() async {
        let registry = LoadingRegistry()
        let logoutGate = AsyncStream<Void>.makeStream()
        let logoutStarted = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: MyPageFeature.State(isLoggedIn: true)) {
            MyPageFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.commonClient.deleteResign = {}
            $0.sessionClient.logout = {
                logoutStarted.continuation.yield(())
                for await _ in logoutGate.stream {}
            }
        }
        let task = await store.send(.resignConfirmed) { $0.isProcessing = true }
        var events = logoutStarted.stream.makeAsyncIterator()
        _ = await events.next()
        #expect(await loadingCount(registry) == 1)
        logoutGate.continuation.finish()
        await store.receive(.resignCompleted(.success(true))) {
            $0.isProcessing = false
            $0.isLoggedIn = false
        }
        await store.receive(.delegate(.resignCompleted))
        await task.finish()
        #expect(await loadingCount(registry) == 0)
    }
}

private actor RequestOrdinal {
    private var value = 0
    func take() -> Int {
        defer { value += 1 }
        return value
    }
}

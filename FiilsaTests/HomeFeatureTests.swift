import ComposableArchitecture
import Foundation
import SwiftUI
import Testing
import UIKit
import Alamofire
@testable import Fiilsa

@Suite("HomeFeature", .serialized)
struct HomeFeatureTests {
    @Test
    func weeklyDateWindowUsesServerAnchorAcrossMonthBoundary() {
        #expect(QuoteDateWindow.endDate(containing: "2026-08-31", anchor: "2026-09-03") == "2026-09-03")
        #expect(QuoteDateWindow.endDate(containing: "2026-08-27", anchor: "2026-09-03") == "2026-08-27")
        #expect(QuoteDateWindow.endDate(containing: "2026-09-04", anchor: "2026-09-03") == nil)
    }

    @Test
    func weeklyResponsePreservesUnassignedDayAndAnswer() throws {
        let payload = Data("""
        {"startDate":"2026-09-01","endDate":"2026-09-07","days":[
          {"date":"2026-09-01","dayOfWeek":"TUESDAY","state":"none","dailyQuoteSeq":null},
          {"date":"2026-09-07","dayOfWeek":"MONDAY","state":"today","dailyQuoteSeq":42,"questionKo":"질문","answer":"답","likeYn":"Y"}
        ]}
        """.utf8)
        let week = try JSONDecoder().decode(MemberWeeklyQuoteResponse.self, from: payload)
        #expect(week.days[0].dailyQuoteSeq == nil)
        #expect(week.days[0].date == "2026-09-01")
        #expect(week.days[1].answer == "답")
        #expect(week.days[1].asDailyQuote.dailyQuoteSeq == 42)
    }

    @Test
    func weeklyRepositoryOmitsInitialEndDateAndUsesItOnOlderWindow() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [WeeklyRequestURLProtocol.self]
        let repository = DefaultHomeRepository(apiClient: APIClient(session: Session(configuration: configuration)))

        _ = try await repository.getWeeklyQuotes(endDate: nil)
        _ = try await repository.getWeeklyQuotes(endDate: "2026-08-31")

        var requests = WeeklyRequestURLProtocol.requests.stream.makeAsyncIterator()
        let first = try #require(await requests.next())
        let second = try #require(await requests.next())
        #expect(first.path == "/api/v2/member-quotes/weekly")
        #expect(first.query == nil)
        #expect(second.query == "endDate=2026-08-31")
    }

    @Test
    func memberOnlyFeedUsesWeeklyEndpoint() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [WeeklyRequestURLProtocol.self]
        let repository = DefaultHomeRepository(apiClient: APIClient(session: Session(configuration: configuration)))
        let result = try await LoadHomeFeedUseCase(homeRepository: repository)(
            endDate: nil
        )

        guard case .member = result else {
            Issue.record("Home must use the member endpoint without a guest fallback")
            return
        }
    }

    @Test @MainActor
    func memberMovesWithinCachedWeekWithoutAnotherRequest() async throws {
        let week = try JSONDecoder().decode(MemberWeeklyQuoteResponse.self, from: Data("""
        {"startDate":"2026-08-06","endDate":"2026-08-12","days":[
          {"date":"2026-08-11","dayOfWeek":"TUESDAY","state":"done","dailyQuoteSeq":11,"korQuote":"전날","likeYn":"N"},
          {"date":"2026-08-12","dayOfWeek":"WEDNESDAY","state":"today","dailyQuoteSeq":12,"korQuote":"오늘","likeYn":"N"}
        ]}
        """.utf8))
        let selectedDate = FillsaCalendarDateSupport.calendar.date(from: DateComponents(year: 2026, month: 8, day: 12))!
        var state = HomeFeature.State()
        state.date = selectedDate
        state.quote = week.day("2026-08-12")!.asDailyQuote
        state.isLoggedIn = true
        state.hasLoaded = true
        state.serverToday = "2026-08-12"
        state.weeklyWindows[week.endDate] = week
        let store = TestStore(initialState: state) { HomeFeature() } withDependencies: {
            $0.homeUseCases.loadFeed = { _ in
                Issue.record("A cached date must not issue another request")
                throw ErrorResponse.defaultError
            }
        }

        await store.send(.beforeTapped) {
            $0.date = FillsaCalendarDateSupport.calendar.date(byAdding: .day, value: -1, to: selectedDate)!
            $0.quote = week.day("2026-08-11")!.asDailyQuote
            $0.hasLoaded = true
        }
        await store.finish()
    }

    @Test @MainActor
    func crossingWeeklyBoundaryFetchesOnceAndReturningUsesCache() async throws {
        let current = try JSONDecoder().decode(MemberWeeklyQuoteResponse.self, from: Data("""
        {"startDate":"2026-08-06","endDate":"2026-08-12","days":[{"date":"2026-08-06","dayOfWeek":"THURSDAY","state":"none","dailyQuoteSeq":6}]}
        """.utf8))
        let older = try JSONDecoder().decode(MemberWeeklyQuoteResponse.self, from: Data("""
        {"startDate":"2026-07-30","endDate":"2026-08-05","days":[{"date":"2026-08-05","dayOfWeek":"WEDNESDAY","state":"done","dailyQuoteSeq":5}]}
        """.utf8))
        let selected = FillsaCalendarDateSupport.calendar.date(from: DateComponents(year: 2026, month: 8, day: 6))!
        var state = HomeFeature.State()
        state.date = selected
        state.quote = current.day("2026-08-06")!.asDailyQuote
        state.isLoggedIn = true
        state.hasLoaded = true
        state.serverToday = current.endDate
        state.weeklyWindows[current.endDate] = current
        let calls = AsyncStream<String>.makeStream()
        let store = TestStore(initialState: state) { HomeFeature() } withDependencies: {
            $0.homeUseCases.loadFeed = { endDate in
                calls.continuation.yield(endDate ?? "omitted")
                return .member(older)
            }
        }
        let previous = FillsaCalendarDateSupport.calendar.date(byAdding: .day, value: -1, to: selected)!

        await store.send(.beforeTapped) {
            $0.date = previous
            $0.hasLoaded = false
            $0.isLoading = true
            $0.feedRequestID = 1
            $0.nextFeedRequestID = 1
        }
        var requestIterator = calls.stream.makeAsyncIterator()
        #expect(await requestIterator.next() == "2026-08-05")
        await store.receive(.feedLoaded(1, .success(.member(older)))) {
            $0.feedRequestID = nil
            $0.weeklyWindows[older.endDate] = older
            $0.completedWritingDates = ["2026-08-05"]
            $0.quote = older.day("2026-08-05")!.asDailyQuote
            $0.hasLoaded = true
            $0.isLoading = false
        }
        await store.send(.nextTapped) {
            $0.date = selected
            $0.quote = current.day("2026-08-06")!.asDailyQuote
        }
        await store.finish()
    }

    @Test @MainActor
    func answerSavedAfterDateChangeUpdatesOnlyItsCachedDay() async throws {
        let week = try JSONDecoder().decode(MemberWeeklyQuoteResponse.self, from: Data("""
        {"startDate":"2026-08-06","endDate":"2026-08-12","days":[
          {"date":"2026-08-11","dayOfWeek":"TUESDAY","state":"none","dailyQuoteSeq":11,"answer":null},
          {"date":"2026-08-12","dayOfWeek":"WEDNESDAY","state":"today","dailyQuoteSeq":12,"answer":null}
        ]}
        """.utf8))
        var state = HomeFeature.State()
        state.date = FillsaCalendarDateSupport.calendar.date(from: DateComponents(year: 2026, month: 8, day: 12))!
        state.quote = week.day("2026-08-12")!.asDailyQuote
        state.isLoggedIn = true
        state.hasLoaded = true
        state.weeklyWindows[week.endDate] = week
        let saved = AnswerResponse(memberQuoteSeq: 88, answer: "수정 답변", answeredAt: "2026-08-12 10:00:00")
        let store = TestStore(initialState: state) { HomeFeature() }

        await store.send(.answerSaved(11, .success(saved))) {
            $0.weeklyWindows[week.endDate]!.days[0].answer = saved.answer
            $0.weeklyWindows[week.endDate]!.days[0].answeredAt = saved.answeredAt
        }
        #expect(store.state.quote.dailyQuoteSeq == 12)
        #expect(store.state.recordedAnswer == nil)
    }

    @Test @MainActor
    func imageUploadForPreviousDateDoesNotReplaceSelectedDateImage() async throws {
        let week = try JSONDecoder().decode(MemberWeeklyQuoteResponse.self, from: Data("""
        {"startDate":"2026-08-06","endDate":"2026-08-12","days":[
          {"date":"2026-08-11","dayOfWeek":"TUESDAY","state":"none","dailyQuoteSeq":11,"imagePath":null},
          {"date":"2026-08-12","dayOfWeek":"WEDNESDAY","state":"today","dailyQuoteSeq":12,"imagePath":"today.jpg"}
        ]}
        """.utf8))
        var state = HomeFeature.State()
        state.date = FillsaCalendarDateSupport.calendar.date(from: DateComponents(year: 2026, month: 8, day: 12))!
        state.quote = week.day("2026-08-12")!.asDailyQuote
        state.isLoggedIn = true
        state.weeklyWindows[week.endDate] = week
        let response = MemberQuoteImageResponse(memberQuoteSeq: 77, imagePath: "yesterday.jpg")
        let store = TestStore(initialState: state) { HomeFeature() }

        await store.send(.imageUploaded(11, .success(response))) {
            $0.weeklyWindows[week.endDate]!.days[0].imagePath = "yesterday.jpg"
        }
        #expect(store.state.quote.imagePath == "today.jpg")
    }

    @Test @MainActor
    func memberHomeEntryLoadsOneWeeklyWindowWithoutEndDate() async throws {
        let week = try JSONDecoder().decode(MemberWeeklyQuoteResponse.self, from: Data("""
        {"startDate":"2026-08-06","endDate":"2026-08-12","days":[{"date":"2026-08-12","dayOfWeek":"WEDNESDAY","state":"today","dailyQuoteSeq":12,"answer":"기록"}]}
        """.utf8))
        let calls = AsyncStream<String>.makeStream()
        let streakGate = AsyncStream<Void>.makeStream()
        var state = HomeFeature.State()
        state.date = FillsaCalendarDateSupport.calendar.date(from: DateComponents(year: 2026, month: 8, day: 12))!
        let store = TestStore(initialState: state) { HomeFeature() } withDependencies: {
            $0.homeUseCases.loadFeed = { endDate in
                calls.continuation.yield(endDate ?? "omitted")
                return .member(week)
            }
            $0.streakClient.getCurrentCount = {
                for await _ in streakGate.stream {}
                return 0
            }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.feedRequestID = 1
            $0.nextFeedRequestID = 1
        }
        var requestIterator = calls.stream.makeAsyncIterator()
        #expect(await requestIterator.next() == "omitted")
        await store.receive(.feedLoaded(1, .success(.member(week)))) {
            $0.feedRequestID = nil
            $0.isLoggedIn = true
            $0.serverToday = "2026-08-12"
            $0.weeklyWindows[week.endDate] = week
            $0.quote = week.day("2026-08-12")!.asDailyQuote
            $0.answerDraft = "기록"
            $0.recordedAnswer = "기록"
            $0.isEditingAnswer = false
            $0.hasLoaded = true
            $0.isLoading = false
        }
        streakGate.continuation.finish()
        await store.receive(.completionStateLoaded(0)) { $0.isStreakStateLoaded = true }
        await store.finish()
    }

    @Test @MainActor
    func selectionDuringInitialWeeklyLoadUsesItsResultForLatestDate() async throws {
        let today = try JSONDecoder().decode(MemberWeeklyQuoteResponse.self, from: Data("""
        {"startDate":"2026-08-06","endDate":"2026-08-12","days":[{"date":"2026-08-12","dayOfWeek":"WEDNESDAY","state":"today","dailyQuoteSeq":12}]}
        """.utf8))
        let selected = try JSONDecoder().decode(MemberWeeklyQuoteResponse.self, from: Data("""
        {"startDate":"2026-08-06","endDate":"2026-08-12","days":[{"date":"2026-08-11","dayOfWeek":"TUESDAY","state":"none","dailyQuoteSeq":11}]}
        """.utf8))
        var state = HomeFeature.State()
        state.date = FillsaCalendarDateSupport.calendar.date(from: DateComponents(year: 2026, month: 8, day: 12))!
        state.isLoading = true
        state.feedRequestID = 1
        state.nextFeedRequestID = 1
        let selectedDate = FillsaCalendarDateSupport.calendar.date(byAdding: .day, value: -1, to: state.date)!
        let store = TestStore(initialState: state) { HomeFeature() } withDependencies: {
            $0.homeUseCases.loadDailyQuote = { _ in
                Issue.record("Selection during weekly load must not fall back to daily")
                throw ErrorResponse.defaultError
            }
            $0.homeUseCases.loadFeed = { _ in
                Issue.record("In-flight first week should serve its selected date")
                throw ErrorResponse.defaultError
            }
        }

        await store.send(.calendarDateSelected(selectedDate)) {
            $0.date = selectedDate
            $0.calendarDisplayedMonth = FillsaCalendarDateSupport.startOfMonth(for: selectedDate)
        }
        await store.send(.feedLoaded(1, .success(.member(selected)))) {
            $0.feedRequestID = nil
            $0.isLoggedIn = true
            $0.serverToday = "2026-08-12"
            $0.weeklyWindows[selected.endDate] = selected
            $0.quote = selected.day("2026-08-11")!.asDailyQuote
            $0.hasLoaded = true
            $0.isLoading = false
        }
        await store.send(.feedLoaded(1, .success(.member(today))))
        #expect(store.state.quote.dailyQuoteSeq == 11)
        await store.finish()
    }

    @Test @MainActor
    func lateDailyResultCannotOverwriteANewerSelectedDate() async {
        var state = HomeFeature.State()
        state.date = FillsaCalendarDateSupport.calendar.date(from: DateComponents(year: 2026, month: 8, day: 12))!
        state.quote = DailyQuote(dailyQuoteSeq: 12, quoteDate: "2026-08-12")
        let store = TestStore(initialState: state) { HomeFeature() }

        await store.send(.datedDailyQuoteLoaded(
            "2026-08-11",
            .success(HomeDailyQuoteResult(quote: DailyQuote(dailyQuoteSeq: 11, quoteDate: "2026-08-11"), isLoggedIn: false))
        ))
        #expect(store.state.quote.dailyQuoteSeq == 12)
    }

    @Test
    func v2DailyQuoteDecodesQuestionAndPreviouslySavedAnswer() throws {
        let payload = Data("""
        {"date":"2026-10-07","dailyQuoteSeq":42,"korQuote":"명언","questionKo":"오늘의 질문","answer":"기존 답변","likeYn":"N"}
        """.utf8)

        let quote = try JSONDecoder().decode(DailyQuote.self, from: payload)

        #expect(quote.quoteDate == "2026-10-07")
        #expect(quote.questionKo == "오늘의 질문")
        #expect(quote.answer == "기존 답변")
    }

    @Test @MainActor
    func homeEntryWaitsForQuoteAndCompletionState() async {
        let registry = LoadingRegistry()
        let quoteGate = AsyncStream<Void>.makeStream()
        let streakGate = AsyncStream<Void>.makeStream()
        let quoteStarted = AsyncStream<Void>.makeStream()
        let streakStarted = AsyncStream<Void>.makeStream()
        let quoteDate = FillsaCalendarDateSupport.quoteDateString(for: Date())
        let response = try! JSONDecoder().decode(MemberWeeklyQuoteResponse.self, from: Data("""
        {"startDate":"\(quoteDate)","endDate":"\(quoteDate)","days":[{"date":"\(quoteDate)","dayOfWeek":"TODAY","state":"today","dailyQuoteSeq":3}]}
        """.utf8))
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.homeUseCases.loadFeed = { _ in
                quoteStarted.continuation.yield(())
                for await _ in quoteGate.stream {}
                return .member(response)
            }
            $0.streakClient.getCurrentCount = {
                streakStarted.continuation.yield(())
                for await _ in streakGate.stream {}
                return 2
            }
        }
        let task = await store.send(.onAppear) { $0.isLoading = true; $0.feedRequestID = 1; $0.nextFeedRequestID = 1 }
        let requestID = 1
        var quoteEvents = quoteStarted.stream.makeAsyncIterator()
        var streakEvents = streakStarted.stream.makeAsyncIterator()
        _ = await quoteEvents.next()
        _ = await streakEvents.next()
        #expect(await loadingCount(registry) == 1)
        quoteGate.continuation.finish()
        await store.receive(.feedLoaded(requestID, .success(.member(response)))) {
            $0.feedRequestID = nil
            $0.isLoggedIn = true
            $0.serverToday = quoteDate
            $0.weeklyWindows[quoteDate] = response
            $0.quote = response.day(quoteDate)!.asDailyQuote
            $0.hasLoaded = true
            $0.isLoading = false
        }
        #expect(await loadingCount(registry) == 1)
        streakGate.continuation.finish()
        await store.receive(.completionStateLoaded(2)) {
            $0.streakCount = 2
            $0.isStreakStateLoaded = true
        }
        await task.finish()
        #expect(await loadingCount(registry) == 0)
    }

    @Test @MainActor
    func quoteFailureStillWaitsForCompletionState() async {
        let registry = LoadingRegistry()
        let streakGate = AsyncStream<Void>.makeStream()
        let streakStarted = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.homeUseCases.loadFeed = { _ in throw ErrorResponse.defaultError }
            $0.streakClient.getCurrentCount = {
                streakStarted.continuation.yield(())
                for await _ in streakGate.stream {}
                return 0
            }
        }
        let task = await store.send(.onAppear) { $0.isLoading = true; $0.feedRequestID = 1; $0.nextFeedRequestID = 1 }
        let requestID = 1
        var started = streakStarted.stream.makeAsyncIterator()
        _ = await started.next()
        await store.receive(.feedLoaded(requestID, .failure(.defaultError))) {
            $0.feedRequestID = nil
            $0.hasLoaded = true
            $0.isLoading = false
        }
        #expect(await loadingCount(registry) == 1)
        streakGate.continuation.finish()
        await store.receive(.completionStateLoaded(0)) {
            $0.isStreakStateLoaded = true
        }
        await task.finish()
        #expect(await loadingCount(registry) == 0)
    }

    @Test @MainActor
    func homeSingleRequestUsesOneScopeAndCancellationSendsNoFailure() async {
        let registry = LoadingRegistry()
        let gate = AsyncStream<Void>.makeStream()
        let started = AsyncStream<Void>.makeStream()
        let selectedDate = FillsaCalendarDateSupport.calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 12)
        )!
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
            $0.homeUseCases.loadDailyQuote = { _ in
                started.continuation.yield(())
                for await _ in gate.stream {}
                throw CancellationError()
            }
        }
        let task = await store.send(.calendarDateSelected(selectedDate)) {
            $0.date = selectedDate
            $0.calendarDisplayedMonth = FillsaCalendarDateSupport.startOfMonth(for: selectedDate)
            $0.isLoading = true
        }
        var events = started.stream.makeAsyncIterator()
        _ = await events.next()
        #expect(await loadingCount(registry) == 1)
        await task.cancel()
        #expect(await loadingCount(registry) == 0)
        gate.continuation.finish()
    }

    @Test
    @MainActor
    func quoteCardGrowsBeyondItsFigmaMinimumForLongContent() {
        let view = HomeQuoteCard(
            text: "사랑은 상대를 바꾸려는 마음이 아니라 서로 다른 시간을 이해하고 기다리며, 늦게 도착한 진심까지도 다치지 않게 받아들이는 오래된 연습이다. 그 연습은 오늘의 작은 친절에서 다시 시작된다.",
            author: "존우든"
        )
        .frame(width: 320)
        .environment(\.dynamicTypeSize, .accessibility3)
        let host = UIHostingController(rootView: view)

        let size = host.sizeThatFits(
            in: CGSize(width: 320, height: CGFloat.greatestFiniteMagnitude)
        )

        #expect(size.height > 150)
    }

    @Test
    func answerInputLimitsExtendedGraphemeClustersAndReportsRemainingCount() {
        let emoji = "👨🏽‍💻"
        let overLimit = String(repeating: emoji, count: 201)

        #expect(HomeAnswerInput.limit(overLimit).count == 200)
        #expect(HomeAnswerInput.remaining(for: overLimit) == 0)
        #expect(HomeAnswerInput.remaining(for: String(repeating: emoji, count: 199)) == 1)
    }

    @Test
    func quoteCardDoesNotRequestNextWhenTheCurrentQuoteIsLatest() {
        #expect(
            HomeQuoteCardSwipeAction.resolve(translationWidth: -151, canNavigateForward: false) == .none
        )
        #expect(
            HomeQuoteCardSwipeAction.resolve(translationWidth: 151, canNavigateForward: false) == .previous
        )
    }

    @Test
    func selectedCompletedDayUsesSelectedAppearanceInsteadOfCompletedAppearance() {
        #expect(HomeWeekStripDayState.resolve(isSelected: true, isCompleted: true) == .selected)
    }

    @Test
    func darkHomePaletteUsesTheFigmaSurfaceAndTextTokens() {
        let palette = HomeFigmaPalette.resolve(isDark: true)

        #expect(palette.rootBackground == .gray700)
        #expect(palette.cardBackground == .gray600)
        #expect(palette.cardBorder == .gray500)
        #expect(palette.primaryText == .white)
        #expect(palette.actionText == .gray200)
        #expect(palette.weekdayDefault == .gray400)
        #expect(palette.mainDivider == .gray500)
        #expect(palette.mainDividerOpacity == 0.55)
    }

    @Test
    func completionDateKeyUsesTheStorageCalendarDayInsteadOfAKSTAssumption() {
        var storageCalendar = Calendar(identifier: .gregorian)
        storageCalendar.timeZone = TimeZone(secondsFromGMT: -8 * 60 * 60)!
        let instant = ISO8601DateFormatter().date(from: "2026-08-12T00:10:00Z")!

        #expect(HomeCompletionDateKey.make(for: instant, calendar: storageCalendar) == "2026-08-11")
    }

    @Test
    func streakCountDoesNotReplaceServerCompletionDates() async {
        var state = HomeFeature.State()
        state.completedWritingDates = ["2026-08-10"]
        let store = TestStore(initialState: state) {
            HomeFeature()
        }

        await store.send(.completionStateLoaded(3)) {
            $0.streakCount = 3
            $0.isStreakStateLoaded = true
        }
        #expect(store.state.completedWritingDates == ["2026-08-10"])
    }

    @Test
    func zeroStreakDoesNotRenderAStreakValue() async {
        var initialState = HomeFeature.State()
        initialState.streakCount = 4
        let store = TestStore(initialState: initialState) {
            HomeFeature()
        }

        await store.send(.completionStateLoaded(0)) {
            $0.streakCount = nil
            $0.isStreakStateLoaded = true
        }
    }

    @Test
    func calendarTriggerAndZeroStreakTooltipAreMutuallyExclusive() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        }

        await store.send(.completionStateLoaded(0)) {
            $0.isStreakStateLoaded = true
        }
        await store.send(.calendarTriggerTapped) {
            $0.isCalendarPresented = true
            $0.calendarDisplayedMonth = FillsaCalendarDateSupport.startOfMonth(for: $0.date)
        }
        await store.send(.streakStatusTapped) {
            $0.isCalendarPresented = false
            $0.isStreakTooltipPresented = true
        }
        await store.send(.streakTooltipDismissed) {
            $0.isStreakTooltipPresented = false
        }
    }

    @Test
    func streakWarningWaitsForAConfirmedZeroAndPositiveLoadClosesItsTooltip() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        }

        await store.send(.streakStatusTapped)
        await store.send(.completionStateLoaded(0)) {
            $0.isStreakStateLoaded = true
        }
        await store.send(.streakStatusTapped) {
            $0.isStreakTooltipPresented = true
        }
        await store.send(.completionStateLoaded(2)) {
            $0.streakCount = 2
            $0.isStreakTooltipPresented = false
        }
    }

    @Test
    func calendarSelectionClosesAndReloadsTheQuote() async {
        let selectedDate = FillsaCalendarDateSupport.calendar.date(
            from: DateComponents(year: 2026, month: 8, day: 12)
        )!
        var initialState = HomeFeature.State()
        initialState.isCalendarPresented = true
        let quote = DailyQuote(dailyQuoteSeq: 99, korQuote: "새 명언")
        let store = TestStore(initialState: initialState) {
            HomeFeature()
        } withDependencies: {
            $0.homeUseCases.loadDailyQuote = { _ in
                HomeDailyQuoteResult(quote: quote, isLoggedIn: false)
            }
        }

        await store.send(.calendarDateSelected(selectedDate)) {
            $0.date = selectedDate
            $0.calendarDisplayedMonth = FillsaCalendarDateSupport.startOfMonth(for: selectedDate)
            $0.isCalendarPresented = false
            $0.isLoading = true
        }
        await store.receive(.datedDailyQuoteLoaded("2026-08-12", .success(HomeDailyQuoteResult(quote: quote, isLoggedIn: false)))) {
            $0.quote = quote
            $0.hasLoaded = true
            $0.isLoading = false
        }
    }

    @Test
    func overlayDismissalsClearTheVisibleState() async {
        var initialState = HomeFeature.State()
        initialState.isCalendarPresented = true
        initialState.isStreakTooltipPresented = true
        let store = TestStore(initialState: initialState) {
            HomeFeature()
        }

        await store.send(.calendarDismissed) {
            $0.isCalendarPresented = false
        }
        await store.send(.streakTooltipDismissed) {
            $0.isStreakTooltipPresented = false
        }
    }

    @Test
    func calendarMonthRangeRejectsMonthsOutsideTheSupportedDates() {
        #expect(HomeCalendarMonthRange.isSelectable(HomeCalendarMonthRange.start))
        #expect(!HomeCalendarMonthRange.isSelectable(FillsaCalendarDateSupport.addMonths(-1, to: HomeCalendarMonthRange.start)))
        #expect(!HomeCalendarMonthRange.isSelectable(FillsaCalendarDateSupport.addMonths(1, to: HomeCalendarMonthRange.end)))
    }

    @Test
    func answerWithoutMemberFlagStillUsesServer() async {
        var state = HomeFeature.State()
        state.quote = DailyQuote(dailyQuoteSeq: 42)
        let saved = AnswerResponse(memberQuoteSeq: 42, answer: "서버 답변", answeredAt: "2026-10-10")
        let store = TestStore(initialState: state) {
            HomeFeature()
        } withDependencies: {
            $0.homeUseCases.saveAnswer = { _, _ in saved }
        }

        await store.send(.answerDraftChanged("서버 답변")) {
            $0.answerDraft = "서버 답변"
        }
        await store.send(.answerRecordTapped)
        await store.receive(.answerSaved(42, .success(saved))) {
            $0.recordedAnswer = "서버 답변"
            $0.isEditingAnswer = false
            $0.quote = DailyQuote(dailyQuoteSeq: 42, answer: "서버 답변")
            $0.toastMessage = "답변을 기록했어요."
        }
        await store.send(.answerEditTapped) {
            $0.isEditingAnswer = true
        }
    }

    @Test @MainActor
    func answerRecordWaitsForServerBeforeShowingSuccess() async {
        var state = HomeFeature.State()
        state.isLoggedIn = true
        state.quote = DailyQuote(dailyQuoteSeq: 42)
        state.answerDraft = "서버에 저장할 답변"
        let gate = AsyncStream<Void>.makeStream()
        let calls = AsyncStream<(String, Int)>.makeStream()
        let saved = AnswerResponse(memberQuoteSeq: 84, answer: "서버에 저장할 답변", answeredAt: "2026-10-07 21:40:00")
        let store = TestStore(initialState: state) {
            HomeFeature()
        } withDependencies: {
            $0.homeUseCases.saveAnswer = { answer, dailyQuoteSeq in
                calls.continuation.yield((answer, dailyQuoteSeq))
                for await _ in gate.stream {}
                return saved
            }
        }

        let task = await store.send(.answerRecordTapped)
        var receivedCalls = calls.stream.makeAsyncIterator()
        let call = await receivedCalls.next()
        #expect(call?.0 == "서버에 저장할 답변")
        #expect(call?.1 == 42)
        #expect(store.state.recordedAnswer == nil)
        #expect(store.state.toastMessage == nil)

        gate.continuation.finish()
        await store.receive(.answerSaved(42, .success(saved))) {
            $0.answerDraft = saved.answer
            $0.recordedAnswer = saved.answer
            $0.isEditingAnswer = false
            $0.quote = DailyQuote(dailyQuoteSeq: 42, answer: saved.answer)
            $0.toastMessage = "답변을 기록했어요."
        }
        await task.finish()
    }

    @Test @MainActor
    func failedAnswerSaveKeepsDraftAndDoesNotClaimSuccess() async {
        var state = HomeFeature.State()
        state.isLoggedIn = true
        state.quote = DailyQuote(dailyQuoteSeq: 42)
        state.answerDraft = "다시 시도할 답변"
        let store = TestStore(initialState: state) {
            HomeFeature()
        } withDependencies: {
            $0.homeUseCases.saveAnswer = { _, _ in throw ErrorResponse.defaultError }
        }

        await store.send(.answerRecordTapped)
        await store.receive(.answerSaved(42, .failure(.defaultError)))
        #expect(store.state.answerDraft == "다시 시도할 답변")
        #expect(store.state.recordedAnswer == nil)
        #expect(store.state.toastMessage == nil)
    }

    @Test
    func onlyRecordedAnswerToastUsesSuccessPresentation() {
        #expect(HomeToastPresentation.resolve(message: "답변을 기록했어요.") == .success)
        #expect(HomeToastPresentation.resolve(message: "이미지가 삭제되었습니다.") == .standard)
        #expect(HomeToastPresentation.resolve(message: "이미지 삭제에 실패했습니다.") == .standard)
        #expect(HomeToastPresentation.resolve(message: "이미지 변경에 실패했습니다.") == .standard)
    }

    @Test
    func weekStripEndsAtTheSelectedDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let selectedDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 12))!

        let dates = HomeWeekStrip.visibleDates(endingAt: selectedDate, calendar: calendar)

        #expect(dates.count == 7)
        #expect(calendar.isDate(dates.last!, inSameDayAs: selectedDate))
        #expect(calendar.component(.day, from: dates.first!) == 6)
    }
}

private final class WeeklyRequestURLProtocol: URLProtocol {
    static let requests = AsyncStream<URLComponents>.makeStream()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        Self.requests.continuation.yield(components)
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"startDate":"2026-08-25","endDate":"2026-08-31","days":[]}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

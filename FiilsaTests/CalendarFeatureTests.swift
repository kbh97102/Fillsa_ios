import ComposableArchitecture
import Foundation
import Testing
@testable import Fiilsa

@Suite("CalendarFeature")
struct CalendarFeatureTests {
    @Test
    func recordIndicatorsMapWritingAndLikesToTheFigmaIcons() {
        let quote = MemberQuotesData(
            dailyQuoteSeq: 1,
            quoteDate: "2025-03-21",
            quote: "quote",
            author: "author",
            completed: true,
            likeYn: "Y",
            todayCompleted: true
        )

        #expect(CalendarRecordIndicators.resolve(for: quote) == [.heart, .flame])
        #expect(CalendarRecordIndicators.resolve(for: nil).isEmpty)
    }

    @Test
    func todayCompletedRecordIsTreatedAsCompletedForTheSelectedDayDetail() {
        let quote = MemberQuotesData(
            dailyQuoteSeq: 2,
            quoteDate: "2025-03-22",
            quote: "quote",
            author: "author",
            completed: false,
            likeYn: "N",
            todayCompleted: true
        )

        #expect(CalendarWritingCompletion.isCompleted(quote))
    }

    @Test
    func selectedDayPresentationUsesCompletedDetailWhenOnlyTodayCompletedIsTrue() {
        let quote = MemberQuotesData(
            dailyQuoteSeq: 3,
            quoteDate: "2025-03-23",
            quote: "quote",
            author: "author",
            completed: false,
            likeYn: "N",
            todayCompleted: true
        )

        #expect(CalendarSelectedDayPresentation.resolve(for: quote) == .completed)
        #expect(CalendarSelectedDayPresentation.resolve(for: nil) == .incomplete)
    }

    @Test
    func loadingAMonthStoresTheStreakForTheCalendarHeader() async {
        let response = fixtureResponse(streakCount: 100)
        var initialState = CalendarFeature.State()
        initialState.currentMonth = fixtureDate(year: 2025, month: 3, day: 1)
        initialState.selectedDay = initialState.currentMonth

        let store = TestStore(initialState: initialState) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarUseCases.loadMonth = { _ in response }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(.monthlyQuotesLoaded(.success(response))) {
            $0.memberQuotes = response.memberQuotes
            $0.monthlySummary = response.monthlySummary
            $0.displayStreakCount = 100
            $0.hasLoaded = true
            $0.isLoading = false
        }
    }

    @Test
    func changingMonthResetsSelectionAndLoadsTheNewMonth() async {
        let response = fixtureResponse(streakCount: 7)
        let targetMonth = fixtureDate(year: 2025, month: 4, day: 1)
        var initialState = CalendarFeature.State()
        initialState.currentMonth = fixtureDate(year: 2025, month: 3, day: 1)
        initialState.selectedDay = fixtureDate(year: 2025, month: 3, day: 21)
        initialState.hasLoaded = true

        let store = TestStore(initialState: initialState) {
            CalendarFeature()
        } withDependencies: {
            $0.calendarUseCases.loadMonth = { _ in response }
        }

        await store.send(.monthChanged(targetMonth)) {
            $0.currentMonth = targetMonth
            $0.selectedDay = targetMonth
            $0.hasLoaded = false
            $0.isLoading = true
        }
        await store.receive(.monthlyQuotesLoaded(.success(response))) {
            $0.memberQuotes = response.memberQuotes
            $0.monthlySummary = response.monthlySummary
            $0.displayStreakCount = 7
            $0.hasLoaded = true
            $0.isLoading = false
        }
    }

    @Test
    func monthlyQuoteDecodesTheImageAndSharingDetails() throws {
        let data = Data("""
        {"dailyQuoteSeq":21,"quoteDate":"2025-03-21","quote":"명언","author":"작가",\
        "completed":true,"likeYn":"Y","todayCompleted":true,"engQuote":"Quote",\
        "engAuthor":"Author","authorUrl":"https://example.com","imagePath":"https://example.com/photo.jpg"}
        """.utf8)
        let quote = try JSONDecoder().decode(MemberQuotesData.self, from: data)

        #expect(quote.engQuote == "Quote")
        #expect(quote.engAuthor == "Author")
        #expect(quote.authorUrl == "https://example.com")
        #expect(quote.imagePath == "https://example.com/photo.jpg")
    }

    @Test @MainActor
    func likeTargetsTheTappedCompletedQuoteAfterDateSelectionChanges() async {
        let day20 = fixtureDate(year: 2025, month: 3, day: 20)
        let day21 = fixtureDate(year: 2025, month: 3, day: 21)
        let first = fixtureQuote(day: 20, liked: true)
        let second = fixtureQuote(day: 21, liked: false)
        var state = CalendarFeature.State()
        state.currentMonth = FillsaCalendarDateSupport.startOfMonth(for: day21)
        state.selectedDay = day21
        state.memberQuotes = [first, second]
        state.monthlySummary = MonthlySummaryData(typingCount: 2, likeCount: 1, streakCount: 7)
        state.hasLoaded = true
        let gate = AsyncStream<Void>.makeStream()
        let started = AsyncStream<(Int, String)>.makeStream()
        var refreshed = second
        refreshed.likeYn = "Y"
        let response = MemberMonthlyQuoteResponse(
            memberQuotes: [first, refreshed],
            monthlySummary: MonthlySummaryData(typingCount: 2, likeCount: 2, streakCount: 7)
        )
        let store = TestStore(initialState: state) {
            CalendarFeature()
        } withDependencies: {
            $0.homeUseCases.updateLike = { _, quote, date, _ in
                started.continuation.yield((quote.dailyQuoteSeq, date))
                for await _ in gate.stream {}
                return 1
            }
            $0.calendarUseCases.loadMonth = { _ in response }
        }

        await store.send(.likeTapped(20, true))
        let task = await store.send(.likeTapped(21, true))
        var calls = started.stream.makeAsyncIterator()
        let call = await calls.next()
        #expect(call?.0 == 21)
        #expect(call?.1 == "2025-03-21")
        await store.send(.daySelected(day20)) { $0.selectedDay = day20 }
        gate.continuation.finish()
        await store.receive(.likeUpdated(21, true, .success(1))) {
            $0.memberQuotes[1].likeYn = "Y"
            $0.monthlySummary = MonthlySummaryData(typingCount: 2, likeCount: 2, streakCount: 7)
        }
        await store.receive(.refresh) { $0.isLoading = true }
        await store.receive(.monthlyQuotesLoaded(.success(response))) {
            $0.memberQuotes = response.memberQuotes
            $0.monthlySummary = response.monthlySummary
            $0.displayStreakCount = 7
            $0.isLoading = false
        }
        await task.finish()
        #expect(store.state.selectedDay == day20)
        #expect(store.state.monthlySummary.likeCount == 2)
        #expect(CalendarRecordIndicators.resolve(for: store.state.memberQuotes[1]).contains(.heart))
    }

    @Test @MainActor
    func imageUploadKeepsTheQuoteChosenWhenDialogOpened() async throws {
        let day20 = fixtureDate(year: 2025, month: 3, day: 20)
        let day21 = fixtureDate(year: 2025, month: 3, day: 21)
        let first = fixtureQuote(day: 20, liked: false)
        let second = fixtureQuote(day: 21, liked: false)
        var state = CalendarFeature.State()
        state.currentMonth = FillsaCalendarDateSupport.startOfMonth(for: day21)
        state.selectedDay = day21
        state.memberQuotes = [first, second]
        state.hasLoaded = true
        var refreshed = second
        refreshed.imagePath = "https://example.com/upload.jpg"
        let response = MemberMonthlyQuoteResponse(
            memberQuotes: [first, refreshed],
            monthlySummary: state.monthlySummary
        )
        let uploaded = MemberQuoteImageResponse(memberQuoteSeq: 21, imagePath: "https://example.com/upload.jpg")
        let uploadedSeqs = AsyncStream<Int>.makeStream()
        let store = TestStore(initialState: state) {
            CalendarFeature()
        } withDependencies: {
            $0.sessionClient.isLoggedIn = { true }
            $0.homeUseCases.postUploadImage = { _, seq in
                uploadedSeqs.continuation.yield(seq)
                return uploaded
            }
            $0.calendarUseCases.loadMonth = { _ in response }
        }

        await store.send(.imageTapped(21))
        await store.receive(.imageAccessResolved(21, true)) {
            $0.imageTargetSeq = 21
            $0.isImageDialogPresented = true
        }
        await store.send(.daySelected(day20)) { $0.selectedDay = day20 }
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        try Data("prepared JPEG fixture".utf8).write(to: fileURL)
        let task = await store.send(.imagePicked(fileURL))
        var calls = uploadedSeqs.stream.makeAsyncIterator()
        #expect(await calls.next() == 21)
        await store.receive(.imageUploaded(21, .success(uploaded))) {
            $0.memberQuotes[1].imagePath = uploaded.imagePath
        }
        await store.receive(.refresh) { $0.isLoading = true }
        await store.receive(.monthlyQuotesLoaded(.success(response))) {
            $0.memberQuotes = response.memberQuotes
            $0.monthlySummary = response.monthlySummary
            $0.displayStreakCount = response.monthlySummary.streakCount
            $0.isLoading = false
        }
        await task.finish()
        #expect(store.state.selectedDay == day20)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test @MainActor
    func imagePreparationFailureIsRecordedWithoutStartingUpload() async {
        var state = CalendarFeature.State()
        state.imageTargetSeq = 21
        state.isImageDialogPresented = true
        let store = TestStore(initialState: state) {
            CalendarFeature()
        }

        await store.send(.imagePreparationFailed) { $0.imageUploadFailed = true }
    }

    private func fixtureResponse(streakCount: Int) -> MemberMonthlyQuoteResponse {
        MemberMonthlyQuoteResponse(
            memberQuotes: [],
            monthlySummary: MonthlySummaryData(
                typingCount: 3,
                likeCount: 2,
                streakCount: streakCount
            )
        )
    }

    private func fixtureQuote(day: Int, liked: Bool) -> MemberQuotesData {
        MemberQuotesData(
            dailyQuoteSeq: day,
            quoteDate: String(format: "2025-03-%02d", day),
            quote: "quote \(day)",
            author: "author \(day)",
            completed: true,
            likeYn: liked ? "Y" : "N",
            todayCompleted: true
        )
    }

    private func fixtureDate(year: Int, month: Int, day: Int) -> Date {
        FillsaCalendarDateSupport.calendar.date(
            from: DateComponents(year: year, month: month, day: day)
        )!
    }
}

import ComposableArchitecture
import Foundation
import Testing
@testable import Fiilsa

@Suite("CalendarFeature")
struct CalendarFeatureTests {
    @Test
    func monthlyResponseDecodesQuestionAndAnswerWithoutRequiringThemOnOlderRecords() throws {
        let json = """
        {"memberQuotes":[
          {"dailyQuoteSeq":11,"quoteDate":"2025-03-21","quote":"q","author":"a","completed":true,"likeYn":"N","todayCompleted":true,"questionKo":"첫 질문","answer":"서버 답변"},
          {"dailyQuoteSeq":12,"quoteDate":"2025-03-22","quote":"q2","author":"a2","completed":true,"likeYn":"N","todayCompleted":true}
        ],"monthlySummary":{"typingCount":2,"likeCount":0,"streakCount":2}}
        """

        let response = try JSONDecoder().decode(MemberMonthlyQuoteResponse.self, from: Data(json.utf8))

        #expect(response.memberQuotes[0].questionKo == "첫 질문")
        #expect(response.memberQuotes[0].answer == "서버 답변")
        #expect(response.memberQuotes[1].questionKo == nil)
        #expect(response.memberQuotes[1].answer == nil)
    }

    @Test
    func memberAnswerChangesOnlyAfterServerSuccess() async {
        let day = fixtureDate(year: 2025, month: 3, day: 21)
        var initial = CalendarFeature.State()
        initial.selectedDay = day
        initial.memberQuotes = [answerRecord()]
        initial.isLoggedIn = true
        let saved = AnswerResponse(memberQuoteSeq: 81, answer: "서버에서 정리한 답변", answeredAt: "2025-03-21T12:00:00")
        let store = TestStore(initialState: initial) {
            CalendarFeature()
        } withDependencies: {
            $0.homeUseCases.saveAnswer = { _, _ in saved }
        }

        await store.send(.answerDraftChanged("  작성 중  ")) {
            $0.answerDraft = "  작성 중  "
        }
        await store.send(.answerRecordTapped)
        #expect(store.state.memberQuotes[0].answer == nil)
        await store.receive(.answerSaved(81, .success(saved))) {
            $0.memberQuotes[0].answer = saved.answer
            $0.answerDraft = saved.answer
            $0.recordedAnswer = saved.answer
            $0.isEditingAnswer = false
        }
    }

    @Test
    func memberSaveFailureKeepsTheDraftEditable() async {
        var initial = CalendarFeature.State()
        initial.selectedDay = fixtureDate(year: 2025, month: 3, day: 21)
        initial.memberQuotes = [answerRecord()]
        initial.isLoggedIn = true
        initial.answerDraft = "다시 보낼 답변"
        let store = TestStore(initialState: initial) {
            CalendarFeature()
        } withDependencies: {
            $0.homeUseCases.saveAnswer = { _, _ in throw ErrorResponse.defaultError }
        }

        await store.send(.answerRecordTapped)
        await store.receive(.answerSaved(81, .failure(.defaultError)))
        #expect(store.state.answerDraft == "다시 보낼 답변")
        #expect(store.state.isEditingAnswer)
    }

    @Test
    func nonmemberAnswerStaysInSessionWhenSwitchingSelectedDates() async {
        let day = fixtureDate(year: 2025, month: 3, day: 21)
        let otherDay = fixtureDate(year: 2025, month: 3, day: 22)
        var initial = CalendarFeature.State()
        initial.selectedDay = day
        initial.memberQuotes = [answerRecord()]
        initial.answerDraft = "세션 답변"
        let store = TestStore(initialState: initial) { CalendarFeature() }

        await store.send(.answerRecordTapped) {
            $0.recordedAnswer = "세션 답변"
            $0.isEditingAnswer = false
            $0.sessionAnswers["2025-03-21"] = "세션 답변"
        }
        await store.send(.daySelected(otherDay)) {
            $0.selectedDay = otherDay
            $0.answerDraft = ""
            $0.recordedAnswer = nil
            $0.isEditingAnswer = true
        }
        await store.send(.daySelected(day)) {
            $0.selectedDay = day
            $0.answerDraft = "세션 답변"
            $0.recordedAnswer = "세션 답변"
            $0.isEditingAnswer = false
        }
    }

    private func answerRecord() -> MemberQuotesData {
        MemberQuotesData(dailyQuoteSeq: 81, quoteDate: "2025-03-21", quote: "명언", author: "작가",
                         completed: true, likeYn: "N", todayCompleted: true,
                         questionKo: "오늘의 질문", answer: nil)
    }
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
            $0.isLoggedIn = true
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
            $0.isLoggedIn = true
            $0.hasLoaded = true
            $0.isLoading = false
        }
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

    private func fixtureDate(year: Int, month: Int, day: Int) -> Date {
        FillsaCalendarDateSupport.calendar.date(
            from: DateComponents(year: year, month: month, day: day)
        )!
    }
}

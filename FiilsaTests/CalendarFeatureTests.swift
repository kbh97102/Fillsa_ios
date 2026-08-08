import ComposableArchitecture
import Foundation
import Testing
@testable import Fiilsa

@Suite("CalendarFeature")
struct CalendarFeatureTests {
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

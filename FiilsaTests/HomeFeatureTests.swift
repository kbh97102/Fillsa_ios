import ComposableArchitecture
import Foundation
import Testing
@testable import Fiilsa

@Suite("HomeFeature")
struct HomeFeatureTests {
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
    func completionStateUsesOnlyGenuineCompletedWritingDates() async {
        let completed = StreakInfo(date: "2026-08-10", streakDateCount: 3, isDailyWritingCompleted: true)
        let incomplete = StreakInfo(date: "2026-08-11", streakDateCount: 3, isDailyWritingCompleted: false)
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        }

        await store.send(.completionStateLoaded(3, [completed, incomplete])) {
            $0.streakCount = 3
            $0.isStreakStateLoaded = true
            $0.completedWritingDates = ["2026-08-10"]
        }
    }

    @Test
    func zeroStreakDoesNotRenderAStreakValue() async {
        var initialState = HomeFeature.State()
        initialState.streakCount = 4
        let store = TestStore(initialState: initialState) {
            HomeFeature()
        }

        await store.send(.completionStateLoaded(0, [])) {
            $0.streakCount = nil
            $0.isStreakStateLoaded = true
        }
    }

    @Test
    func calendarTriggerAndZeroStreakTooltipAreMutuallyExclusive() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        }

        await store.send(.completionStateLoaded(0, [])) {
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
        await store.send(.completionStateLoaded(0, [])) {
            $0.isStreakStateLoaded = true
        }
        await store.send(.streakStatusTapped) {
            $0.isStreakTooltipPresented = true
        }
        await store.send(.completionStateLoaded(2, [])) {
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
        await store.receive(.dailyQuoteLoaded(.success(HomeDailyQuoteResult(quote: quote, isLoggedIn: false)))) {
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
    func answerRecordsInHomeSessionAndCanReturnToEditing() async {
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        }

        await store.send(.answerDraftChanged("Home에서만 기록하는 답변")) {
            $0.answerDraft = "Home에서만 기록하는 답변"
        }
        await store.send(.answerRecordTapped) {
            $0.recordedAnswer = "Home에서만 기록하는 답변"
            $0.isEditingAnswer = false
            $0.toastMessage = "답변을 기록했어요."
        }
        await store.send(.answerEditTapped) {
            $0.isEditingAnswer = true
        }
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

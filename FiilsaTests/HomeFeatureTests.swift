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
        }
    }
}

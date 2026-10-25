import ComposableArchitecture
import Foundation
import Testing
@testable import Fiilsa

@Suite("Typing save result")
struct TypingFeatureTests {
    private static let today = Date(timeIntervalSince1970: 1_792_886_400) // 2026-10-25 UTC

    @Test @MainActor
    func saveUsesCurrentCompletionEvenWhenV2FlagsAreFalse() async {
        let today = FillsaCalendarDateSupport.quoteDateString(for: Self.today)
        for (quoteDate, completed, writtenToday, expected) in [
            (today, true, true, TypingSaveResult.streak),
            (today, true, false, .streak),
            ("2026-10-20", true, true, .completed),
            ("2026-10-20", true, false, .encouragement),
            (today, false, false, .incomplete),
            ("2026-10-20", false, true, .incomplete)
        ] {
            let store = TestStore(initialState: TypingFeature.State(
                dailyQuoteSeq: 7, korTyping: "이미 저장한 내용", quoteDate: quoteDate
            )) { TypingFeature() } withDependencies: {
                $0.date.now = Self.today
                $0.typingClient.postTyping = { _, _ in
                    TypingSaveResponse(memberQuoteSeq: 1, completedChanged: false, todayCompletedChanged: false)
                }
                $0.calendarUseCases.loadMonth = { _ in
                    MemberMonthlyQuoteResponse(memberQuotes: [MemberQuotesData(
                        dailyQuoteSeq: 7, quoteDate: quoteDate, quote: "원문", author: "작가",
                        completed: completed, likeYn: "N", todayCompleted: completed && quoteDate == today
                    )], monthlySummary: MonthlySummaryData(typingCount: 0, likeCount: 0, streakCount: 0))
                }
                $0.commonClient.getMemberStreaks = {
                    MemberStreakResponse(currentStreak: writtenToday ? 1 : 0, isTodayWritten: writtenToday)
                }
            }
            await store.send(.saveTapped) { $0.isSaving = true }
            await store.receive(.typingSaved(.success(expected))) {
                $0.isSaving = false
                $0.saveResult = expected
            }
            #expect(store.state.korTyping == "이미 저장한 내용")
        }
    }

    @Test @MainActor
    func incompleteCancelAndRetryShowsPopupAgain() async {
        let store = TestStore(initialState: TypingFeature.State(
            dailyQuoteSeq: 7, korTyping: "중간까지", quoteDate: "2026-10-25", saveResult: .incomplete
        )) { TypingFeature() } withDependencies: {
            $0.date.now = Self.today
            $0.typingClient.postTyping = { _, _ in
                TypingSaveResponse(memberQuoteSeq: 1, completedChanged: false, todayCompletedChanged: false)
            }
            $0.calendarUseCases.loadMonth = { _ in
                MemberMonthlyQuoteResponse(memberQuotes: [], monthlySummary: MonthlySummaryData(typingCount: 0, likeCount: 0, streakCount: 0))
            }
            $0.commonClient.getMemberStreaks = { MemberStreakResponse(currentStreak: 0, isTodayWritten: false) }
        }
        await store.send(.resultCancelled) { $0.saveResult = nil }
        #expect(store.state.korTyping == "중간까지")
        await store.send(.saveTapped) { $0.isSaving = true }
        await store.receive(.typingSaved(.success(.incomplete))) {
            $0.isSaving = false
            $0.saveResult = .incomplete
        }
        await store.send(.resultConfirmed) { $0.saveResult = nil }
    }

    @Test @MainActor
    func completionConfirmationReturnsHome() async {
        for result in [TypingSaveResult.completed, .streak, .encouragement] {
            let store = TestStore(initialState: TypingFeature.State(saveResult: result)) { TypingFeature() }
            await store.send(.resultConfirmed) { $0.saveResult = nil }
            await store.receive(.delegate(.back))
        }
    }

    @Test @MainActor
    func statusLookupFailureKeepsInputWithoutSuccessPopup() async {
        let store = TestStore(initialState: TypingFeature.State(
            dailyQuoteSeq: 7, korTyping: "보존할 입력", quoteDate: "2026-10-25"
        )) { TypingFeature() } withDependencies: {
            $0.typingClient.postTyping = { _, _ in
                TypingSaveResponse(memberQuoteSeq: 1, completedChanged: true, todayCompletedChanged: true)
            }
            $0.calendarUseCases.loadMonth = { _ in throw ErrorResponse.defaultError }
            $0.commonClient.getMemberStreaks = { MemberStreakResponse(currentStreak: 1, isTodayWritten: true) }
        }
        await store.send(.saveTapped) { $0.isSaving = true }
        await store.receive(.typingSaved(.failure(.defaultError))) { $0.isSaving = false }
        #expect(store.state.korTyping == "보존할 입력")
        #expect(store.state.saveResult == nil)
    }

    @Test @MainActor
    func backSavesWithoutCompletionLookup() async {
        let store = TestStore(initialState: TypingFeature.State(dailyQuoteSeq: 7)) { TypingFeature() } withDependencies: {
            $0.typingClient.postTyping = { _, _ in
                TypingSaveResponse(memberQuoteSeq: 1, completedChanged: false, todayCompletedChanged: false)
            }
            $0.calendarUseCases.loadMonth = { _ in
                Issue.record("Back does not need result status")
                throw ErrorResponse.defaultError
            }
        }
        await store.send(.saveAndBack) { $0.isSaving = true }
        await store.receive(.typingSaved(.success(nil))) { $0.isSaving = false }
        await store.receive(.delegate(.back))
    }

    @Test @MainActor
    func staleResponseAfterResetDoesNotNavigate() async {
        let store = TestStore(initialState: TypingFeature.State()) { TypingFeature() }
        await store.send(.typingSaved(.success(.streak)))
        await store.send(.resultConfirmed)
    }

    @Test @MainActor
    func v2ResponseDecodesChangeFlagsWithoutTreatingThemAsCurrentState() throws {
        let data = Data(#"{"memberQuoteSeq":12,"completedChanged":false,"todayCompletedChanged":false}"#.utf8)
        let response = try JSONDecoder().decode(TypingSaveResponse.self, from: data)
        #expect(response.memberQuoteSeq == 12)
        #expect(!response.completedChanged && !response.todayCompletedChanged)
        #expect(APIEndpoint.saveTyping(dailyQuoteSeq: 7) == "/api/v2/member-quotes/7/typing")
        #expect(APIEndpoint.typing(dailyQuoteSeq: 7) == "/api/v1/member-quotes/7/typing")
    }

    @Test @MainActor
    func duplicateSaveDoesNotStartAnotherRequest() async {
        let store = TestStore(initialState: TypingFeature.State(dailyQuoteSeq: 7, isSaving: true)) {
            TypingFeature()
        } withDependencies: {
            $0.typingClient.postTyping = { _, _ in
                Issue.record("A save is already in flight")
                throw ErrorResponse.defaultError
            }
        }
        await store.send(.saveAndBack)
        await store.finish()
    }
}

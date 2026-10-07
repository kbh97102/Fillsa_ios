import ComposableArchitecture
import Foundation

@Reducer
struct CalendarFeature {
    @ObservableState
    struct State: Equatable {
        var memberQuotes: [MemberQuotesData] = []
        var monthlySummary = MonthlySummaryData(typingCount: 0, likeCount: 0, streakCount: 0)
        var displayStreakCount: Int?
        var currentMonth = FillsaCalendarDateSupport.startOfMonth(for: Date())
        var selectedDay = Date()
        var hasLoaded = false
        var isLoading = false
        var isLoggedIn = false
        var answerDraft = ""
        var recordedAnswer: String?
        var isEditingAnswer = true
        var sessionAnswers: [String: String] = [:]
    }

    enum Action: Equatable {
        case onAppear
        case monthChanged(Date)
        case daySelected(Date)
        case bottomQuoteTapped
        case countTapped
        case monthlyQuotesLoaded(Result<MemberMonthlyQuoteResponse, ErrorResponse>)
        case answerDraftChanged(String)
        case answerRecordTapped
        case answerSaved(Int, Result<AnswerResponse, ErrorResponse>)
        case answerEditTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case homeSelected(Date)
            case quoteListSelected(Date)
        }
    }

    @Dependency(\.calendarUseCases) private var calendarUseCases
    @Dependency(\.homeUseCases) private var homeUseCases

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoaded, !state.isLoading else { return .none }
                return load(state: &state)

            case let .monthChanged(month):
                state.currentMonth = month
                state.selectedDay = month
                state.hasLoaded = false
                state.answerDraft = ""
                state.recordedAnswer = nil
                state.isEditingAnswer = true
                return load(state: &state)

            case let .daySelected(day):
                state.selectedDay = day
                restoreAnswer(state: &state)
                return .none

            case .bottomQuoteTapped:
                return .send(.delegate(.homeSelected(state.selectedDay)))

            case .countTapped:
                return .send(.delegate(.quoteListSelected(state.selectedDay)))

            case let .monthlyQuotesLoaded(.success(response)):
                state.memberQuotes = response.memberQuotes
                state.monthlySummary = response.monthlySummary
                state.displayStreakCount = response.monthlySummary.streakCount
                state.isLoggedIn = response.isLoggedIn
                state.hasLoaded = true
                state.isLoading = false
                restoreAnswer(state: &state)
                return .none

            case .monthlyQuotesLoaded(.failure):
                state.memberQuotes = []
                state.monthlySummary = MonthlySummaryData(typingCount: 0, likeCount: 0, streakCount: 0)
                state.displayStreakCount = nil
                state.answerDraft = ""
                state.recordedAnswer = nil
                state.isEditingAnswer = true
                state.hasLoaded = true
                state.isLoading = false
                return .none

            case let .answerDraftChanged(answer):
                state.answerDraft = HomeAnswerInput.limit(answer)
                return .none

            case .answerRecordTapped:
                let answer = HomeAnswerInput.limit(state.answerDraft)
                guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let record = selectedRecord(in: state),
                      CalendarWritingCompletion.isCompleted(record) else { return .none }
                if state.isLoggedIn {
                    let dailyQuoteSeq = record.dailyQuoteSeq
                    return .runWithLoading { send in
                        do {
                            let response = try await homeUseCases.saveAnswer(answer, dailyQuoteSeq)
                            await send(.answerSaved(dailyQuoteSeq, .success(response)))
                        } catch is CancellationError {
                            return
                        } catch let error as ErrorResponse {
                            guard !Task.isCancelled else { return }
                            await send(.answerSaved(dailyQuoteSeq, .failure(error)))
                        } catch {
                            guard !Task.isCancelled else { return }
                            await send(.answerSaved(dailyQuoteSeq, .failure(.defaultError)))
                        }
                    }
                }
                state.answerDraft = answer
                state.recordedAnswer = answer
                state.isEditingAnswer = false
                state.sessionAnswers[record.quoteDate] = answer
                return .none

            case let .answerSaved(dailyQuoteSeq, .success(response)):
                guard let index = state.memberQuotes.firstIndex(where: { $0.dailyQuoteSeq == dailyQuoteSeq }) else { return .none }
                state.memberQuotes[index].answer = response.answer
                if selectedRecord(in: state)?.dailyQuoteSeq == dailyQuoteSeq {
                    state.answerDraft = response.answer
                    state.recordedAnswer = response.answer
                    state.isEditingAnswer = false
                }
                return .none

            case .answerSaved(_, .failure):
                return .none

            case .answerEditTapped:
                state.answerDraft = state.recordedAnswer ?? state.answerDraft
                state.isEditingAnswer = true
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private func selectedRecord(in state: State) -> MemberQuotesData? {
        let date = FillsaCalendarDateSupport.quoteDateString(for: state.selectedDay)
        return state.memberQuotes.first { $0.quoteDate == date }
    }

    private func restoreAnswer(state: inout State) {
        let date = FillsaCalendarDateSupport.quoteDateString(for: state.selectedDay)
        let answer = state.isLoggedIn ? selectedRecord(in: state)?.answer : state.sessionAnswers[date]
        state.recordedAnswer = answer
        state.answerDraft = answer ?? ""
        state.isEditingAnswer = answer == nil
    }

    private func load(state: inout State) -> Effect<Action> {
        state.isLoading = true
        let yearMonth = yearMonthString(for: state.currentMonth)

        return .runWithLoading { send in
            do {
                let response = try await calendarUseCases.loadMonth(yearMonth)
                guard !Task.isCancelled else { return }
                await send(.monthlyQuotesLoaded(.success(response)))
            } catch is CancellationError {
                return
            } catch let error as ErrorResponse {
                guard !Task.isCancelled else { return }
                await send(.monthlyQuotesLoaded(.failure(error)))
            } catch {
                guard !Task.isCancelled else { return }
                await send(.monthlyQuotesLoaded(.failure(.defaultError)))
            }
        }
    }

    private func yearMonthString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}

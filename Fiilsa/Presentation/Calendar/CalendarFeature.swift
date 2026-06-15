import ComposableArchitecture
import Foundation

@Reducer
struct CalendarFeature {
    @ObservableState
    struct State: Equatable {
        var memberQuotes: [MemberQuotesData] = []
        var monthlySummary = MonthlySummaryData(typingCount: 0, likeCount: 0, streakCount: 0)
        var currentMonth = FillsaCalendarDateSupport.startOfMonth(for: Date())
        var hasLoaded = false
        var isLoading = false
    }

    enum Action: Equatable {
        case onAppear
        case monthChanged(Date)
        case monthlyQuotesLoaded(Result<MemberMonthlyQuoteResponse, ErrorResponse>)
        case monthlyQuotesNonMemberLoaded(Result<[MonthlyQuoteResponse], ErrorResponse>)
    }

    @Dependency(\.calendarClient) private var calendarClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoaded, !state.isLoading else { return .none }
                return load(state: &state)

            case let .monthChanged(month):
                state.currentMonth = month
                state.hasLoaded = false
                return load(state: &state)

            case let .monthlyQuotesLoaded(.success(response)):
                state.memberQuotes = response.memberQuotes
                state.monthlySummary = response.monthlySummary
                state.hasLoaded = true
                state.isLoading = false
                return .none

            case .monthlyQuotesLoaded(.failure):
                return loadNonMember(state: &state)

            case let .monthlyQuotesNonMemberLoaded(.success(response)):
                state.memberQuotes = response.map {
                    MemberQuotesData(
                        dailyQuoteSeq: $0.dailyQuoteSeq,
                        quoteDate: $0.quoteDate,
                        quote: $0.quote,
                        author: $0.author,
                        completed: false,
                        likeYn: "N",
                        todayCompleted: false
                    )
                }
                state.monthlySummary = MonthlySummaryData(typingCount: 0, likeCount: 0, streakCount: 0)
                state.hasLoaded = true
                state.isLoading = false
                return .none

            case .monthlyQuotesNonMemberLoaded(.failure):
                state.memberQuotes = []
                state.monthlySummary = MonthlySummaryData(typingCount: 0, likeCount: 0, streakCount: 0)
                state.hasLoaded = true
                state.isLoading = false
                return .none
            }
        }
    }

    private func load(state: inout State) -> Effect<Action> {
        state.isLoading = true
        let yearMonth = yearMonthString(for: state.currentMonth)

        return .run { send in
            do {
                let response = try await calendarClient.getQuotesMonthly(yearMonth)
                await send(.monthlyQuotesLoaded(.success(response)))
            } catch let error as ErrorResponse {
                await send(.monthlyQuotesLoaded(.failure(error)))
            } catch {
                await send(.monthlyQuotesLoaded(.failure(.defaultError)))
            }
        }
    }

    private func loadNonMember(state: inout State) -> Effect<Action> {
        state.isLoading = true
        let yearMonth = yearMonthString(for: state.currentMonth)

        return .run { send in
            do {
                let response = try await calendarClient.getQuotesMonthlyNonMember(yearMonth)
                await send(.monthlyQuotesNonMemberLoaded(.success(response)))
            } catch let error as ErrorResponse {
                await send(.monthlyQuotesNonMemberLoaded(.failure(error)))
            } catch {
                await send(.monthlyQuotesNonMemberLoaded(.failure(.defaultError)))
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

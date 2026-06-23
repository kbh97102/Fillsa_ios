import ComposableArchitecture
import Foundation

@Reducer
struct CalendarFeature {
    @ObservableState
    struct State: Equatable {
        var memberQuotes: [MemberQuotesData] = []
        var monthlySummary = MonthlySummaryData(typingCount: 0, likeCount: 0, streakCount: 0)
        var currentMonth = FillsaCalendarDateSupport.startOfMonth(for: Date())
        var selectedDay = Date()
        var hasLoaded = false
        var isLoading = false
    }

    enum Action: Equatable {
        case onAppear
        case monthChanged(Date)
        case daySelected(Date)
        case bottomQuoteTapped
        case countTapped
        case monthlyQuotesLoaded(Result<MemberMonthlyQuoteResponse, ErrorResponse>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case homeSelected(Date)
            case quoteListSelected(Date)
        }
    }

    @Dependency(\.calendarUseCases) private var calendarUseCases

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
                return load(state: &state)

            case let .daySelected(day):
                state.selectedDay = day
                return .none

            case .bottomQuoteTapped:
                return .send(.delegate(.homeSelected(state.selectedDay)))

            case .countTapped:
                return .send(.delegate(.quoteListSelected(state.selectedDay)))

            case let .monthlyQuotesLoaded(.success(response)):
                state.memberQuotes = response.memberQuotes
                state.monthlySummary = response.monthlySummary
                state.hasLoaded = true
                state.isLoading = false
                return .none

            case .monthlyQuotesLoaded(.failure):
                state.memberQuotes = []
                state.monthlySummary = MonthlySummaryData(typingCount: 0, likeCount: 0, streakCount: 0)
                state.hasLoaded = true
                state.isLoading = false
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private func load(state: inout State) -> Effect<Action> {
        state.isLoading = true
        let yearMonth = yearMonthString(for: state.currentMonth)

        return .run { send in
            do {
                let response = try await calendarUseCases.loadMonth(yearMonth)
                await send(.monthlyQuotesLoaded(.success(response)))
            } catch let error as ErrorResponse {
                await send(.monthlyQuotesLoaded(.failure(error)))
            } catch {
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

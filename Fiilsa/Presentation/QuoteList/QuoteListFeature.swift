import ComposableArchitecture
import Foundation

@Reducer
struct QuoteListFeature {
    @ObservableState
    struct State: Equatable {
        var list: [MemberQuotesResponse] = []
        var startDate = FillsaCalendarDateSupport.startDay
        var endDate = Date()
        var likeFilter = false
        var hasLoaded = false
        var isLoading = false
    }

    enum Action: Equatable {
        case onAppear
        case dateRangeChanged(Date, Date)
        case likeFilterChanged(Bool)
        case quotesLoaded(Result<PageResponseMemberQuotesResponse, ErrorResponse>)
    }

    @Dependency(\.quoteListClient) private var quoteListClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoaded, !state.isLoading else { return .none }
                return load(state: &state)

            case let .dateRangeChanged(startDate, endDate):
                state.startDate = startDate
                state.endDate = endDate
                state.hasLoaded = false
                return load(state: &state)

            case let .likeFilterChanged(isLike):
                state.likeFilter = isLike
                state.hasLoaded = false
                return load(state: &state)

            case let .quotesLoaded(.success(response)):
                state.list = response.content
                state.hasLoaded = true
                state.isLoading = false
                return .none

            case .quotesLoaded(.failure):
                state.list = []
                state.hasLoaded = true
                state.isLoading = false
                return .none
            }
        }
    }

    private func load(state: inout State) -> Effect<Action> {
        state.isLoading = true
        let likeYn = state.likeFilter ? "Y" : ""
        let startDate = FillsaCalendarDateSupport.quoteDateString(for: state.startDate)
        let endDate = FillsaCalendarDateSupport.quoteDateString(for: state.endDate)

        return .run { send in
            do {
                let response = try await quoteListClient.getQuotesList(0, 30, likeYn, startDate, endDate)
                await send(.quotesLoaded(.success(response)))
            } catch let error as ErrorResponse {
                await send(.quotesLoaded(.failure(error)))
            } catch {
                await send(.quotesLoaded(.failure(.defaultError)))
            }
        }
    }
}

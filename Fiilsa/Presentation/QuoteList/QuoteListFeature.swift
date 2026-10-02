import ComposableArchitecture
import Foundation

@Reducer
struct QuoteListFeature {
    enum EmptyState: Equatable {
        case general
        case searchResult
    }

    @ObservableState
    struct State: Equatable {
        var list: [MemberQuotesResponse] = []
        var startDate = QuoteListDateSupport.defaultStartDate
        var endDate = Date()
        var likeFilter = false
        var hasLoaded = false
        var isLoading = false
        var currentPage = 0
        var totalPages = 1
        var hasAppliedSearchCondition = false
        var loadFailed = false

        var emptyState: EmptyState? {
            guard hasLoaded, !isLoading, !loadFailed, list.isEmpty else { return nil }
            return hasAppliedSearchCondition ? .searchResult : .general
        }
    }

    enum Action: Equatable {
        case onAppear
        case refresh
        case loadNextPage
        case dateRangeChanged(Date, Date)
        case likeFilterChanged(Bool)
        case quotesLoaded(Result<PageResponseMemberQuotesResponse, ErrorResponse>)
    }

    @Dependency(\.quoteListUseCases) private var quoteListUseCases

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoaded, !state.isLoading else { return .none }
                return load(state: &state, page: 0, reset: true)

            case .refresh:
                return load(state: &state, page: 0, reset: true)

            case .loadNextPage:
                guard state.hasLoaded, !state.isLoading, state.currentPage + 1 < state.totalPages else {
                    return .none
                }
                return load(state: &state, page: state.currentPage + 1, reset: false)

            case let .dateRangeChanged(startDate, endDate):
                state.startDate = startDate
                state.endDate = endDate
                state.hasAppliedSearchCondition = true
                return load(state: &state, page: 0, reset: true)

            case let .likeFilterChanged(isLike):
                state.likeFilter = isLike
                state.hasAppliedSearchCondition = true
                return load(state: &state, page: 0, reset: true)

            case let .quotesLoaded(.success(response)):
                if response.currentPage == 0 {
                    state.list = response.content
                } else {
                    state.list.append(contentsOf: response.content)
                }
                state.currentPage = response.currentPage
                state.totalPages = response.totalPages
                state.hasLoaded = true
                state.isLoading = false
                state.loadFailed = false
                return .none

            case .quotesLoaded(.failure):
                state.list = []
                state.hasLoaded = true
                state.isLoading = false
                state.loadFailed = true
                return .none
            }
        }
    }

    private func load(state: inout State, page: Int, reset: Bool) -> Effect<Action> {
        state.isLoading = true
        if reset {
            state.hasLoaded = false
            state.currentPage = 0
            state.totalPages = 1
            state.loadFailed = false
        }
        let likeYn = state.likeFilter ? "Y" : "N"
        let startDate = FillsaCalendarDateSupport.quoteDateString(for: state.startDate)
        let endDate = FillsaCalendarDateSupport.quoteDateString(for: state.endDate)

        return .runWithLoading { send in
            do {
                let response = try await quoteListUseCases.loadList(page, 30, likeYn, startDate, endDate)
                guard !Task.isCancelled else { return }
                await send(.quotesLoaded(.success(response)))
            } catch is CancellationError {
                return
            } catch let error as ErrorResponse {
                guard !Task.isCancelled else { return }
                await send(.quotesLoaded(.failure(error)))
            } catch {
                guard !Task.isCancelled else { return }
                await send(.quotesLoaded(.failure(.defaultError)))
            }
        }
        .cancellable(id: "QuoteListFeature.load", cancelInFlight: reset)
    }
}

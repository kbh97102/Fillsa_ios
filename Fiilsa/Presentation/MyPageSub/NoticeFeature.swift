import ComposableArchitecture

@Reducer
struct NoticeFeature {
    @ObservableState
    struct State: Equatable {
        var notices: [NoticeResponse] = []
        var hasLoaded = false
        var isLoading = false
    }

    enum Action: Equatable {
        case onAppear
        case noticesLoaded(Result<PageResponseNoticeResponse, ErrorResponse>)
        case backTapped
        case noticeTapped(NoticeResponse)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case back
            case noticeSelected(NoticeResponse)
        }
    }

    @Dependency(\.commonClient) private var commonClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoaded, !state.isLoading else { return .none }
                state.isLoading = true

                return .run { send in
                    do {
                        let response = try await commonClient.getNotice(0, 30)
                        await send(.noticesLoaded(.success(response)))
                    } catch let error as ErrorResponse {
                        await send(.noticesLoaded(.failure(error)))
                    } catch {
                        await send(.noticesLoaded(.failure(.defaultError)))
                    }
                }

            case let .noticesLoaded(.success(response)):
                state.notices = response.content
                state.hasLoaded = true
                state.isLoading = false
                return .none

            case .noticesLoaded(.failure):
                state.notices = []
                state.hasLoaded = true
                state.isLoading = false
                return .none

            case .backTapped:
                return .send(.delegate(.back))

            case let .noticeTapped(notice):
                return .send(.delegate(.noticeSelected(notice)))

            case .delegate:
                return .none
            }
        }
    }
}

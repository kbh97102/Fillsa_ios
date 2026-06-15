import ComposableArchitecture

@Reducer
struct MemoInsertFeature {
    @ObservableState
    struct State: Equatable {
        var savedMemo = ""
        var memberQuoteSeq = 0
        var isSaving = false
    }

    enum Action: Equatable {
        case saveAndBack(String)
        case memoSaved(Result<Int, ErrorResponse>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case back
        }
    }

    @Dependency(\.quoteListClient) private var quoteListClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .saveAndBack(memo):
                guard state.memberQuoteSeq > 0 else {
                    return .send(.delegate(.back))
                }
                state.savedMemo = memo
                state.isSaving = true
                let memberQuoteSeq = state.memberQuoteSeq

                return .run { send in
                    do {
                        let response = try await quoteListClient.postSaveMemo(
                            MemoRequest(memo: memo),
                            String(memberQuoteSeq)
                        )
                        await send(.memoSaved(.success(response)))
                    } catch let error as ErrorResponse {
                        await send(.memoSaved(.failure(error)))
                    } catch {
                        await send(.memoSaved(.failure(.defaultError)))
                    }
                }

            case .memoSaved:
                state.isSaving = false
                return .send(.delegate(.back))

            case .delegate:
                return .none
            }
        }
    }
}

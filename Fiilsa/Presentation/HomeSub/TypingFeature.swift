import ComposableArchitecture

@Reducer
struct TypingFeature {
    @ObservableState
    struct State: Equatable {
        var dailyQuoteSeq = 0
        var korQuote = ""
        var engQuote = ""
        var korAuthor = ""
        var engAuthor = ""
        var korTyping = ""
        var engTyping = ""
        var likeYn = "N"
        var hasLoaded = false
        var isSaving = false
    }

    enum Action: Equatable {
        case onAppear
        case typingLoaded(Result<MemberTypingQuoteResponse, ErrorResponse>)
        case korTypingChanged(String)
        case engTypingChanged(String)
        case saveAndBack
        case typingSaved(Result<Int, ErrorResponse>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case back
        }
    }

    @Dependency(\.typingClient) private var typingClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.dailyQuoteSeq > 0, !state.hasLoaded else { return .none }
                let dailyQuoteSeq = state.dailyQuoteSeq

                return .run { send in
                    do {
                        let response = try await typingClient.getTyping(dailyQuoteSeq)
                        await send(.typingLoaded(.success(response)))
                    } catch let error as ErrorResponse {
                        await send(.typingLoaded(.failure(error)))
                    } catch {
                        await send(.typingLoaded(.failure(.defaultError)))
                    }
                }

            case let .typingLoaded(.success(response)):
                state.korQuote = response.korQuote ?? state.korQuote
                state.engQuote = response.engQuote ?? state.engQuote
                state.korTyping = response.typingKorQuote ?? ""
                state.engTyping = response.typingEngQuote ?? ""
                state.likeYn = response.likeYn
                state.hasLoaded = true
                return .none

            case .typingLoaded(.failure):
                state.hasLoaded = true
                return .none

            case let .korTypingChanged(value):
                state.korTyping = value
                return .none

            case let .engTypingChanged(value):
                state.engTyping = value
                return .none

            case .saveAndBack:
                guard state.dailyQuoteSeq > 0 else {
                    return .send(.delegate(.back))
                }
                state.isSaving = true
                let dailyQuoteSeq = state.dailyQuoteSeq
                let request = TypingQuoteRequest(
                    typingKorQuote: state.korTyping,
                    typingEngQuote: state.engTyping
                )

                return .run { send in
                    do {
                        let response = try await typingClient.postTyping(dailyQuoteSeq, request)
                        await send(.typingSaved(.success(response)))
                    } catch let error as ErrorResponse {
                        await send(.typingSaved(.failure(error)))
                    } catch {
                        await send(.typingSaved(.failure(.defaultError)))
                    }
                }

            case .typingSaved:
                state.isSaving = false
                return .send(.delegate(.back))

            case .delegate:
                return .none
            }
        }
    }
}

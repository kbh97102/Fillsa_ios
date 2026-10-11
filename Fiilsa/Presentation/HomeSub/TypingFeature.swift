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
        var quoteDate = ""
        var dayOfWeek = ""
        var hasLoaded = false
        var isSaving = false
    }

    enum Action: Equatable {
        case onAppear
        case typingLoaded(Result<MemberTypingQuoteResponse, ErrorResponse>)
        case korTypingChanged(String)
        case engTypingChanged(String)
        case likeTapped(Bool)
        case likeUpdated(Result<Int, ErrorResponse>)
        case saveAndBack
        case typingSaved(Result<Int, ErrorResponse>)
        case saveCancelled
        case delegate(Delegate)

        enum Delegate: Equatable {
            case back
        }
    }

    @Dependency(\.typingClient) private var typingClient
    @Dependency(\.homeUseCases) private var homeUseCases

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.dailyQuoteSeq > 0, !state.hasLoaded else { return .none }
                let dailyQuoteSeq = state.dailyQuoteSeq

                return .runWithLoading { send in
                    do {
                        let response = try await typingClient.getTyping(dailyQuoteSeq)
                        guard !Task.isCancelled else { return }
                        await send(.typingLoaded(.success(response)))
                    } catch is CancellationError {
                        return
                    } catch let error as ErrorResponse {
                        guard !Task.isCancelled else { return }
                        await send(.typingLoaded(.failure(error)))
                    } catch {
                        guard !Task.isCancelled else { return }
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

            case let .likeTapped(isLike):
                state.likeYn = isLike ? "Y" : "N"

                guard state.dailyQuoteSeq > 0 else { return .none }
                let quote = DailyQuote(
                    likeYn: state.likeYn,
                    dailyQuoteSeq: state.dailyQuoteSeq,
                    korQuote: state.korQuote,
                    engQuote: state.engQuote,
                    korAuthor: state.korAuthor,
                    engAuthor: state.engAuthor,
                    quoteDate: state.quoteDate
                )
                let quoteDate = state.quoteDate
                let dayOfWeek = state.dayOfWeek

                return .runWithLoading { send in
                    do {
                        let response = try await homeUseCases.updateLike(
                            isLike,
                            quote,
                            quoteDate,
                            dayOfWeek
                        )
                        guard !Task.isCancelled else { return }
                        await send(.likeUpdated(.success(response)))
                    } catch is CancellationError {
                        return
                    } catch let error as ErrorResponse {
                        guard !Task.isCancelled else { return }
                        await send(.likeUpdated(.failure(error)))
                    } catch {
                        guard !Task.isCancelled else { return }
                        await send(.likeUpdated(.failure(.defaultError)))
                    }
                }

            case .likeUpdated:
                return .none

            case .saveAndBack:
                guard state.dailyQuoteSeq > 0 else {
                    return .send(.delegate(.back))
                }
                state.isSaving = true
                let dailyQuoteSeq = state.dailyQuoteSeq
                let request = TypingQuoteRequest(typingKorQuote: state.korTyping, typingEngQuote: state.engTyping)

                return .runWithLoading { send in
                    do {
                        let response = try await typingClient.postTyping(dailyQuoteSeq, request)
                        guard !Task.isCancelled else { return }
                        await send(.typingSaved(.success(response)))
                    } catch is CancellationError {
                        await send(.saveCancelled)
                        return
                    } catch let error as ErrorResponse {
                        guard !Task.isCancelled else { return }
                        await send(.typingSaved(.failure(error)))
                    } catch {
                        guard !Task.isCancelled else { return }
                        await send(.typingSaved(.failure(.defaultError)))
                    }
                }

            case .typingSaved(.success):
                state.isSaving = false
                return .send(.delegate(.back))

            case .typingSaved(.failure):
                state.isSaving = false
                return .none

            case .saveCancelled:
                state.isSaving = false
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

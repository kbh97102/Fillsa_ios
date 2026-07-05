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
        case localTypingLoaded(LocalQuoteInfo?)
        case korTypingChanged(String)
        case engTypingChanged(String)
        case likeTapped(Bool)
        case likeUpdated(Result<Int, ErrorResponse>)
        case saveAndBack
        case typingSaved(Result<Int, ErrorResponse>)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case back
        }
    }

    @Dependency(\.typingClient) private var typingClient
    @Dependency(\.sessionClient) private var sessionClient
    @Dependency(\.localQuoteClient) private var localQuoteClient
    @Dependency(\.homeUseCases) private var homeUseCases

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.dailyQuoteSeq > 0, !state.hasLoaded else { return .none }
                let dailyQuoteSeq = state.dailyQuoteSeq

                return .run { send in
                    do {
                        let isLoggedIn = (try? await sessionClient.isLoggedIn()) ?? false
                        if isLoggedIn {
                            let response = try await typingClient.getTyping(dailyQuoteSeq)
                            await send(.typingLoaded(.success(response)))
                        } else {
                            let localQuote = try await localQuoteClient.findById(dailyQuoteSeq)
                            await send(.localTypingLoaded(localQuote))
                        }
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

            case let .localTypingLoaded(localQuote):
                state.korTyping = localQuote?.korTyping ?? ""
                state.engTyping = localQuote?.engTyping ?? ""
                state.likeYn = localQuote?.likeYn ?? state.likeYn
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

                return .run { send in
                    do {
                        let response = try await homeUseCases.updateLike(
                            isLike,
                            quote,
                            quoteDate,
                            dayOfWeek
                        )
                        await send(.likeUpdated(.success(response)))
                    } catch let error as ErrorResponse {
                        await send(.likeUpdated(.failure(error)))
                    } catch {
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
                let localQuote = LocalQuoteInfo(
                    dailyQuoteSeq: dailyQuoteSeq,
                    korQuote: state.korQuote,
                    engQuote: state.engQuote,
                    korAuthor: state.korAuthor,
                    engAuthor: state.engAuthor,
                    korTyping: state.korTyping,
                    engTyping: state.engTyping,
                    likeYn: state.likeYn,
                    memo: "",
                    date: state.quoteDate,
                    dayOfWeek: state.dayOfWeek
                )
                let request = TypingQuoteRequest(typingKorQuote: state.korTyping, typingEngQuote: state.engTyping)

                return .run { send in
                    do {
                        let isLoggedIn = (try? await sessionClient.isLoggedIn()) ?? false
                        if isLoggedIn {
                            let response = try await typingClient.postTyping(dailyQuoteSeq, request)
                            await send(.typingSaved(.success(response)))
                        } else {
                            let storedQuote = try await localQuoteClient.findById(dailyQuoteSeq)
                            if localQuote.korTyping.isEmpty,
                               localQuote.engTyping.isEmpty,
                               storedQuote?.memo.isEmpty == true,
                               storedQuote?.likeYn != "Y" {
                                try await localQuoteClient.deleteBySeq(dailyQuoteSeq)
                            } else {
                                try await localQuoteClient.add(
                                    LocalQuoteInfo(
                                        dailyQuoteSeq: localQuote.dailyQuoteSeq,
                                        korQuote: localQuote.korQuote,
                                        engQuote: localQuote.engQuote,
                                        korAuthor: localQuote.korAuthor,
                                        engAuthor: localQuote.engAuthor,
                                        korTyping: localQuote.korTyping,
                                        engTyping: localQuote.engTyping,
                                        likeYn: localQuote.likeYn,
                                        memo: storedQuote?.memo ?? localQuote.memo,
                                        date: localQuote.date,
                                        dayOfWeek: localQuote.dayOfWeek
                                    )
                                )
                            }
                            await send(.typingSaved(.success(1)))
                        }
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

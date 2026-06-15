import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var quote = DailyQuote()
        var hasLoaded = false
        var isLoading = false
    }

    enum Action: Equatable {
        case onAppear
        case dailyQuoteLoaded(Result<DailyQuote, ErrorResponse>)
        case likeTapped(Bool)
        case likeUpdated(Result<Int, ErrorResponse>)
    }

    @Dependency(\.homeClient) private var homeClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoaded, !state.isLoading else { return .none }
                state.isLoading = true
                let quoteDate = FillsaCalendarDateSupport.quoteDateString(for: Date())

                return .run { send in
                    do {
                        let response = try await homeClient.getDailyQuote(quoteDate)
                        await send(.dailyQuoteLoaded(.success(response)))
                    } catch {
                        do {
                            let response = try await homeClient.getDailyQuoteNoToken(quoteDate)
                            await send(
                                .dailyQuoteLoaded(
                                    .success(
                                        DailyQuote(
                                            dailyQuoteSeq: response.dailyQuoteSeq,
                                            korQuote: response.korQuote,
                                            engQuote: response.engQuote,
                                            korAuthor: response.korAuthor,
                                            engAuthor: response.engAuthor,
                                            authorUrl: response.authorUrl,
                                            quoteDate: quoteDate
                                        )
                                    )
                                )
                            )
                        } catch let error as ErrorResponse {
                            await send(.dailyQuoteLoaded(.failure(error)))
                        } catch {
                            await send(.dailyQuoteLoaded(.failure(.defaultError)))
                        }
                    }
                }

            case let .dailyQuoteLoaded(.success(quote)):
                state.quote = quote
                state.hasLoaded = true
                state.isLoading = false
                return .none

            case .dailyQuoteLoaded(.failure):
                state.hasLoaded = true
                state.isLoading = false
                return .none

            case let .likeTapped(isLike):
                state.quote = DailyQuote(
                    likeYn: isLike ? "Y" : "N",
                    imagePath: state.quote.imagePath,
                    dailyQuoteSeq: state.quote.dailyQuoteSeq,
                    korQuote: state.quote.korQuote,
                    engQuote: state.quote.engQuote,
                    korAuthor: state.quote.korAuthor,
                    engAuthor: state.quote.engAuthor,
                    authorUrl: state.quote.authorUrl,
                    quoteDate: state.quote.quoteDate
                )

                guard state.quote.dailyQuoteSeq > 0 else { return .none }
                let dailyQuoteSeq = state.quote.dailyQuoteSeq
                return .run { send in
                    do {
                        let response = try await homeClient.postLike(
                            LikeRequest(likeYn: isLike ? "Y" : "N"),
                            dailyQuoteSeq
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
            }
        }
    }
}

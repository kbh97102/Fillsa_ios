import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var quote = DailyQuote()
        var date = Date()
        var isLoggedIn = false
        var hasLoaded = false
        var isLoading = false
    }

    enum Action: Equatable {
        case onAppear
        case beforeTapped
        case nextTapped
        case loginStatusLoaded(Bool)
        case dailyQuoteLoaded(Result<DailyQuote, ErrorResponse>)
        case likeTapped(Bool)
        case likeUpdated(Result<Int, ErrorResponse>)
        case localLikeUpdated(Result<Int, ErrorResponse>)
    }

    @Dependency(\.homeClient) private var homeClient
    @Dependency(\.localQuoteClient) private var localQuoteClient
    @Dependency(\.sessionClient) private var sessionClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoaded, !state.isLoading else { return .none }
                return load(state: &state)

            case .beforeTapped:
                let targetDate = FillsaCalendarDateSupport.calendar.date(byAdding: .day, value: -1, to: state.date) ?? state.date
                guard targetDate >= FillsaCalendarDateSupport.startDay else { return .none }
                state.date = targetDate
                state.hasLoaded = false
                return load(state: &state)

            case .nextTapped:
                let targetDate = FillsaCalendarDateSupport.calendar.date(byAdding: .day, value: 1, to: state.date) ?? state.date
                guard FillsaCalendarDateSupport.calendar.startOfDay(for: targetDate) <= FillsaCalendarDateSupport.calendar.startOfDay(for: Date()) else {
                    return .none
                }
                state.date = targetDate
                state.hasLoaded = false
                return load(state: &state)

            case let .loginStatusLoaded(isLoggedIn):
                state.isLoggedIn = isLoggedIn
                return .none

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
                guard state.isLoggedIn else {
                    let quote = state.quote
                    let date = state.date
                    let dayOfWeek = dayOfWeekString(for: date)
                    return .run { send in
                        do {
                            if try await localQuoteClient.findById(dailyQuoteSeq) == nil {
                                try await localQuoteClient.add(
                                    LocalQuoteInfo(
                                        dailyQuoteSeq: quote.dailyQuoteSeq,
                                        korQuote: quote.korQuote ?? "",
                                        engQuote: quote.engQuote ?? "",
                                        korAuthor: quote.korAuthor ?? "",
                                        engAuthor: quote.engAuthor ?? "",
                                        korTyping: "",
                                        engTyping: "",
                                        likeYn: isLike ? "Y" : "N",
                                        memo: "",
                                        date: FillsaCalendarDateSupport.quoteDateString(for: date),
                                        dayOfWeek: dayOfWeek
                                    )
                                )
                                await send(.localLikeUpdated(.success(1)))
                            } else {
                                let result = try await localQuoteClient.updateLike(isLike ? .yes : .no, dailyQuoteSeq)
                                await send(.localLikeUpdated(.success(result)))
                            }
                        } catch let error as ErrorResponse {
                            await send(.localLikeUpdated(.failure(error)))
                        } catch {
                            await send(.localLikeUpdated(.failure(.defaultError)))
                        }
                    }
                }

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

            case .likeUpdated, .localLikeUpdated:
                return .none
            }
        }
    }

    private func load(state: inout State) -> Effect<Action> {
        state.isLoading = true
        let quoteDate = FillsaCalendarDateSupport.quoteDateString(for: state.date)

        return .run { send in
            let isLoggedIn = (try? await sessionClient.isLoggedIn()) ?? false
            await send(.loginStatusLoaded(isLoggedIn))

            if isLoggedIn {
                do {
                    let response = try await homeClient.getDailyQuote(quoteDate)
                    await send(.dailyQuoteLoaded(.success(response)))
                } catch let error as ErrorResponse {
                    await send(.dailyQuoteLoaded(.failure(error)))
                } catch {
                    await send(.dailyQuoteLoaded(.failure(.defaultError)))
                }
            } else {
                do {
                    let response = try await homeClient.getDailyQuoteNoToken(quoteDate)
                    let localQuote = try await localQuoteClient.findById(response.dailyQuoteSeq)
                    await send(
                        .dailyQuoteLoaded(
                            .success(
                                DailyQuote(
                                    likeYn: localQuote?.likeYn ?? "N",
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
    }

    private func dayOfWeekString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).uppercased()
    }
}

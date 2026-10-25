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
        var saveResult: TypingSaveResult?
    }

    enum Action: Equatable {
        case onAppear
        case typingLoaded(Result<MemberTypingQuoteResponse, ErrorResponse>)
        case korTypingChanged(String)
        case engTypingChanged(String)
        case likeTapped(Bool)
        case likeUpdated(Result<Int, ErrorResponse>)
        case saveAndBack
        case saveTapped
        case typingSaved(Result<TypingSaveResult?, ErrorResponse>)
        case resultConfirmed
        case resultCancelled
        case saveCancelled
        case delegate(Delegate)

        enum Delegate: Equatable {
            case back
        }
    }

    @Dependency(\.typingClient) private var typingClient
    @Dependency(\.homeUseCases) private var homeUseCases
    @Dependency(\.calendarUseCases) private var calendarUseCases
    @Dependency(\.commonClient) private var commonClient
    @Dependency(\.date.now) private var now

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

            case .saveAndBack, .saveTapped:
                guard !state.isSaving, state.saveResult == nil else { return .none }
                guard state.dailyQuoteSeq > 0 else {
                    return action == .saveAndBack ? .send(.delegate(.back)) : .none
                }
                state.isSaving = true
                let dailyQuoteSeq = state.dailyQuoteSeq
                let quoteDate = state.quoteDate
                let showsResult = action == .saveTapped
                let request = TypingQuoteRequest(typingKorQuote: state.korTyping, typingEngQuote: state.engTyping)

                return .runWithLoading { send in
                    do {
                        _ = try await typingClient.postTyping(dailyQuoteSeq, request)
                        guard !Task.isCancelled else { return }
                        guard showsResult else {
                            await send(.typingSaved(.success(nil)))
                            return
                        }
                        // Change flags cannot distinguish an incomplete quote from a completed re-save.
                        guard quoteDate.count == 10 else { throw ErrorResponse.defaultError }
                        let records = try await calendarUseCases.loadMonth(String(quoteDate.prefix(7)))
                        guard records.isLoggedIn else { throw ErrorResponse.defaultError }
                        let completed = records.memberQuotes.first { $0.dailyQuoteSeq == dailyQuoteSeq }?.completed == true
                        let today = await FillsaCalendarDateSupport.quoteDateString(for: now)
                        let result: TypingSaveResult
                        if !completed {
                            result = .incomplete
                        } else if quoteDate == today {
                            result = .streak
                        } else {
                            let writingStatus = try await commonClient.getMemberStreaks()
                            result = writingStatus.isTodayWritten ? .completed : .encouragement
                        }
                        guard !Task.isCancelled else { return }
                        await send(.typingSaved(.success(result)))
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

            case let .typingSaved(.success(result)):
                guard state.isSaving else { return .none }
                state.isSaving = false
                state.saveResult = result
                return result == nil ? .send(.delegate(.back)) : .none

            case .resultConfirmed:
                guard let result = state.saveResult else { return .none }
                state.saveResult = nil
                return result == .incomplete ? .none : .send(.delegate(.back))

            case .resultCancelled:
                state.saveResult = nil
                return .none

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

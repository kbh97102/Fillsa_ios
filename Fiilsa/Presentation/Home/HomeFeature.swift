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
        var isImageDialogPresented = false
        var isLoginRequiredDialogPresented = false
        var isDeleteImageConfirmationPresented = false
        var toastMessage: String?
    }

    enum Action: Equatable {
        case onAppear
        case beforeTapped
        case nextTapped
        case dailyQuoteLoaded(Result<HomeDailyQuoteResult, ErrorResponse>)
        case likeTapped(Bool)
        case likeUpdated(Result<Int, ErrorResponse>)
        case imageTapped
        case imageDialogDismissed
        case loginRequiredDialogDismissed
        case deleteImageTapped
        case deleteImageCancelled
        case deleteImageConfirmed
        case imageDeleted(Result<Int, ErrorResponse>)
        case imagePicked(URL)
        case imageUploaded(Result<MemberQuoteImageResponse, ErrorResponse>)
        case copyCompleted
        case toastDismissed
    }

    @Dependency(\.homeUseCases) private var homeUseCases

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

            case let .dailyQuoteLoaded(.success(result)):
                state.quote = result.quote
                state.isLoggedIn = result.isLoggedIn
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
                let quote = state.quote
                let quoteDate = FillsaCalendarDateSupport.quoteDateString(for: state.date)
                let dayOfWeek = dayOfWeekString(for: state.date)

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

            case .imageTapped:
                guard state.isLoggedIn else {
                    state.isLoginRequiredDialogPresented = true
                    return .none
                }
                state.isImageDialogPresented = true
                return .none

            case .imageDialogDismissed:
                state.isImageDialogPresented = false
                return .none

            case .loginRequiredDialogDismissed:
                state.isLoginRequiredDialogPresented = false
                return .none

            case .deleteImageTapped:
                state.isDeleteImageConfirmationPresented = true
                return .none

            case .deleteImageCancelled:
                state.isDeleteImageConfirmationPresented = false
                return .none

            case .deleteImageConfirmed:
                state.isDeleteImageConfirmationPresented = false
                guard state.quote.dailyQuoteSeq > 0 else { return .none }
                let dailyQuoteSeq = state.quote.dailyQuoteSeq

                return .run { send in
                    do {
                        let response = try await homeUseCases.deleteUploadImage(dailyQuoteSeq)
                        await send(.imageDeleted(.success(response)))
                    } catch let error as ErrorResponse {
                        await send(.imageDeleted(.failure(error)))
                    } catch {
                        await send(.imageDeleted(.failure(.defaultError)))
                    }
                }

            case .imageDeleted(.success):
                state.quote = state.quote.copy(imagePath: "")
                state.toastMessage = "이미지가 삭제되었습니다."
                return .none

            case .imageDeleted(.failure):
                state.toastMessage = "이미지 삭제에 실패했습니다."
                return .none

            case let .imagePicked(fileURL):
                guard state.quote.dailyQuoteSeq > 0 else { return .none }
                let dailyQuoteSeq = state.quote.dailyQuoteSeq

                return .run { send in
                    do {
                        let response = try await homeUseCases.postUploadImage(fileURL, dailyQuoteSeq)
                        await send(.imageUploaded(.success(response)))
                    } catch let error as ErrorResponse {
                        await send(.imageUploaded(.failure(error)))
                    } catch {
                        await send(.imageUploaded(.failure(.defaultError)))
                    }
                }

            case let .imageUploaded(.success(response)):
                state.quote = state.quote.copy(imagePath: response.imagePath)
                state.toastMessage = "이미지가 변경되었습니다."
                return .none

            case .imageUploaded(.failure):
                state.toastMessage = "이미지 변경에 실패했습니다."
                return .none

            case .copyCompleted:
                state.toastMessage = "복사되었습니다."
                return .none

            case .toastDismissed:
                state.toastMessage = nil
                return .none
            }
        }
    }

    private func load(state: inout State) -> Effect<Action> {
        state.isLoading = true
        let quoteDate = FillsaCalendarDateSupport.quoteDateString(for: state.date)

        return .run { send in
            do {
                let response = try await homeUseCases.loadDailyQuote(quoteDate)
                await send(.dailyQuoteLoaded(.success(response)))
            } catch let error as ErrorResponse {
                await send(.dailyQuoteLoaded(.failure(error)))
            } catch {
                await send(.dailyQuoteLoaded(.failure(.defaultError)))
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

private extension DailyQuote {
    func copy(
        likeYn: String? = nil,
        imagePath: String? = nil
    ) -> DailyQuote {
        DailyQuote(
            likeYn: likeYn ?? self.likeYn,
            imagePath: imagePath ?? self.imagePath,
            dailyQuoteSeq: dailyQuoteSeq,
            korQuote: korQuote,
            engQuote: engQuote,
            korAuthor: korAuthor,
            engAuthor: engAuthor,
            authorUrl: authorUrl,
            quoteDate: quoteDate
        )
    }
}

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
        var streakCount: Int?
        var isStreakStateLoaded = false
        var completedWritingDates: Set<String> = []
        var isCalendarPresented = false
        var calendarDisplayedMonth = FillsaCalendarDateSupport.startOfMonth(for: Date())
        var isStreakTooltipPresented = false
        var answerDraft = ""
        var recordedAnswer: String?
        var isEditingAnswer = true
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
        case completionStateLoaded(Int, [StreakInfo])
        case calendarTriggerTapped
        case calendarDismissed
        case calendarMonthChanged(Date)
        case calendarDateSelected(Date)
        case streakStatusTapped
        case streakTooltipDismissed
        case answerDraftChanged(String)
        case answerRecordTapped
        case answerEditTapped
    }

    @Dependency(\.homeUseCases) private var homeUseCases
    @Dependency(\.streakClient) private var streakClient
    @Dependency(\.loadingClient) private var loadingClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoaded, !state.isLoading else { return .none }
                state.isLoading = true
                let quoteDate = FillsaCalendarDateSupport.quoteDateString(for: state.date)
                return .run { send in
                    guard !Task.isCancelled else { return }
                    let token = await loadingClient.begin()
                    if !Task.isCancelled {
                        async let quote: Void = fetchDailyQuote(quoteDate: quoteDate, send: send)
                        async let completion: Void = fetchCompletionState(send: send)
                        _ = await (quote, completion)
                    }
                    await loadingClient.end(token)
                }

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

                return .runWithLoading { send in
                    do {
                        let response = try await homeUseCases.updateLike(
                            isLike,
                            quote,
                            quoteDate,
                            dayOfWeek
                        )
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

                return .runWithLoading { send in
                    do {
                        let response = try await homeUseCases.deleteUploadImage(dailyQuoteSeq)
                        await send(.imageDeleted(.success(response)))
                    } catch is CancellationError {
                        return
                    } catch let error as ErrorResponse {
                        guard !Task.isCancelled else { return }
                        await send(.imageDeleted(.failure(error)))
                    } catch {
                        guard !Task.isCancelled else { return }
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

                return .runWithLoading { send in
                    do {
                        let response = try await homeUseCases.postUploadImage(fileURL, dailyQuoteSeq)
                        await send(.imageUploaded(.success(response)))
                    } catch is CancellationError {
                        return
                    } catch let error as ErrorResponse {
                        guard !Task.isCancelled else { return }
                        await send(.imageUploaded(.failure(error)))
                    } catch {
                        guard !Task.isCancelled else { return }
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

            case let .completionStateLoaded(streakCount, streakInfos):
                state.streakCount = streakCount > 0 ? streakCount : nil
                state.isStreakStateLoaded = true
                if streakCount > 0 {
                    state.isStreakTooltipPresented = false
                }
                state.completedWritingDates = Set(
                    streakInfos
                        .filter(\.isDailyWritingCompleted)
                        .map(\.date)
                )
                return .none

            case .calendarTriggerTapped:
                state.isCalendarPresented.toggle()
                if state.isCalendarPresented {
                    state.calendarDisplayedMonth = FillsaCalendarDateSupport.startOfMonth(for: state.date)
                    state.isStreakTooltipPresented = false
                }
                return .none

            case .calendarDismissed:
                state.isCalendarPresented = false
                return .none

            case let .calendarMonthChanged(month):
                let targetMonth = FillsaCalendarDateSupport.startOfMonth(for: month)
                guard HomeCalendarMonthRange.isSelectable(targetMonth) else { return .none }
                state.calendarDisplayedMonth = targetMonth
                return .none

            case let .calendarDateSelected(date):
                let selectedDay = FillsaCalendarDateSupport.calendar.startOfDay(for: date)
                let today = FillsaCalendarDateSupport.calendar.startOfDay(for: Date())
                guard selectedDay >= FillsaCalendarDateSupport.startDay, selectedDay <= today else {
                    return .none
                }
                state.date = selectedDay
                state.calendarDisplayedMonth = FillsaCalendarDateSupport.startOfMonth(for: selectedDay)
                state.isCalendarPresented = false
                state.hasLoaded = false
                return load(state: &state)

            case .streakStatusTapped:
                guard state.isStreakStateLoaded, state.streakCount == nil else { return .none }
                state.isStreakTooltipPresented.toggle()
                if state.isStreakTooltipPresented {
                    state.isCalendarPresented = false
                }
                return .none

            case .streakTooltipDismissed:
                state.isStreakTooltipPresented = false
                return .none

            case let .answerDraftChanged(answer):
                state.answerDraft = HomeAnswerInput.limit(answer)
                return .none

            case .answerRecordTapped:
                let answer = HomeAnswerInput.limit(state.answerDraft)
                guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    return .none
                }
                state.answerDraft = answer
                state.recordedAnswer = answer
                state.isEditingAnswer = false
                state.toastMessage = "답변을 기록했어요."
                return .none

            case .answerEditTapped:
                state.answerDraft = state.recordedAnswer ?? state.answerDraft
                state.isEditingAnswer = true
                return .none
            }
        }
    }

    private func load(state: inout State) -> Effect<Action> {
        state.isLoading = true
        let quoteDate = FillsaCalendarDateSupport.quoteDateString(for: state.date)

        return .runWithLoading { send in
            await fetchDailyQuote(quoteDate: quoteDate, send: send)
        }
    }

    private func fetchDailyQuote(quoteDate: String, send: Send<Action>) async {
        do {
            let response = try await homeUseCases.loadDailyQuote(quoteDate)
            guard !Task.isCancelled else { return }
            await send(.dailyQuoteLoaded(.success(response)))
        } catch is CancellationError {
            return
        } catch let error as ErrorResponse {
            guard !Task.isCancelled else { return }
            await send(.dailyQuoteLoaded(.failure(error)))
        } catch {
            guard !Task.isCancelled else { return }
            await send(.dailyQuoteLoaded(.failure(.defaultError)))
        }
    }

    private func fetchCompletionState(send: Send<Action>) async {
        let streakCount = await streakClient.getCurrentCount()
        guard !Task.isCancelled else { return }
        let streakInfos = (try? await streakClient.getAllLocal()) ?? []
        guard !Task.isCancelled else { return }
        await send(.completionStateLoaded(streakCount, streakInfos))
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

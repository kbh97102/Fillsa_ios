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
        var serverToday: String?
        var weeklyWindows: [String: MemberWeeklyQuoteResponse] = [:]
        var feedRequestID: Int?
        var nextFeedRequestID = 0
    }

    enum Action: Equatable {
        case onAppear
        case beforeTapped
        case nextTapped
        case dailyQuoteLoaded(Result<HomeDailyQuoteResult, ErrorResponse>)
        case datedDailyQuoteLoaded(String, Result<HomeDailyQuoteResult, ErrorResponse>)
        case feedLoaded(Int, Result<HomeFeedResult, ErrorResponse>)
        case likeTapped(Bool)
        case likeUpdated(Result<Int, ErrorResponse>)
        case imageTapped
        case imageDialogDismissed
        case deleteImageTapped
        case deleteImageCancelled
        case deleteImageConfirmed
        case imageDeleted(Int, Result<Int, ErrorResponse>)
        case imagePicked(URL)
        case imageUploaded(Int, Result<MemberQuoteImageResponse, ErrorResponse>)
        case copyCompleted
        case toastDismissed
        case completionStateLoaded(Int)
        case calendarTriggerTapped
        case calendarDismissed
        case calendarMonthChanged(Date)
        case calendarDateSelected(Date)
        case streakStatusTapped
        case streakTooltipDismissed
        case answerDraftChanged(String)
        case answerRecordTapped
        case answerSaved(Int, Result<AnswerResponse, ErrorResponse>)
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
                state.nextFeedRequestID += 1
                let requestID = state.nextFeedRequestID
                state.feedRequestID = requestID
                return .run { send in
                    guard !Task.isCancelled else { return }
                    let token = await loadingClient.begin()
                    if !Task.isCancelled {
                        async let quote: Void = fetchFeed(endDate: nil, requestID: requestID, send: send)
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
                applyDailyResult(result, state: &state)
                return .none

            case .dailyQuoteLoaded(.failure):
                state.hasLoaded = true
                state.isLoading = false
                return .none

            case let .datedDailyQuoteLoaded(quoteDate, .success(result)):
                guard quoteDate == FillsaCalendarDateSupport.quoteDateString(for: state.date) else { return .none }
                applyDailyResult(result, state: &state)
                return .none

            case let .datedDailyQuoteLoaded(quoteDate, .failure):
                guard quoteDate == FillsaCalendarDateSupport.quoteDateString(for: state.date) else { return .none }
                state.hasLoaded = true
                state.isLoading = false
                return .none

            case let .feedLoaded(requestID, .success(result)):
                guard state.feedRequestID == requestID else { return .none }
                state.feedRequestID = nil
                switch result {
                case let .member(week):
                    state.isLoggedIn = true
                    if state.serverToday == nil { state.serverToday = week.endDate }
                    state.weeklyWindows[week.endDate] = week
                    state.completedWritingDates.formUnion(
                        week.days.filter { $0.completed == true || $0.state == "done" }.map(\.date)
                    )
                    let key = FillsaCalendarDateSupport.quoteDateString(for: state.date)
                    if let day = week.day(key) {
                        applyDailyResult(HomeDailyQuoteResult(quote: day.asDailyQuote, isLoggedIn: true), state: &state)
                        return .none
                    }
                    if let anchor = state.serverToday,
                       let neededEndDate = QuoteDateWindow.endDate(containing: key, anchor: anchor),
                       neededEndDate != week.endDate {
                        return load(state: &state)
                    }
                    state.isLoading = true
                    return .runWithLoading { send in
                        await fetchDailyQuote(quoteDate: key, send: send)
                    }
                }

            case let .feedLoaded(requestID, .failure):
                guard state.feedRequestID == requestID else { return .none }
                state.feedRequestID = nil
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
                    quoteDate: state.quote.quoteDate,
                    questionKo: state.quote.questionKo,
                    questionEn: state.quote.questionEn,
                    answer: state.quote.answer,
                    answeredAt: state.quote.answeredAt
                )
                updateCachedDay(state: &state) { $0.likeYn = isLike ? "Y" : "N" }

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
                state.isImageDialogPresented = true
                return .none

            case .imageDialogDismissed:
                state.isImageDialogPresented = false
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
                        await send(.imageDeleted(dailyQuoteSeq, .success(response)))
                    } catch is CancellationError {
                        return
                    } catch let error as ErrorResponse {
                        guard !Task.isCancelled else { return }
                        await send(.imageDeleted(dailyQuoteSeq, .failure(error)))
                    } catch {
                        guard !Task.isCancelled else { return }
                        await send(.imageDeleted(dailyQuoteSeq, .failure(.defaultError)))
                    }
                }

            case let .imageDeleted(dailyQuoteSeq, .success):
                updateCachedDay(state: &state, dailyQuoteSeq: dailyQuoteSeq) { $0.imagePath = "" }
                guard state.quote.dailyQuoteSeq == dailyQuoteSeq else { return .none }
                state.quote = state.quote.copy(imagePath: "")
                state.toastMessage = "이미지가 삭제되었습니다."
                return .none

            case .imageDeleted(_, .failure):
                state.toastMessage = "이미지 삭제에 실패했습니다."
                return .none

            case let .imagePicked(fileURL):
                guard state.quote.dailyQuoteSeq > 0 else {
                    try? FileManager.default.removeItem(at: fileURL)
                    return .none
                }
                let dailyQuoteSeq = state.quote.dailyQuoteSeq

                return .runWithLoading { send in
                    defer { try? FileManager.default.removeItem(at: fileURL) }
                    do {
                        let response = try await homeUseCases.postUploadImage(fileURL, dailyQuoteSeq)
                        await send(.imageUploaded(dailyQuoteSeq, .success(response)))
                    } catch is CancellationError {
                        return
                    } catch let error as ErrorResponse {
                        guard !Task.isCancelled else { return }
                        await send(.imageUploaded(dailyQuoteSeq, .failure(error)))
                    } catch {
                        guard !Task.isCancelled else { return }
                        await send(.imageUploaded(dailyQuoteSeq, .failure(.defaultError)))
                    }
                }

            case let .imageUploaded(dailyQuoteSeq, .success(response)):
                updateCachedDay(state: &state, dailyQuoteSeq: dailyQuoteSeq) { $0.imagePath = response.imagePath }
                guard state.quote.dailyQuoteSeq == dailyQuoteSeq else { return .none }
                state.quote = state.quote.copy(imagePath: response.imagePath)
                state.toastMessage = "이미지가 변경되었습니다."
                return .none

            case .imageUploaded(_, .failure):
                state.toastMessage = "이미지 변경에 실패했습니다."
                return .none

            case .copyCompleted:
                state.toastMessage = "복사되었습니다."
                return .none

            case .toastDismissed:
                state.toastMessage = nil
                return .none

            case let .completionStateLoaded(streakCount):
                state.streakCount = streakCount > 0 ? streakCount : nil
                state.isStreakStateLoaded = true
                if streakCount > 0 {
                    state.isStreakTooltipPresented = false
                }
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
                guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      state.quote.dailyQuoteSeq > 0 else { return .none }
                let dailyQuoteSeq = state.quote.dailyQuoteSeq
                return .runWithLoading { send in
                    do {
                        let response = try await homeUseCases.saveAnswer(answer, dailyQuoteSeq)
                        await send(.answerSaved(dailyQuoteSeq, .success(response)))
                    } catch is CancellationError {
                        return
                    } catch let error as ErrorResponse {
                        guard !Task.isCancelled else { return }
                        await send(.answerSaved(dailyQuoteSeq, .failure(error)))
                    } catch {
                        guard !Task.isCancelled else { return }
                        await send(.answerSaved(dailyQuoteSeq, .failure(.defaultError)))
                    }
                }

            case let .answerSaved(dailyQuoteSeq, .success(response)):
                updateCachedDay(state: &state, dailyQuoteSeq: dailyQuoteSeq) {
                    $0.answer = response.answer
                    $0.answeredAt = response.answeredAt
                }
                guard state.quote.dailyQuoteSeq == dailyQuoteSeq else { return .none }
                state.answerDraft = response.answer
                state.recordedAnswer = response.answer
                state.isEditingAnswer = false
                state.quote = state.quote.copy(answer: response.answer)
                state.toastMessage = "답변을 기록했어요."
                return .none

            case .answerSaved(_, .failure):
                return .none

            case .answerEditTapped:
                state.answerDraft = state.recordedAnswer ?? state.answerDraft
                state.isEditingAnswer = true
                return .none
            }
        }
    }

    private func load(state: inout State) -> Effect<Action> {
        let quoteDate = FillsaCalendarDateSupport.quoteDateString(for: state.date)
        if state.isLoggedIn,
           let day = state.weeklyWindows.values.compactMap({ $0.day(quoteDate) }).first {
            applyDailyResult(HomeDailyQuoteResult(quote: day.asDailyQuote, isLoggedIn: true), state: &state)
            return .none
        }
        if state.feedRequestID != nil {
            // The in-flight first week supplies the server's date anchor. Apply its
            // response to the latest selection before deciding if another week is needed.
            state.isLoading = true
            state.answerDraft = ""
            state.recordedAnswer = nil
            state.isEditingAnswer = true
            return .none
        }
        state.isLoading = true
        state.answerDraft = ""
        state.recordedAnswer = nil
        state.isEditingAnswer = true
        if state.isLoggedIn, let anchor = state.serverToday,
           let endDate = QuoteDateWindow.endDate(containing: quoteDate, anchor: anchor) {
            state.nextFeedRequestID += 1
            let requestID = state.nextFeedRequestID
            state.feedRequestID = requestID
            return .runWithLoading { send in
                await fetchFeed(endDate: endDate, requestID: requestID, send: send)
            }
        }
        return .runWithLoading { send in
            await fetchDailyQuote(quoteDate: quoteDate, send: send)
        }
    }

    private func applyDailyResult(_ result: HomeDailyQuoteResult, state: inout State) {
        state.quote = result.quote
        state.isLoggedIn = result.isLoggedIn
        if result.isLoggedIn {
            state.answerDraft = result.quote.answer ?? ""
            state.recordedAnswer = result.quote.answer
            state.isEditingAnswer = result.quote.answer == nil
        }
        state.hasLoaded = true
        state.isLoading = false
    }

    private func updateCachedDay(
        state: inout State,
        dailyQuoteSeq: Int? = nil,
        _ update: (inout MemberQuoteDay) -> Void
    ) {
        let key = FillsaCalendarDateSupport.quoteDateString(for: state.date)
        for (endDate, var week) in state.weeklyWindows {
            if let index = week.days.firstIndex(where: {
                if let dailyQuoteSeq { return $0.dailyQuoteSeq == dailyQuoteSeq }
                return $0.date == key
            }) {
                update(&week.days[index])
                state.weeklyWindows[endDate] = week
                return
            }
        }
    }

    private func fetchFeed(endDate: String?, requestID: Int, send: Send<Action>) async {
        do {
            let result = try await homeUseCases.loadFeed(endDate)
            guard !Task.isCancelled else { return }
            await send(.feedLoaded(requestID, .success(result)))
        } catch is CancellationError {
            return
        } catch let error as ErrorResponse {
            guard !Task.isCancelled else { return }
            await send(.feedLoaded(requestID, .failure(error)))
        } catch {
            guard !Task.isCancelled else { return }
            await send(.feedLoaded(requestID, .failure(.defaultError)))
        }
    }

    private func fetchDailyQuote(quoteDate: String, send: Send<Action>) async {
        do {
            let response = try await homeUseCases.loadDailyQuote(quoteDate)
            guard !Task.isCancelled else { return }
            await send(.datedDailyQuoteLoaded(quoteDate, .success(response)))
        } catch is CancellationError {
            return
        } catch let error as ErrorResponse {
            guard !Task.isCancelled else { return }
            await send(.datedDailyQuoteLoaded(quoteDate, .failure(error)))
        } catch {
            guard !Task.isCancelled else { return }
            await send(.datedDailyQuoteLoaded(quoteDate, .failure(.defaultError)))
        }
    }

    private func fetchCompletionState(send: Send<Action>) async {
        let streakCount = await streakClient.getCurrentCount()
        guard !Task.isCancelled else { return }
        await send(.completionStateLoaded(streakCount))
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
        imagePath: String? = nil,
        answer: String? = nil
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
            quoteDate: quoteDate,
            questionKo: questionKo,
            questionEn: questionEn,
            answer: answer ?? self.answer,
            answeredAt: answeredAt
        )
    }
}

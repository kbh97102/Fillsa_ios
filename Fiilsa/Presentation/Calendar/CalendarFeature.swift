import ComposableArchitecture
import Foundation

@Reducer
struct CalendarFeature {
    @ObservableState
    struct State: Equatable {
        var memberQuotes: [MemberQuotesData] = []
        var monthlySummary = MonthlySummaryData(typingCount: 0, likeCount: 0, streakCount: 0)
        var displayStreakCount: Int?
        var currentMonth = FillsaCalendarDateSupport.startOfMonth(for: Date())
        var selectedDay = Date()
        var hasLoaded = false
        var isLoading = false
        var isLoggedIn = false
        var answerDraft = ""
        var recordedAnswer: String?
        var isEditingAnswer = true
        var imageTargetSeq: Int?
        var isImageDialogPresented = false
        var isDeleteImageConfirmationPresented = false
        var imageUploadFailed = false

    }

    enum Action: Equatable {
        case onAppear
        case monthChanged(Date)
        case daySelected(Date)
        case bottomQuoteTapped
        case countTapped
        case likeTapped(Int, Bool)
        case likeUpdated(Int, Bool, Result<Int, ErrorResponse>)
        case imageTapped(Int)
        case imageAccessResolved(Int, Bool)
        case imageDialogDismissed
        case deleteImageTapped
        case deleteImageCancelled
        case deleteImageConfirmed
        case imageDeleted(Int, Result<Int, ErrorResponse>)
        case imagePicked(URL)
        case imagePreparationFailed
        case imageUploaded(Int, Result<MemberQuoteImageResponse, ErrorResponse>)
        case refresh
        case monthlyQuotesLoaded(Result<MemberMonthlyQuoteResponse, ErrorResponse>)
        case answerDraftChanged(String)
        case answerRecordTapped
        case answerSaved(Int, Result<AnswerResponse, ErrorResponse>)
        case answerEditTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case homeSelected(Date)
            case quoteListSelected(Date)
            case memberAccessLost
        }
    }

    @Dependency(\.calendarUseCases) private var calendarUseCases
    @Dependency(\.homeUseCases) private var homeUseCases
    @Dependency(\.sessionClient) private var sessionClient


    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.isLoading else { return .none }
                return load(state: &state)

            case let .monthChanged(month):
                state.currentMonth = month
                state.selectedDay = month
                state.hasLoaded = false
                state.answerDraft = ""
                state.recordedAnswer = nil
                state.isEditingAnswer = true
                state.imageTargetSeq = nil
                state.isImageDialogPresented = false

                return load(state: &state)

            case let .daySelected(day):
                state.selectedDay = day
                restoreAnswer(state: &state)
                return .none

            case .bottomQuoteTapped:
                return .send(.delegate(.homeSelected(state.selectedDay)))

            case .countTapped:
                return .send(.delegate(.quoteListSelected(state.selectedDay)))

            case let .likeTapped(dailyQuoteSeq, isLike):
                guard let record = selectedCompletedRecord(in: state), record.dailyQuoteSeq == dailyQuoteSeq else {
                    return .none
                }
                let quote = DailyQuote(
                    likeYn: record.likeYn,
                    imagePath: record.imagePath,
                    dailyQuoteSeq: record.dailyQuoteSeq,
                    korQuote: record.quote,
                    engQuote: record.engQuote,
                    korAuthor: record.author,
                    engAuthor: record.engAuthor,
                    authorUrl: record.authorUrl,
                    quoteDate: record.quoteDate
                )
                let dayOfWeek = dayOfWeekString(for: state.selectedDay)
                return .runWithLoading { send in
                    do {
                        let result = try await homeUseCases.updateLike(isLike, quote, record.quoteDate, dayOfWeek)
                        await send(.likeUpdated(dailyQuoteSeq, isLike, .success(result)))
                    } catch is CancellationError {
                        return
                    } catch let error as ErrorResponse {
                        await send(.likeUpdated(dailyQuoteSeq, isLike, .failure(error)))
                    } catch {
                        await send(.likeUpdated(dailyQuoteSeq, isLike, .failure(.defaultError)))
                    }
                }

            case let .likeUpdated(dailyQuoteSeq, isLike, .success):
                guard let index = state.memberQuotes.firstIndex(where: { $0.dailyQuoteSeq == dailyQuoteSeq }) else {
                    return .none
                }
                state.memberQuotes[index].likeYn = isLike ? "Y" : "N"
                state.monthlySummary = MonthlySummaryData(
                    typingCount: state.monthlySummary.typingCount,
                    likeCount: state.memberQuotes.count { $0.likeYn == "Y" },
                    streakCount: state.monthlySummary.streakCount
                )
                return .send(.refresh)

            case .likeUpdated(_, _, .failure):
                return .none

            case let .imageTapped(dailyQuoteSeq):
                guard let record = selectedCompletedRecord(in: state), record.dailyQuoteSeq == dailyQuoteSeq else {
                    return .none
                }
                return .run { send in
                    let isLoggedIn = (try? await sessionClient.isLoggedIn()) == true
                    await send(.imageAccessResolved(dailyQuoteSeq, isLoggedIn))
                }

            case let .imageAccessResolved(dailyQuoteSeq, isLoggedIn):
                guard let record = selectedCompletedRecord(in: state), record.dailyQuoteSeq == dailyQuoteSeq else {
                    return .none
                }
                if isLoggedIn {
                    state.imageTargetSeq = dailyQuoteSeq
                    state.isImageDialogPresented = true
                } else {
                    return .send(.delegate(.memberAccessLost))
                }
                return .none

            case .imageDialogDismissed:
                state.isImageDialogPresented = false
                state.imageTargetSeq = nil
                return .none

            case .deleteImageTapped:
                guard state.isImageDialogPresented, state.imageTargetSeq != nil else { return .none }
                state.isDeleteImageConfirmationPresented = true
                return .none

            case .deleteImageCancelled:
                state.isDeleteImageConfirmationPresented = false
                return .none

            case .deleteImageConfirmed:
                state.isDeleteImageConfirmationPresented = false
                guard let dailyQuoteSeq = state.imageTargetSeq else { return .none }
                return .runWithLoading { send in
                    do {
                        let result = try await homeUseCases.deleteUploadImage(dailyQuoteSeq)
                        await send(.imageDeleted(dailyQuoteSeq, .success(result)))
                    } catch is CancellationError {
                        return
                    } catch let error as ErrorResponse {
                        await send(.imageDeleted(dailyQuoteSeq, .failure(error)))
                    } catch {
                        await send(.imageDeleted(dailyQuoteSeq, .failure(.defaultError)))
                    }
                }

            case let .imageDeleted(dailyQuoteSeq, .success):
                guard let index = state.memberQuotes.firstIndex(where: { $0.dailyQuoteSeq == dailyQuoteSeq }) else {
                    return .none
                }
                state.memberQuotes[index].imagePath = nil
                return .send(.refresh)

            case .imageDeleted(_, .failure):
                return .none

            case let .imagePicked(fileURL):
                guard let dailyQuoteSeq = state.imageTargetSeq else {
                    try? FileManager.default.removeItem(at: fileURL)
                    return .none
                }
                state.imageUploadFailed = false
                return .runWithLoading { send in
                    defer { try? FileManager.default.removeItem(at: fileURL) }
                    do {
                        let response = try await homeUseCases.postUploadImage(fileURL, dailyQuoteSeq)
                        await send(.imageUploaded(dailyQuoteSeq, .success(response)))
                    } catch is CancellationError {
                        return
                    } catch let error as ErrorResponse {
                        await send(.imageUploaded(dailyQuoteSeq, .failure(error)))
                    } catch {
                        await send(.imageUploaded(dailyQuoteSeq, .failure(.defaultError)))
                    }
                }

            case .imagePreparationFailed:
                state.imageUploadFailed = true
                return .none

            case let .imageUploaded(dailyQuoteSeq, .success(response)):
                guard let index = state.memberQuotes.firstIndex(where: { $0.dailyQuoteSeq == dailyQuoteSeq }) else {
                    return .none
                }
                state.memberQuotes[index].imagePath = response.imagePath
                state.imageUploadFailed = false
                return .send(.refresh)

            case .imageUploaded(_, .failure):
                state.imageUploadFailed = true
                return .none

            case .refresh:
                return load(state: &state)

            case let .monthlyQuotesLoaded(.success(response)):
                state.memberQuotes = response.memberQuotes
                state.monthlySummary = response.monthlySummary
                state.displayStreakCount = response.monthlySummary.streakCount
                state.isLoggedIn = response.isLoggedIn
                state.hasLoaded = true
                state.isLoading = false
                restoreAnswer(state: &state)
                return .none

            case .monthlyQuotesLoaded(.failure):
                if state.hasLoaded {
                    state.isLoading = false
                    return .none
                }
                state.memberQuotes = []
                state.monthlySummary = MonthlySummaryData(typingCount: 0, likeCount: 0, streakCount: 0)
                state.displayStreakCount = nil
                state.answerDraft = ""
                state.recordedAnswer = nil
                state.isEditingAnswer = true
                state.hasLoaded = true
                state.isLoading = false
                return .none

            case let .answerDraftChanged(answer):
                state.answerDraft = HomeAnswerInput.limit(answer)
                return .none

            case .answerRecordTapped:
                let answer = HomeAnswerInput.limit(state.answerDraft)
                guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let record = selectedRecord(in: state),
                      CalendarWritingCompletion.isCompleted(record) else { return .none }
                let dailyQuoteSeq = record.dailyQuoteSeq
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
                guard let index = state.memberQuotes.firstIndex(where: { $0.dailyQuoteSeq == dailyQuoteSeq }) else { return .none }
                state.memberQuotes[index].answer = response.answer
                if selectedRecord(in: state)?.dailyQuoteSeq == dailyQuoteSeq {
                    state.answerDraft = response.answer
                    state.recordedAnswer = response.answer
                    state.isEditingAnswer = false
                }
                return .none

            case .answerSaved(_, .failure):
                return .none

            case .answerEditTapped:
                state.answerDraft = state.recordedAnswer ?? state.answerDraft
                state.isEditingAnswer = true
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private func selectedRecord(in state: State) -> MemberQuotesData? {
        let date = FillsaCalendarDateSupport.quoteDateString(for: state.selectedDay)
        return state.memberQuotes.first { $0.quoteDate == date }
    }

    private func restoreAnswer(state: inout State) {
        let answer = selectedRecord(in: state)?.answer
        state.recordedAnswer = answer
        state.answerDraft = answer ?? ""
        state.isEditingAnswer = answer == nil
    }

    private func load(state: inout State) -> Effect<Action> {
        state.isLoading = true
        let yearMonth = yearMonthString(for: state.currentMonth)

        return .runWithLoading { send in
            do {
                let response = try await calendarUseCases.loadMonth(yearMonth)
                guard !Task.isCancelled else { return }
                await send(.monthlyQuotesLoaded(.success(response)))
            } catch is CancellationError {
                return
            } catch let error as ErrorResponse {
                guard !Task.isCancelled else { return }
                await send(.monthlyQuotesLoaded(.failure(error)))
            } catch {
                guard !Task.isCancelled else { return }
                await send(.monthlyQuotesLoaded(.failure(.defaultError)))
            }
        }
    }

    private func yearMonthString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    private func selectedCompletedRecord(in state: State) -> MemberQuotesData? {
        let selectedDate = FillsaCalendarDateSupport.quoteDateString(for: state.selectedDay)
        guard let record = state.memberQuotes.first(where: { $0.quoteDate == selectedDate }),
              CalendarWritingCompletion.isCompleted(record) else { return nil }
        return record
    }

    private func dayOfWeekString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).uppercased()
    }
}

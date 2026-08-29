import ComposableArchitecture

@Reducer
struct HomeAnswerEditorFeature {
    @ObservableState
    struct State: Equatable {
        var dateKey = ""
        var question = ""
        var answer = ""
        var hasLoaded = false
        var isSaving = false
        var toastMessage: String?

        init(dateKey: String = "", question: String = "", initialAnswer: String = "") {
            self.dateKey = dateKey
            self.question = question
            self.answer = HomeAnswerInput.limit(initialAnswer)
        }
    }

    enum Action: Equatable {
        case onAppear
        case answerLoaded(Result<HomeAnswerRecord?, ErrorResponse>)
        case answerChanged(String)
        case saveTapped
        case answerSaved(Result<Bool, ErrorResponse>)
        case backTapped
        case toastDismissed
        case delegate(Delegate)

        enum Delegate: Equatable {
            case back
            case saved
        }
    }

    @Dependency(\.homeAnswerClient) private var homeAnswerClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard !state.hasLoaded else { return .none }
                state.hasLoaded = true
                let dateKey = state.dateKey
                let question = state.question

                return .run { send in
                    do {
                        let record = try await homeAnswerClient.get(dateKey, question)
                        await send(.answerLoaded(.success(record)))
                    } catch let error as ErrorResponse {
                        await send(.answerLoaded(.failure(error)))
                    } catch {
                        await send(.answerLoaded(.failure(.defaultError)))
                    }
                }

            case let .answerLoaded(.success(record)):
                if let record {
                    state.answer = HomeAnswerInput.limit(record.answer)
                }
                return .none

            case .answerLoaded(.failure):
                state.toastMessage = "저장된 답변을 불러오지 못했습니다."
                return .none

            case let .answerChanged(answer):
                state.answer = HomeAnswerInput.limit(answer)
                return .none

            case .saveTapped:
                guard !state.isSaving else { return .none }
                state.isSaving = true
                let record = HomeAnswerRecord(
                    dateKey: state.dateKey,
                    question: state.question,
                    answer: HomeAnswerInput.limit(state.answer)
                )

                return .run { send in
                    do {
                        try await homeAnswerClient.save(record)
                        await send(.answerSaved(.success(true)))
                    } catch let error as ErrorResponse {
                        await send(.answerSaved(.failure(error)))
                    } catch {
                        await send(.answerSaved(.failure(.defaultError)))
                    }
                }

            case .answerSaved(.success):
                state.isSaving = false
                return .send(.delegate(.saved))

            case .answerSaved(.failure):
                state.isSaving = false
                state.toastMessage = "답변 저장에 실패했습니다."
                return .none

            case .backTapped:
                return .send(.delegate(.back))

            case .toastDismissed:
                state.toastMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

import ComposableArchitecture
import Testing
@testable import Fiilsa

@Suite("HomeAnswerEditorFeature")
struct HomeAnswerEditorFeatureTests {
    @Test
    func editorLoadsThePersistedAnswerThenSavesTheCappedReplacement() async {
        let dateKey = "2026-08-29"
        let question = "오늘의 질문"
        let storedRecord = HomeAnswerRecord(
            dateKey: dateKey,
            question: question,
            answer: "이전에 저장한 답변"
        )
        let emoji = "👨🏽‍💻"
        let replacement = String(repeating: emoji, count: 201)
        let expectedRecord = HomeAnswerRecord(
            dateKey: dateKey,
            question: question,
            answer: String(repeating: emoji, count: 200)
        )
        let store = TestStore(
            initialState: HomeAnswerEditorFeature.State(
                dateKey: dateKey,
                question: question,
                initialAnswer: "홈 입력"
            )
        ) {
            HomeAnswerEditorFeature()
        } withDependencies: {
            $0.homeAnswerClient.get = { requestedDateKey, requestedQuestion in
                guard requestedDateKey == dateKey, requestedQuestion == question else {
                    throw HomeAnswerEditorTestError.unexpectedKey
                }
                return storedRecord
            }
            $0.homeAnswerClient.save = { record in
                guard record == expectedRecord else {
                    throw HomeAnswerEditorTestError.unexpectedRecord
                }
            }
        }

        await store.send(.onAppear) {
            $0.hasLoaded = true
        }
        await store.receive(.answerLoaded(.success(storedRecord))) {
            $0.answer = "이전에 저장한 답변"
        }
        await store.send(.answerChanged(replacement)) {
            $0.answer = expectedRecord.answer
        }
        await store.send(.saveTapped) {
            $0.isSaving = true
        }
        await store.receive(.answerSaved(.success(true))) {
            $0.isSaving = false
        }
        await store.receive(.delegate(.saved))
        await store.finish()
    }
}

private enum HomeAnswerEditorTestError: Error {
    case unexpectedKey
    case unexpectedRecord
}

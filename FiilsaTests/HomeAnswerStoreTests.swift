import Foundation
import Testing
@testable import Fiilsa

@Suite("HomeAnswerStore")
struct HomeAnswerStoreTests {
    @Test
    func answerRecordPersistsAndReloadsForItsDateAndQuestion() async throws {
        let databasePath = FileManager.default.temporaryDirectory
            .appendingPathComponent("home-answer-\(UUID().uuidString).sqlite")
            .path
        let store = try SQLiteLocalStore(path: databasePath)
        let record = HomeAnswerRecord(
            dateKey: "2026-08-29",
            question: "오늘의 질문",
            answer: "저장된 답변"
        )

        try await store.saveHomeAnswer(record)

        #expect(
            try await store.getHomeAnswer(
                dateKey: "2026-08-29",
                question: "오늘의 질문"
            ) == record
        )
        #expect(
            try await store.getHomeAnswer(
                dateKey: "2026-08-29",
                question: "다른 질문"
            ) == nil
        )
    }
}

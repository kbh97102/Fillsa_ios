final class DefaultHomeAnswerRepository: HomeAnswerRepository {
    private let localStore: SQLiteLocalStore

    init(localStore: SQLiteLocalStore? = nil) throws {
        if let localStore {
            self.localStore = localStore
        } else {
            self.localStore = try SQLiteLocalStore()
        }
    }

    func getAnswer(dateKey: String, question: String) async throws -> HomeAnswerRecord? {
        try await localStore.getHomeAnswer(dateKey: dateKey, question: question)
    }

    func saveAnswer(_ record: HomeAnswerRecord) async throws {
        try await localStore.saveHomeAnswer(record)
    }
}

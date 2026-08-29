protocol HomeAnswerRepository {
    func getAnswer(dateKey: String, question: String) async throws -> HomeAnswerRecord?
    func saveAnswer(_ record: HomeAnswerRecord) async throws
}

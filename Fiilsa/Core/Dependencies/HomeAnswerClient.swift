import ComposableArchitecture

struct HomeAnswerClient {
    var get: @Sendable (_ dateKey: String, _ question: String) async throws -> HomeAnswerRecord?
    var save: @Sendable (_ record: HomeAnswerRecord) async throws -> Void
}

extension HomeAnswerClient: DependencyKey {
    static let liveValue: HomeAnswerClient = {
        let repository = LiveRepositories.homeAnswer

        return HomeAnswerClient(
            get: { dateKey, question in
                try await repository.getAnswer(dateKey: dateKey, question: question)
            },
            save: { record in
                try await repository.saveAnswer(record)
            }
        )
    }()
}

extension DependencyValues {
    var homeAnswerClient: HomeAnswerClient {
        get { self[HomeAnswerClient.self] }
        set { self[HomeAnswerClient.self] = newValue }
    }
}

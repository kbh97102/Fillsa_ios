import ComposableArchitecture

struct TypingClient {
    var getTyping: @Sendable (_ dailyQuoteSeq: Int) async throws -> MemberTypingQuoteResponse
    var postTyping: @Sendable (_ dailyQuoteSeq: Int, _ request: TypingQuoteRequest) async throws -> Int
}

extension TypingClient: DependencyKey {
    static let liveValue: TypingClient = {
        let repository = LiveRepositories.typing

        return TypingClient(
            getTyping: { dailyQuoteSeq in
                try await repository.getTyping(dailyQuoteSeq: dailyQuoteSeq)
            },
            postTyping: { dailyQuoteSeq, request in
                try await repository.postTyping(dailyQuoteSeq: dailyQuoteSeq, request: request)
            }
        )
    }()
}

extension DependencyValues {
    var typingClient: TypingClient {
        get { self[TypingClient.self] }
        set { self[TypingClient.self] = newValue }
    }
}

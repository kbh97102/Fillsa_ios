struct AddLocalQuoteUseCase {
    let localRepository: LocalRepository

    func callAsFunction(_ quote: LocalQuoteInfo) async throws {
        try await localRepository.addLocalQuote(quote)
    }
}

struct ClearLocalDataUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws {
        try await localRepository.clear()
    }
}

struct DeleteLocalQuoteUseCase {
    let localRepository: LocalRepository

    func callAsFunction(_ quote: LocalQuoteInfo) async throws {
        try await localRepository.deleteQuote(quote)
    }

    func callAsFunction(seq: Int) async throws {
        try await localRepository.deleteQuote(seq: seq)
    }
}

struct FindLocalQuoteByIdUseCase {
    let localRepository: LocalRepository

    func callAsFunction(seq: Int) async throws -> LocalQuoteInfo? {
        try await localRepository.findLocalQuoteById(seq: seq)
    }
}

struct GetLocalQuoteListUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> [LocalQuoteInfo] {
        try await localRepository.getLocalQuotes()
    }
}

struct GetLocalQuotePagingUseCase {
    let localRepository: LocalRepository

    func callAsFunction(
        likeYN: YN,
        startDate: String,
        endDate: String,
        offset: Int,
        limit: Int = 10
    ) async throws -> [LocalQuoteInfo] {
        try await localRepository.getLocalQuotes(
            likeYN: likeYN,
            startDate: startDate,
            endDate: endDate,
            offset: offset,
            limit: limit
        )
    }
}

struct GetLocalQuoteUseCase {
    let localRepository: LocalRepository

    func callAsFunction(seq: Int) async throws -> LocalQuoteInfo? {
        try await localRepository.getQuoteLocal(seq: seq)
    }
}

struct UpdateLocalQuoteLikeUseCase {
    let localRepository: LocalRepository

    func callAsFunction(likeYN: YN, seq: Int) async throws -> Int {
        try await localRepository.updateLocalQuoteLike(likeYN, seq: seq)
    }
}

struct UpdateLocalQuoteMemoUseCase {
    let localRepository: LocalRepository

    func callAsFunction(memo: String, seq: Int) async throws {
        try await localRepository.updateLocalQuoteMemo(memo, seq: seq)
    }
}

struct UpdateLocalQuoteUseCase {
    let localRepository: LocalRepository

    func callAsFunction(_ quote: LocalQuoteInfo) async throws {
        try await localRepository.updateQuote(quote)
    }
}

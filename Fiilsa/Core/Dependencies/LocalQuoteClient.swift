import ComposableArchitecture

struct LocalQuoteClient {
    var getList: @Sendable () async throws -> [LocalQuoteInfo]
    var getPage: @Sendable (_ likeYN: YN, _ startDate: String, _ endDate: String, _ offset: Int, _ limit: Int) async throws -> [LocalQuoteInfo]
    var get: @Sendable (_ seq: Int) async throws -> LocalQuoteInfo?
    var findById: @Sendable (_ seq: Int) async throws -> LocalQuoteInfo?
    var add: @Sendable (_ quote: LocalQuoteInfo) async throws -> Void
    var update: @Sendable (_ quote: LocalQuoteInfo) async throws -> Void
    var updateLike: @Sendable (_ likeYN: YN, _ seq: Int) async throws -> Int
    var updateMemo: @Sendable (_ memo: String, _ seq: Int) async throws -> Void
    var delete: @Sendable (_ quote: LocalQuoteInfo) async throws -> Void
    var deleteBySeq: @Sendable (_ seq: Int) async throws -> Void
    var clear: @Sendable () async throws -> Void
}

extension LocalQuoteClient: DependencyKey {
    static let liveValue: LocalQuoteClient = {
        let repository = LiveRepositories.local

        return LocalQuoteClient(
            getList: {
                try await GetLocalQuoteListUseCase(localRepository: repository)()
            },
            getPage: { likeYN, startDate, endDate, offset, limit in
                try await GetLocalQuotePagingUseCase(localRepository: repository)(
                    likeYN: likeYN,
                    startDate: startDate,
                    endDate: endDate,
                    offset: offset,
                    limit: limit
                )
            },
            get: { seq in
                try await GetLocalQuoteUseCase(localRepository: repository)(seq: seq)
            },
            findById: { seq in
                try await FindLocalQuoteByIdUseCase(localRepository: repository)(seq: seq)
            },
            add: { quote in
                try await AddLocalQuoteUseCase(localRepository: repository)(quote)
            },
            update: { quote in
                try await UpdateLocalQuoteUseCase(localRepository: repository)(quote)
            },
            updateLike: { likeYN, seq in
                try await UpdateLocalQuoteLikeUseCase(localRepository: repository)(likeYN: likeYN, seq: seq)
            },
            updateMemo: { memo, seq in
                try await UpdateLocalQuoteMemoUseCase(localRepository: repository)(memo: memo, seq: seq)
            },
            delete: { quote in
                try await DeleteLocalQuoteUseCase(localRepository: repository)(quote)
            },
            deleteBySeq: { seq in
                try await DeleteLocalQuoteUseCase(localRepository: repository)(seq: seq)
            },
            clear: {
                try await ClearLocalDataUseCase(localRepository: repository)()
            }
        )
    }()
}

extension DependencyValues {
    var localQuoteClient: LocalQuoteClient {
        get { self[LocalQuoteClient.self] }
        set { self[LocalQuoteClient.self] = newValue }
    }
}

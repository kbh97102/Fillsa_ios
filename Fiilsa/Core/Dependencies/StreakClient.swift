import ComposableArchitecture

struct StreakClient {
    var checkYesterday: @Sendable () async throws -> Void
    var insertToday: @Sendable () async throws -> Void
    var getYesterday: @Sendable () async throws -> StreakInfo?
    var getTodayLocal: @Sendable () async throws -> StreakInfo?
    var getAllLocal: @Sendable () async throws -> [StreakInfo]
    var getLocalCount: @Sendable () async throws -> Int
    var getMemberStreaks: @Sendable () async -> MemberStreakResponse?
    var getCurrentCount: @Sendable () async -> Int
}

extension StreakClient: DependencyKey {
    static let liveValue: StreakClient = {
        let localRepository = LiveRepositories.local
        let commonRepository = LiveRepositories.common

        return StreakClient(
            checkYesterday: {
                try await CheckYesterdayStreakUseCase(localRepository: localRepository)()
            },
            insertToday: {
                try await InsertStreakInfoUseCase(localRepository: localRepository)()
            },
            getYesterday: {
                try await GetYesterdayStreakInfoUseCase(localRepository: localRepository)()
            },
            getTodayLocal: {
                try await GetTodayLocalStreakInfoUseCase(localRepository: localRepository)()
            },
            getAllLocal: {
                try await GetAllStreakInfoUseCase(localRepository: localRepository)()
            },
            getLocalCount: {
                try await GetLocalStreakDateCountUseCase(localRepository: localRepository)()
            },
            getMemberStreaks: {
                await GetMemberStreaksUseCase(
                    commonRepository: commonRepository,
                    localRepository: localRepository
                )()
            },
            getCurrentCount: {
                await GetStreakCountUseCase(
                    commonRepository: commonRepository,
                    localRepository: localRepository
                )()
            }
        )
    }()
}

extension DependencyValues {
    var streakClient: StreakClient {
        get { self[StreakClient.self] }
        set { self[StreakClient.self] = newValue }
    }
}

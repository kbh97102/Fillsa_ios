import ComposableArchitecture

struct StreakClient {
    var getMemberStreaks: @Sendable () async -> MemberStreakResponse?
    var getCurrentCount: @Sendable () async -> Int
}

extension StreakClient: DependencyKey {
    static let liveValue: StreakClient = {
        let commonRepository = LiveRepositories.common

        return StreakClient(
            getMemberStreaks: {
                await GetMemberStreaksUseCase(commonRepository: commonRepository)()
            },
            getCurrentCount: {
                await GetStreakCountUseCase(commonRepository: commonRepository)()
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

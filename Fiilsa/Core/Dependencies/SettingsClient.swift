import ComposableArchitecture

struct SettingsClient {
    var getAlarm: @Sendable () async throws -> Bool
    var setAlarm: @Sendable (_ value: Bool) async throws -> Void
    var isAlarmPermissionRequestedBefore: @Sendable () async throws -> Bool
    var setAlarmPermissionRequestedBefore: @Sendable (_ requested: Bool) async throws -> Void
    var getDarkModeType: @Sendable () async throws -> DarkModeType
    var setDarkModeType: @Sendable (_ darkModeType: DarkModeType) async throws -> Void
    var getUserName: @Sendable () async throws -> String
    var setUserName: @Sendable (_ name: String) async throws -> Void
    var getTokenExpired: @Sendable () async throws -> String
    var emitTokenExpired: @Sendable (_ errorCode: String) async throws -> Void
}

extension SettingsClient: DependencyKey {
    static let liveValue: SettingsClient = {
        let repository = LiveRepositories.local

        return SettingsClient(
            getAlarm: {
                try await GetAlarmUsageUseCase(localRepository: repository)()
            },
            setAlarm: { value in
                try await SetAlarmUsageUseCase(localRepository: repository)(value)
            },
            isAlarmPermissionRequestedBefore: {
                try await GetAlarmPermissionRequestedBeforeUseCase(localRepository: repository)()
            },
            setAlarmPermissionRequestedBefore: { requested in
                try await SetAlarmPermissionRequestedBeforeUseCase(localRepository: repository)(requested)
            },
            getDarkModeType: {
                try await GetDarkModeTypeUseCase(localRepository: repository)()
            },
            setDarkModeType: { darkModeType in
                try await SetDarkModeTypeUseCase(localRepository: repository)(darkModeType)
            },
            getUserName: {
                try await GetUserNameUseCase(localRepository: repository)()
            },
            setUserName: { name in
                try await SetUserNameUseCase(localRepository: repository)(name)
            },
            getTokenExpired: {
                try await GetTokenExpiredUseCase(localRepository: repository)()
            },
            emitTokenExpired: { errorCode in
                try await EmitTokenExpiredUseCase(localRepository: repository)(errorCode)
            }
        )
    }()
}

extension DependencyValues {
    var settingsClient: SettingsClient {
        get { self[SettingsClient.self] }
        set { self[SettingsClient.self] = newValue }
    }
}

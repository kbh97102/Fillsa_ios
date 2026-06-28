struct EmitTokenExpiredUseCase {
    let localRepository: LocalRepository

    func callAsFunction(_ errorCode: String) async throws {
        try await localRepository.emitTokenExpired(errorCode)
    }
}

struct GetAlarmPermissionRequestedBeforeUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> Bool {
        try await localRepository.isAlarmPermissionRequestedBefore()
    }
}

struct GetAlarmUsageUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> Bool {
        try await localRepository.getAlarm()
    }
}

struct GetDarkModeTypeUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> DarkModeType {
        try await localRepository.getDarkModeType()
    }
}

struct GetTokenExpiredUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> String {
        try await localRepository.getTokenExpired()
    }
}

struct GetUserNameUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> String {
        try await localRepository.getName()
    }
}

struct GetImageURIUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> String {
        try await localRepository.getImageURI()
    }
}

struct SetAlarmPermissionRequestedBeforeUseCase {
    let localRepository: LocalRepository

    func callAsFunction(_ requested: Bool) async throws {
        try await localRepository.setAlarmPermissionRequestedBefore(requested)
    }
}

struct SetAlarmUsageUseCase {
    let localRepository: LocalRepository

    func callAsFunction(_ value: Bool) async throws {
        try await localRepository.setAlarm(value)
    }
}

struct SetDarkModeTypeUseCase {
    let localRepository: LocalRepository

    func callAsFunction(_ darkModeType: DarkModeType) async throws {
        try await localRepository.setDarkModeType(darkModeType)
    }
}

struct SetUserNameUseCase {
    let localRepository: LocalRepository

    func callAsFunction(_ name: String) async throws {
        try await localRepository.setName(name)
    }
}

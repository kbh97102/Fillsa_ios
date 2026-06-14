struct CheckYesterdayStreakUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws {
        try await localRepository.checkYesterdayStreak()
    }
}

struct GetAllStreakInfoUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> [StreakInfo] {
        try await localRepository.getAllStreakInfos()
    }
}

struct GetLocalStreakDateCountUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> Int {
        try await localRepository.getStreakDateCount()
    }
}

struct GetTodayLocalStreakInfoUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> StreakInfo? {
        try await localRepository.getTodayLocalStreakInfo()
    }
}

struct GetYesterdayStreakInfoUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws -> StreakInfo? {
        try await localRepository.getYesterdayStreakInfo()
    }
}

struct InsertStreakInfoUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws {
        try await localRepository.setTodayStreakInfo()
    }
}

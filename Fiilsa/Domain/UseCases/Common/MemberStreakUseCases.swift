struct GetMemberStreaksUseCase {
    let commonRepository: CommonRepository
    let localRepository: LocalRepository

    func callAsFunction() async -> MemberStreakResponse? {
        do {
            if try await localRepository.isLoggedIn() {
                return try await commonRepository.getMemberStreaks()
            }

            guard let local = try await localRepository.getTodayLocalStreakInfo() else {
                return nil
            }
            return MemberStreakResponse(
                currentStreak: local.streakDateCount,
                isTodayWritten: local.isDailyWritingCompleted
            )
        } catch {
            return nil
        }
    }
}

struct GetStreakCountUseCase {
    let commonRepository: CommonRepository
    let localRepository: LocalRepository

    func callAsFunction() async -> Int {
        do {
            if try await localRepository.isLoggedIn() {
                return try await commonRepository.getMemberStreaks().currentStreak
            }
            return try await localRepository.getStreakDateCount()
        } catch {
            return 0
        }
    }
}

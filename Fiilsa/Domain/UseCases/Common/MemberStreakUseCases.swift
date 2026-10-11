struct GetMemberStreaksUseCase {
    let commonRepository: CommonRepository

    func callAsFunction() async -> MemberStreakResponse? {
        try? await commonRepository.getMemberStreaks()
    }
}

struct GetStreakCountUseCase {
    let commonRepository: CommonRepository

    func callAsFunction() async -> Int {
        (try? await commonRepository.getMemberStreaks().currentStreak) ?? 0
    }
}

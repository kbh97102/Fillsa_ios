struct StreakInfo: Codable, Equatable, Identifiable {
    var id: String { date }

    let date: String
    let streakDateCount: Int
    let isDailyWritingCompleted: Bool
}

struct MemberMonthlyQuoteResponse: Codable, Equatable {
    let memberQuotes: [MemberQuotesData]
    let monthlySummary: MonthlySummaryData
}

struct MemberQuotesData: Codable, Equatable, Identifiable {
    var id: Int { dailyQuoteSeq }

    let dailyQuoteSeq: Int
    let quoteDate: String
    let quote: String
    let author: String
    let completed: Bool
    let likeYn: String
    let todayCompleted: Bool
}

struct MonthlySummaryData: Codable, Equatable {
    let typingCount: Int
    let likeCount: Int
    let streakCount: Int
}

struct MonthlyQuoteResponse: Codable, Equatable, Identifiable {
    var id: Int { dailyQuoteSeq }

    let dailyQuoteSeq: Int
    let quoteDate: String
    let quote: String
    let author: String
}


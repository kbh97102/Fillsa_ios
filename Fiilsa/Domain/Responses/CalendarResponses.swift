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
    var likeYn: String
    let todayCompleted: Bool
    var engQuote: String? = nil
    var engAuthor: String? = nil
    var authorUrl: String? = nil
    var questionKo: String? = nil
    var questionEn: String? = nil
    var answer: String? = nil
    var answeredAt: String? = nil
    var imagePath: String? = nil
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

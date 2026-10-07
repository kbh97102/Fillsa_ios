struct MemberMonthlyQuoteResponse: Codable, Equatable {
    let memberQuotes: [MemberQuotesData]
    let monthlySummary: MonthlySummaryData
    let isLoggedIn: Bool

    init(memberQuotes: [MemberQuotesData], monthlySummary: MonthlySummaryData, isLoggedIn: Bool = true) {
        self.memberQuotes = memberQuotes
        self.monthlySummary = monthlySummary
        self.isLoggedIn = isLoggedIn
    }

    private enum CodingKeys: String, CodingKey { case memberQuotes, monthlySummary }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        memberQuotes = try container.decode([MemberQuotesData].self, forKey: .memberQuotes)
        monthlySummary = try container.decode(MonthlySummaryData.self, forKey: .monthlySummary)
        isLoggedIn = true // Only the member endpoint decodes this response.
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(memberQuotes, forKey: .memberQuotes)
        try container.encode(monthlySummary, forKey: .monthlySummary)
    }
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

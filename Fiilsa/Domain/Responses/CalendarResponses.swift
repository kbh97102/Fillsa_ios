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
    let likeYn: String
    let todayCompleted: Bool
    let questionKo: String?
    var answer: String?

    init(dailyQuoteSeq: Int, quoteDate: String, quote: String, author: String, completed: Bool,
         likeYn: String, todayCompleted: Bool, questionKo: String? = nil, answer: String? = nil) {
        self.dailyQuoteSeq = dailyQuoteSeq
        self.quoteDate = quoteDate
        self.quote = quote
        self.author = author
        self.completed = completed
        self.likeYn = likeYn
        self.todayCompleted = todayCompleted
        self.questionKo = questionKo
        self.answer = answer
    }
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

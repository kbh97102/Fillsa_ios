struct DailyQuote: Codable, Equatable {
    let likeYn: String
    let imagePath: String?
    let dailyQuoteSeq: Int
    let korQuote: String?
    let engQuote: String?
    let korAuthor: String?
    let engAuthor: String?
    let authorUrl: String?
    var quoteDate: String
    let questionKo: String?
    let questionEn: String?
    let answer: String?
    let answeredAt: String?

    private enum CodingKeys: String, CodingKey {
        case likeYn
        case imagePath
        case dailyQuoteSeq
        case korQuote
        case engQuote
        case korAuthor
        case engAuthor
        case authorUrl
        case quoteDate
        case date
        case questionKo
        case questionEn
        case answer
        case answeredAt
    }

    init(
        likeYn: String = "",
        imagePath: String? = "",
        dailyQuoteSeq: Int = 0,
        korQuote: String? = "",
        engQuote: String? = "",
        korAuthor: String? = "",
        engAuthor: String? = "",
        authorUrl: String? = "",
        quoteDate: String = "",
        questionKo: String? = nil,
        questionEn: String? = nil,
        answer: String? = nil,
        answeredAt: String? = nil
    ) {
        self.likeYn = likeYn
        self.imagePath = imagePath
        self.dailyQuoteSeq = dailyQuoteSeq
        self.korQuote = korQuote
        self.engQuote = engQuote
        self.korAuthor = korAuthor
        self.engAuthor = engAuthor
        self.authorUrl = authorUrl
        self.quoteDate = quoteDate
        self.questionKo = questionKo
        self.questionEn = questionEn
        self.answer = answer
        self.answeredAt = answeredAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        likeYn = try container.decodeIfPresent(String.self, forKey: .likeYn) ?? "N"
        imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        dailyQuoteSeq = try container.decodeIfPresent(Int.self, forKey: .dailyQuoteSeq) ?? 0
        korQuote = try container.decodeIfPresent(String.self, forKey: .korQuote)
        engQuote = try container.decodeIfPresent(String.self, forKey: .engQuote)
        korAuthor = try container.decodeIfPresent(String.self, forKey: .korAuthor)
        engAuthor = try container.decodeIfPresent(String.self, forKey: .engAuthor)
        authorUrl = try container.decodeIfPresent(String.self, forKey: .authorUrl)
        quoteDate = try container.decodeIfPresent(String.self, forKey: .quoteDate)
            ?? container.decodeIfPresent(String.self, forKey: .date)
            ?? ""
        questionKo = try container.decodeIfPresent(String.self, forKey: .questionKo)
        questionEn = try container.decodeIfPresent(String.self, forKey: .questionEn)
        answer = try container.decodeIfPresent(String.self, forKey: .answer)
        answeredAt = try container.decodeIfPresent(String.self, forKey: .answeredAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(likeYn, forKey: .likeYn)
        try container.encodeIfPresent(imagePath, forKey: .imagePath)
        try container.encode(dailyQuoteSeq, forKey: .dailyQuoteSeq)
        try container.encodeIfPresent(korQuote, forKey: .korQuote)
        try container.encodeIfPresent(engQuote, forKey: .engQuote)
        try container.encodeIfPresent(korAuthor, forKey: .korAuthor)
        try container.encodeIfPresent(engAuthor, forKey: .engAuthor)
        try container.encodeIfPresent(authorUrl, forKey: .authorUrl)
        try container.encode(quoteDate, forKey: .quoteDate)
        try container.encodeIfPresent(questionKo, forKey: .questionKo)
        try container.encodeIfPresent(questionEn, forKey: .questionEn)
        try container.encodeIfPresent(answer, forKey: .answer)
        try container.encodeIfPresent(answeredAt, forKey: .answeredAt)
    }
}

struct MemberTypingQuoteResponse: Codable, Equatable {
    let korQuote: String?
    let engQuote: String?
    let typingKorQuote: String?
    let typingEngQuote: String?
    let likeYn: String
}

struct MemberQuoteImageResponse: Codable, Equatable {
    let memberQuoteSeq: Int
    let imagePath: String
}

struct AnswerResponse: Codable, Equatable {
    let memberQuoteSeq: Int
    let answer: String
    let answeredAt: String
}

struct MemberQuotesResponse: Codable, Equatable, Identifiable {
    var id: Int { memberQuoteSeq }

    let memberQuoteSeq: Int
    let quoteDate: String
    let quoteDayOfWeek: String
    let korQuote: String?
    let engQuote: String?
    let korAuthor: String?
    let engAuthor: String?
    let authorUrl: String
    let memo: String?
    let memoYn: String
    let likeYn: String
    let imagePath: String?
}

struct PageResponseMemberQuotesResponse: Codable, Equatable {
    let content: [MemberQuotesResponse]
    let totalElements: Int
    let totalPages: Int
    let currentPage: Int
}

struct SimpleIntResponse: Codable, Equatable {
    let value: Int
}

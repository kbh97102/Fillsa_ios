struct DailyQuoteNoToken: Codable, Equatable {
    let dailyQuoteSeq: Int
    let korQuote: String?
    let engQuote: String?
    let korAuthor: String?
    let engAuthor: String?
    let authorUrl: String?
}

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

    init(
        likeYn: String = "",
        imagePath: String? = "",
        dailyQuoteSeq: Int = 0,
        korQuote: String? = "",
        engQuote: String? = "",
        korAuthor: String? = "",
        engAuthor: String? = "",
        authorUrl: String? = "",
        quoteDate: String = ""
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


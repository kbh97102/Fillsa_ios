struct TypingQuoteRequest: Codable, Equatable {
    let typingKorQuote: String
    let typingEngQuote: String
}

struct LikeRequest: Codable, Equatable {
    let likeYn: String
}

struct MemoRequest: Codable, Equatable {
    let memo: String
}

struct LocalQuoteInfo: Codable, Equatable, Identifiable {
    var id: Int { dailyQuoteSeq }

    let dailyQuoteSeq: Int
    let korQuote: String
    let engQuote: String
    let korAuthor: String
    let engAuthor: String
    let korTyping: String
    let engTyping: String
    let likeYn: String
    let memo: String
    let date: String
    let dayOfWeek: String
}


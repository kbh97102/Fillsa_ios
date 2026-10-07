import Foundation

struct MemberQuoteDay: Codable, Equatable, Identifiable {
    var id: String { date }

    let date: String
    let dayOfWeek: String
    let state: String
    let dailyQuoteSeq: Int?
    let korQuote: String?
    let engQuote: String?
    let korAuthor: String?
    let engAuthor: String?
    let authorUrl: String?
    let questionKo: String?
    let questionEn: String?
    var answer: String?
    var answeredAt: String?
    var likeYn: String?
    var imagePath: String?
    let completed: Bool?

    var asDailyQuote: DailyQuote {
        DailyQuote(
            likeYn: likeYn ?? "N",
            imagePath: imagePath,
            dailyQuoteSeq: dailyQuoteSeq ?? 0,
            korQuote: korQuote,
            engQuote: engQuote,
            korAuthor: korAuthor,
            engAuthor: engAuthor,
            authorUrl: authorUrl,
            quoteDate: date,
            questionKo: questionKo,
            questionEn: questionEn,
            answer: answer,
            answeredAt: answeredAt
        )
    }
}

struct MemberWeeklyQuoteResponse: Codable, Equatable {
    let startDate: String
    let endDate: String
    var days: [MemberQuoteDay]

    func day(_ date: String) -> MemberQuoteDay? {
        days.first { $0.date == date }
    }
}

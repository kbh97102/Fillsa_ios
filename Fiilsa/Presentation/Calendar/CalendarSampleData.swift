import Foundation

enum CalendarSampleData {
    static let memberQuotes: [MemberQuotesData] = [
        MemberQuotesData(
            dailyQuoteSeq: 1,
            quoteDate: FillsaCalendarDateSupport.quoteDateString(for: Date()),
            quote: "상황을 가장 잘 활용하는 사람이 가장 좋은 상황을 맞는다.",
            author: "John Wooden",
            completed: true,
            likeYn: "Y",
            todayCompleted: true
        )
    ]

    static let monthlySummary = MonthlySummaryData(
        typingCount: 1,
        likeCount: 1,
        streakCount: 1
    )
}

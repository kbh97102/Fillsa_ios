enum APIEndpoint {
    static let login = "/api/v1/auth/login"
    static let dailyQuote = "/api/v2/member-quotes/daily"
    static let memberWeeklyQuotes = "/api/v2/member-quotes/weekly"
    static let quoteList = "/api/v2/member-quotes"
    static let memberMonthlyQuotes = "/api/v2/member-quotes/monthly"
    static let notice = "/api/v1/notices"
    static let resign = "/api/v1/auth/withdraw"
    static let refreshToken = "/api/v1/auth/refresh"
    static let memberStreaks = "/api/v1/member-streaks"
    static let popupGeneral = "/api/v1/popups/general"
    static let versionUpdate = "/api/v1/popups/version-update"
    static let pushDevice = "/api/v1/member-devices/push"

    static func like(dailyQuoteSeq: Int) -> String {
        "/api/v1/member-quotes/\(dailyQuoteSeq)/like"
    }

    static func answer(dailyQuoteSeq: Int) -> String {
        "/api/v2/member-quotes/\(dailyQuoteSeq)/answer"
    }

    static func uploadImage(dailyQuoteSeq: Int) -> String {
        "/api/v1/member-quotes/\(dailyQuoteSeq)/images"
    }

    static func saveMemo(memberQuoteSeq: String) -> String {
        "/api/v1/member-quotes/\(memberQuoteSeq)/memo"
    }

    static func typing(dailyQuoteSeq: Int) -> String {
        "/api/v1/member-quotes/\(dailyQuoteSeq)/typing"
    }
}

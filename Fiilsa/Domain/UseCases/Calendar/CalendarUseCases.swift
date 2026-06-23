import Foundation

struct LoadCalendarMonthUseCase {
    let calendarRepository: CalendarRepository
    let localRepository: LocalRepository

    func callAsFunction(yearMonth: String) async throws -> MemberMonthlyQuoteResponse {
        let isLoggedIn = try await GetLoginStatusUseCase(localRepository: localRepository)()

        if isLoggedIn {
            return try await GetQuotesMonthlyUseCase(calendarRepository: calendarRepository)(
                yearMonth: yearMonth
            )
        }

        let localQuotes = try await GetLocalQuoteListUseCase(localRepository: localRepository)()
        let localStreak = try await GetTodayLocalStreakInfoUseCase(localRepository: localRepository)()
        let monthlyQuotes = try await GetMonthlyQuotesNonMemberUseCase(calendarRepository: calendarRepository)(
            yearMonth: yearMonth
        )

        let memberQuotes = monthlyQuotes.map { quote in
            let localQuote = localQuotes.first { $0.dailyQuoteSeq == quote.dailyQuoteSeq }
            let completed = localQuote?.korTyping.isEmpty == false || localQuote?.engTyping.isEmpty == false

            return MemberQuotesData(
                dailyQuoteSeq: quote.dailyQuoteSeq,
                quoteDate: quote.quoteDate,
                quote: quote.quote,
                author: quote.author,
                completed: completed,
                likeYn: localQuote?.likeYn ?? "N",
                todayCompleted: completed
            )
        }

        return MemberMonthlyQuoteResponse(
            memberQuotes: memberQuotes,
            monthlySummary: MonthlySummaryData(
                typingCount: memberQuotes.count { $0.completed },
                likeCount: memberQuotes.count { $0.likeYn == "Y" },
                streakCount: localStreak?.streakDateCount ?? 0
            )
        )
    }
}

struct GetQuotesMonthlyUseCase {
    let calendarRepository: CalendarRepository

    func callAsFunction(yearMonth: String) async throws -> MemberMonthlyQuoteResponse {
        try await calendarRepository.getQuotesMonthly(yearMonth: yearMonth)
    }
}

struct GetMonthlyQuotesNonMemberUseCase {
    let calendarRepository: CalendarRepository

    func callAsFunction(yearMonth: String) async throws -> [MonthlyQuoteResponse] {
        try await calendarRepository.getQuotesMonthlyNonMember(yearMonth: yearMonth)
    }
}

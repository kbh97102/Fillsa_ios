protocol CalendarRepository {
    func getQuotesMonthly(yearMonth: String) async throws -> MemberMonthlyQuoteResponse
    func getQuotesMonthlyNonMember(yearMonth: String) async throws -> [MonthlyQuoteResponse]
}


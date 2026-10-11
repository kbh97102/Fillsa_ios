protocol CalendarRepository {
    func getQuotesMonthly(yearMonth: String) async throws -> MemberMonthlyQuoteResponse
}

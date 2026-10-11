import Foundation

struct LoadCalendarMonthUseCase {
    let calendarRepository: CalendarRepository

    func callAsFunction(yearMonth: String) async throws -> MemberMonthlyQuoteResponse {
        try await GetQuotesMonthlyUseCase(calendarRepository: calendarRepository)(
            yearMonth: yearMonth
        )
    }
}

struct GetQuotesMonthlyUseCase {
    let calendarRepository: CalendarRepository

    func callAsFunction(yearMonth: String) async throws -> MemberMonthlyQuoteResponse {
        try await calendarRepository.getQuotesMonthly(yearMonth: yearMonth)
    }
}

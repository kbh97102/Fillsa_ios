import ComposableArchitecture

struct CalendarClient {
    var getQuotesMonthly: @Sendable (_ yearMonth: String) async throws -> MemberMonthlyQuoteResponse
    var getQuotesMonthlyNonMember: @Sendable (_ yearMonth: String) async throws -> [MonthlyQuoteResponse]
}

extension CalendarClient: DependencyKey {
    static let liveValue: CalendarClient = {
        let repository = LiveRepositories.calendar

        return CalendarClient(
            getQuotesMonthly: { yearMonth in
                try await repository.getQuotesMonthly(yearMonth: yearMonth)
            },
            getQuotesMonthlyNonMember: { yearMonth in
                try await repository.getQuotesMonthlyNonMember(yearMonth: yearMonth)
            }
        )
    }()
}

extension DependencyValues {
    var calendarClient: CalendarClient {
        get { self[CalendarClient.self] }
        set { self[CalendarClient.self] = newValue }
    }
}

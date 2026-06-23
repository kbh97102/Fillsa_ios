import ComposableArchitecture

struct CalendarUseCases {
    var loadMonth: @Sendable (_ yearMonth: String) async throws -> MemberMonthlyQuoteResponse
}

extension CalendarUseCases: DependencyKey {
    static let liveValue: CalendarUseCases = {
        let calendarRepository = LiveRepositories.calendar
        let localRepository = LiveRepositories.local

        return CalendarUseCases(
            loadMonth: { yearMonth in
                try await LoadCalendarMonthUseCase(
                    calendarRepository: calendarRepository,
                    localRepository: localRepository
                )(yearMonth: yearMonth)
            }
        )
    }()
}

extension DependencyValues {
    var calendarUseCases: CalendarUseCases {
        get { self[CalendarUseCases.self] }
        set { self[CalendarUseCases.self] = newValue }
    }
}

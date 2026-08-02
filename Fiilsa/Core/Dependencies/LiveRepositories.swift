enum LiveRepositories {
    static let local: LocalRepository = {
        do {
            return try DefaultLocalRepository()
        } catch {
            fatalError("Failed to create DefaultLocalRepository: \(error)")
        }
    }()

    static let common: CommonRepository = DefaultCommonRepository()
    static let auth: AuthRepository = DefaultAuthRepository()
    static let home: HomeRepository = DefaultHomeRepository()
    static let quoteList: QuoteListRepository = DefaultQuoteListRepository()
    static let calendar: CalendarRepository = DefaultCalendarRepository()
    static let typing: TypingRepository = DefaultTypingRepository()
    static let pushRegistration: PushRegistrationRepository = DefaultPushRegistrationRepository()
}

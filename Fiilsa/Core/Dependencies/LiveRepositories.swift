enum LiveRepositories {
    static let tokenStore = KeychainTokenStore()

    static let local: LocalRepository = {
        do {
            return try DefaultLocalRepository(tokenStore: tokenStore)
        } catch {
            fatalError("Failed to create DefaultLocalRepository: \(error)")
        }
    }()

    static let common: CommonRepository = DefaultCommonRepository(
        apiClient: APIClientFactory.authenticated(tokenStore: tokenStore)
    )
    static let auth: AuthRepository = DefaultAuthRepository()
    static let home: HomeRepository = DefaultHomeRepository(
        apiClient: APIClientFactory.authenticated(tokenStore: tokenStore)
    )
    static let quoteList: QuoteListRepository = DefaultQuoteListRepository(
        apiClient: APIClientFactory.authenticated(tokenStore: tokenStore)
    )
    static let calendar: CalendarRepository = DefaultCalendarRepository(
        apiClient: APIClientFactory.authenticated(tokenStore: tokenStore)
    )
    static let typing: TypingRepository = DefaultTypingRepository(
        apiClient: APIClientFactory.authenticated(tokenStore: tokenStore)
    )
    static let pushRegistration: PushRegistrationRepository = DefaultPushRegistrationRepository(
        apiClient: APIClientFactory.authenticated(tokenStore: tokenStore)
    )
}

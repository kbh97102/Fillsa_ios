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
        apiClient: APIClientFactory.authenticated(tokenStore: tokenStore, deviceIDProvider: { "" })
    )
    static let auth: AuthRepository = DefaultAuthRepository()
    static let home: HomeRepository = DefaultHomeRepository(
        apiClient: APIClientFactory.authenticated(tokenStore: tokenStore, deviceIDProvider: { "" })
    )
    static let quoteList: QuoteListRepository = DefaultQuoteListRepository(
        apiClient: APIClientFactory.authenticated(tokenStore: tokenStore, deviceIDProvider: { "" })
    )
    static let calendar: CalendarRepository = DefaultCalendarRepository(
        apiClient: APIClientFactory.authenticated(tokenStore: tokenStore, deviceIDProvider: { "" })
    )
    static let typing: TypingRepository = DefaultTypingRepository(
        apiClient: APIClientFactory.authenticated(tokenStore: tokenStore, deviceIDProvider: { "" })
    )
    static let pushRegistration: PushRegistrationRepository = DefaultPushRegistrationRepository(
        apiClient: APIClientFactory.authenticated(
            tokenStore: tokenStore,
            deviceIDProvider: { DeviceIDProvider.current() }
        )
    )
}

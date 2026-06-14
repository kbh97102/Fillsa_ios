enum LiveRepositories {
    static let local: LocalRepository = {
        do {
            return try DefaultLocalRepository()
        } catch {
            fatalError("Failed to create DefaultLocalRepository: \(error)")
        }
    }()

    static let common: CommonRepository = DefaultCommonRepository()
}

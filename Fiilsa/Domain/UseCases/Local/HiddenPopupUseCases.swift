struct AddHiddenPopupUseCase {
    let localRepository: LocalRepository

    func callAsFunction(seq: Int) async throws {
        try await localRepository.addHiddenPopup(seq: seq)
    }
}

struct CheckPopupIsHiddenUseCase {
    let localRepository: LocalRepository

    func callAsFunction(seq: Int) async throws -> Bool {
        try await localRepository.checkPopupIsHidden(seq: seq)
    }
}

struct ClearAllHiddenPopupUseCase {
    let localRepository: LocalRepository

    func callAsFunction() async throws {
        try await localRepository.clearAllHiddenPopup()
    }
}

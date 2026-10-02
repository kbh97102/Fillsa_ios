import ComposableArchitecture
import Foundation

@Reducer
struct MyPageFeature {
    @ObservableState
    struct State: Equatable {
        var isLoggedIn = false
        var userName = ""
        var imagePath = ""
        var selectedTheme: DarkModeType = .system
        var isThemeDialogPresented = false
        var isProcessing = false
        var isResignDialogPresented = false
        var toastMessage: String?
    }

    enum Action: Equatable {
        case onAppear
        case loaded(isLoggedIn: Bool, userName: String, imagePath: String, selectedTheme: DarkModeType)
        case logoTapped
        case loginTapped
        case noticeTapped
        case alertTapped
        case themeTapped
        case themeSelected(DarkModeType)
        case themeDialogConfirmed
        case logoutTapped
        case loggedOut
        case resignTapped
        case resignDialogDismissed
        case resignConfirmed
        case resignCompleted(Result<Bool, ResignError>)
        case resignCancelled
        case toastDismissed
        case delegate(Delegate)

        enum Delegate: Equatable {
            case homeSelected
            case loginSelected
            case noticeSelected
            case alertSelected
            case resignCompleted
        }
    }

    enum ResignError: Error, Equatable {
        case failed
    }

    @Dependency(\.sessionClient) private var sessionClient
    @Dependency(\.settingsClient) private var settingsClient
    @Dependency(\.commonClient) private var commonClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let isLoggedIn = (try? await sessionClient.isLoggedIn()) ?? false
                    let userName = (try? await settingsClient.getUserName()) ?? ""
                    let imagePath = (try? await settingsClient.getImageURI()) ?? ""
                    let selectedTheme = (try? await settingsClient.getDarkModeType()) ?? .system

                    await send(
                        .loaded(
                            isLoggedIn: isLoggedIn,
                            userName: userName,
                            imagePath: imagePath,
                            selectedTheme: selectedTheme
                        )
                    )
                }

            case let .loaded(isLoggedIn, userName, imagePath, selectedTheme):
                state.isLoggedIn = isLoggedIn
                state.userName = userName
                state.imagePath = imagePath
                state.selectedTheme = selectedTheme
                return .none

            case .logoTapped:
                return .send(.delegate(.homeSelected))

            case .loginTapped:
                return .send(.delegate(.loginSelected))

            case .noticeTapped:
                return .send(.delegate(.noticeSelected))

            case .alertTapped:
                return .send(.delegate(.alertSelected))

            case .themeTapped:
                state.isThemeDialogPresented = true
                return .none

            case let .themeSelected(theme):
                state.selectedTheme = theme
                return .run { _ in
                    try? await settingsClient.setDarkModeType(theme)
                }

            case .themeDialogConfirmed:
                state.isThemeDialogPresented = false
                return .none

            case .logoutTapped:
                return .run { send in
                    try? await sessionClient.logout()
                    await send(.loggedOut)
                }

            case .loggedOut:
                state.isLoggedIn = false
                state.userName = ""
                state.imagePath = ""
                return .none

            case .resignTapped:
                guard state.isLoggedIn, !state.isProcessing else { return .none }
                state.isResignDialogPresented = true
                return .none

            case .resignDialogDismissed:
                state.isResignDialogPresented = false
                return .none

            case .resignConfirmed:
                guard state.isLoggedIn, !state.isProcessing else { return .none }
                state.isProcessing = true
                state.isResignDialogPresented = false
                return .runWithLoading { send in
                    do {
                        try await commonClient.deleteResign()
                    } catch is CancellationError {
                        await send(.resignCancelled)
                        return
                    } catch {
                        guard !Task.isCancelled else { return }
                        guard Self.isAlreadyWithdrawn(error) else {
                            await send(.resignCompleted(.failure(.failed)))
                            return
                        }
                    }

                    guard !Task.isCancelled else { return }

                    do {
                        try await sessionClient.logout()
                    } catch is CancellationError {
                        await send(.resignCancelled)
                        return
                    } catch {
                    }
                    guard !Task.isCancelled else { return }
                    await send(.resignCompleted(.success(true)))
                }

            case .resignCompleted(.success):
                state.isProcessing = false
                state.isLoggedIn = false
                state.userName = ""
                state.imagePath = ""
                return .send(.delegate(.resignCompleted))

            case .resignCompleted(.failure):
                state.isProcessing = false
                state.toastMessage = "탈퇴 처리에 실패했습니다."
                return .none

            case .resignCancelled:
                state.isProcessing = false
                return .none

            case .toastDismissed:
                state.toastMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private nonisolated static func isAlreadyWithdrawn(_ error: Error) -> Bool {
        guard let response = error as? ErrorResponse else { return false }
        return response.httpStatus == 404
            && response.errorCode == 1002
            && response.message == "Withdrawal user"
    }
}

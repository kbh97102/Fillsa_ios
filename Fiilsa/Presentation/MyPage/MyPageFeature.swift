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
        case delegate(Delegate)

        enum Delegate: Equatable {
            case homeSelected
            case loginSelected
            case noticeSelected
            case alertSelected
        }
    }

    @Dependency(\.sessionClient) private var sessionClient
    @Dependency(\.settingsClient) private var settingsClient

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

            case .delegate:
                return .none
            }
        }
    }
}

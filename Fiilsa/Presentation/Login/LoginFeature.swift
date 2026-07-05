import ComposableArchitecture
import Foundation

@Reducer
struct LoginFeature {
    @ObservableState
    struct State: Equatable {
        var isOnboarding = false
        var isProcessing = false
        var toastMessage: String?

        init(isOnboarding: Bool = false) {
            self.isOnboarding = isOnboarding
        }
    }

    enum Action: Equatable {
        case kakaoTapped
        case appleTapped
        case nonMemberTapped
        case closeTapped
        case socialLoginCompleted(Result<LoginResponse, LoginError>)
        case toastDismissed
        case delegate(Delegate)

        enum Delegate: Equatable {
            case close
            case moveHome
            case moveOnboardingGuide
        }
    }

    enum LoginError: Error, Equatable {
        case missingConfiguration
        case cancelled
        case failed
    }

    @Dependency(\.socialAuthClient) private var socialAuthClient
    @Dependency(\.authUseCases) private var authUseCases
    @Dependency(\.sessionClient) private var sessionClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .kakaoTapped:
                guard !state.isProcessing else { return .none }
                state.isProcessing = true
                return .run { send in
                    do {
                        let user = try await socialAuthClient.signInWithKakao()
                        let response = try await authUseCases.login(user)
                        await send(.socialLoginCompleted(.success(response)))
                    } catch {
                        await send(.socialLoginCompleted(.failure(map(error))))
                    }
                }

            case .appleTapped:
                guard !state.isProcessing else { return .none }
                state.isProcessing = true
                return .run { send in
                    do {
                        let user = try await socialAuthClient.signInWithApple()
                        let response = try await authUseCases.login(user)
                        await send(.socialLoginCompleted(.success(response)))
                    } catch {
                        await send(.socialLoginCompleted(.failure(map(error))))
                    }
                }

            case .nonMemberTapped:
                return .run { send in
                    try? await sessionClient.setAccessToken("")
                    try? await sessionClient.setRefreshToken("")
                    await send(.delegate(.moveOnboardingGuide))
                }

            case .closeTapped:
                return .send(.delegate(.close))

            case .socialLoginCompleted(.success):
                state.isProcessing = false
                return .send(.delegate(.moveHome))

            case let .socialLoginCompleted(.failure(error)):
                state.isProcessing = false
                switch error {
                case .missingConfiguration:
                    state.toastMessage = "소셜 로그인 설정이 필요합니다."
                case .cancelled:
                    state.toastMessage = nil
                case .failed:
                    state.toastMessage = "로그인에 실패했습니다."
                }
                return .none

            case .toastDismissed:
                state.toastMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }

    private func map(_ error: Error) -> LoginError {
        if let socialError = error as? SocialAuthError {
            switch socialError {
            case .missingConfiguration:
                return .missingConfiguration
            case .cancelled:
                return .cancelled
            default:
                return .failed
            }
        }
        return .failed
    }
}

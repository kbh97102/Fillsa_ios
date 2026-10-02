import ComposableArchitecture
import Foundation

@Reducer
struct LoginFeature {
    @ObservableState
    struct State: Equatable {
        var isOnboarding = false
        var isProcessing = false
        var isKakaoTalkInstallDialogPresented = false
        var toastMessage: String?

        init(isOnboarding: Bool = false) {
            self.isOnboarding = isOnboarding
        }
    }

    enum Action: Equatable {
        case kakaoTapped
        case kakaoAuthenticationCompleted(Result<SocialAuthUser, LoginError>)
        case appleTapped
        case appleAuthenticationCompleted(Result<SocialAuthUser, LoginError>)
        case kakaoTalkInstallDialogDismissed
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
        case kakaoTalkNotInstalled
        case cancelled
        case failed
    }

    @Dependency(\.socialAuthClient) private var socialAuthClient
    @Dependency(\.authUseCases) private var authUseCases
    @Dependency(\.sessionClient) private var sessionClient
    @Dependency(\.pushRegistrationClient) private var pushRegistrationClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .kakaoTapped:
                guard !state.isProcessing else { return .none }
                state.isProcessing = true
                return .run { send in
                    do {
                        let user = try await socialAuthClient.signInWithKakao()
                        await send(.kakaoAuthenticationCompleted(.success(user)))
                    } catch {
                        await send(.kakaoAuthenticationCompleted(.failure(map(error))))
                    }
                }

            case .kakaoTalkInstallDialogDismissed:
                state.isKakaoTalkInstallDialogPresented = false
                return .none

            case let .kakaoAuthenticationCompleted(.success(user)):
                return login(user: user)

            case let .kakaoAuthenticationCompleted(.failure(error)):
                return .send(.socialLoginCompleted(.failure(error)))

            case .appleTapped:
                guard !state.isProcessing else { return .none }
                state.isProcessing = true
                return .run { send in
                    do {
                        let user = try await socialAuthClient.signInWithApple()
                        await send(.appleAuthenticationCompleted(.success(user)))
                    } catch {
                        await send(.appleAuthenticationCompleted(.failure(map(error))))
                    }
                }

            case let .appleAuthenticationCompleted(.success(user)):
                return login(user: user)

            case let .appleAuthenticationCompleted(.failure(error)):
                return .send(.socialLoginCompleted(.failure(error)))

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
                return .merge(
                    .send(.delegate(.moveHome)),
                    .run { _ in
                        await pushRegistrationClient.synchronize(nil)
                    }
                )

            case let .socialLoginCompleted(.failure(error)):
                state.isProcessing = false
                switch error {
                case .missingConfiguration:
                    state.toastMessage = "소셜 로그인 설정이 필요합니다."
                case .kakaoTalkNotInstalled:
                    state.isKakaoTalkInstallDialogPresented = true
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
            case .kakaoTalkNotInstalled:
                return .kakaoTalkNotInstalled
            case .cancelled:
                return .cancelled
            default:
                return .failed
            }
        }
        return .failed
    }

    private func login(user: SocialAuthUser) -> Effect<Action> {
        .runWithLoading { send in
            do {
                let response = try await authUseCases.login(user)
                guard !Task.isCancelled else { return }
                await send(.socialLoginCompleted(.success(response)))
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                await send(.socialLoginCompleted(.failure(map(error))))
            }
        }
    }
}

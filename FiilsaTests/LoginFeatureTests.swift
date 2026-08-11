import ComposableArchitecture
import XCTest
@testable import Fiilsa

@MainActor
final class LoginFeatureTests: XCTestCase {
    func testKakaoTapAuthenticatesThenLogsIntoBackend() async {
        let user = SocialAuthUser(
            provider: "KAKAO",
            oauthID: "42",
            nickname: "필사",
            profileImageURL: "https://example.com/profile.png"
        )
        let response = LoginResponse(
            accessToken: "access",
            refreshToken: "refresh",
            memberSeq: 1,
            nickname: "필사",
            profileImageUrl: "https://example.com/profile.png"
        )
        let store = TestStore(initialState: LoginFeature.State()) {
            LoginFeature()
        } withDependencies: {
            $0.socialAuthClient.signInWithKakao = { user }
            $0.authUseCases.login = { receivedUser in
                XCTAssertEqual(receivedUser, user)
                return response
            }
            $0.pushRegistrationClient.synchronize = { _ in }
        }

        await store.send(.kakaoTapped) {
            $0.isProcessing = true
        }
        await store.receive(.kakaoAuthenticationCompleted(.success(user)))
        await store.receive(.socialLoginCompleted(.success(response))) {
            $0.isProcessing = false
        }
        await store.receive(.delegate(.moveHome))
        await store.finish()
    }

    func testKakaoTalkUnavailableShowsAndroidParityInstallAlert() async {
        let store = TestStore(initialState: LoginFeature.State()) {
            LoginFeature()
        } withDependencies: {
            $0.socialAuthClient.signInWithKakao = {
                throw SocialAuthError.kakaoTalkNotInstalled
            }
        }

        await store.send(.kakaoTapped) {
            $0.isProcessing = true
        }
        await store.receive(.kakaoAuthenticationCompleted(.failure(.kakaoTalkNotInstalled)))
        await store.receive(.socialLoginCompleted(.failure(.kakaoTalkNotInstalled))) {
            $0.isProcessing = false
            $0.isKakaoTalkInstallDialogPresented = true
        }
        await store.send(.kakaoTalkInstallDialogDismissed) {
            $0.isKakaoTalkInstallDialogPresented = false
        }
        await store.finish()
    }

    func testKakaoCancellationLeavesLoginScreenWithoutMessage() async {
        let store = TestStore(initialState: LoginFeature.State()) {
            LoginFeature()
        } withDependencies: {
            $0.socialAuthClient.signInWithKakao = {
                throw SocialAuthError.cancelled
            }
        }

        await store.send(.kakaoTapped) {
            $0.isProcessing = true
        }
        await store.receive(.kakaoAuthenticationCompleted(.failure(.cancelled)))
        await store.receive(.socialLoginCompleted(.failure(.cancelled))) {
            $0.isProcessing = false
        }
        await store.finish()
    }

    func testKakaoProviderFailureShowsGenericLoginFailureMessage() async {
        let store = TestStore(initialState: LoginFeature.State()) {
            LoginFeature()
        } withDependencies: {
            $0.socialAuthClient.signInWithKakao = {
                throw KakaoLoginTestError.failed
            }
        }

        await store.send(.kakaoTapped) {
            $0.isProcessing = true
        }
        await store.receive(.kakaoAuthenticationCompleted(.failure(.failed)))
        await store.receive(.socialLoginCompleted(.failure(.failed))) {
            $0.isProcessing = false
            $0.toastMessage = "로그인에 실패했습니다."
        }
        await store.finish()
    }
}

private enum KakaoLoginTestError: Error {
    case failed
}

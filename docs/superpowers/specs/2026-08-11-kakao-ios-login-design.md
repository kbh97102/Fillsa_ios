# Kakao iOS Login Design

## Goal

Replace the iOS login screen's Kakao “coming soon” alert with the same KakaoTalk-only login behaviour as Android, while preserving the existing server login contract and TCA boundaries.

## Scope and parity

- Use the Kakao iOS SDK and the existing Kakao Developers app's Native App Key.
- When KakaoTalk is installed, authenticate through KakaoTalk, fetch the Kakao account ID, nickname, and profile image, then call the existing `/api/v1/auth/login` flow with provider `KAKAO`.
- When KakaoTalk is not installed, present an acknowledgement alert titled `카카오톡 설치 후 이용해주세요.` (the Android dialog's copy) and do not open a browser-based Kakao Account login.
- Treat user cancellation as a silent return to the login screen. Show the existing generic login failure toast for other provider failures.
- Do not change server APIs, account linking, app navigation, Apple login, guest login, or Kakao share.

## Architecture

`LoginFeature` remains the TCA reducer responsible for processing state and navigation. It will start the injected `SocialAuthClient.signInWithKakao` effect, then pass the resulting `SocialAuthUser` through the same `AuthUseCases.login` path already used by Apple login.

`SocialAuthClient` will wrap the Kakao SDK. It checks KakaoTalk availability, starts `UserApi.shared.loginWithKakaoTalk`, calls `UserApi.shared.me`, and maps only the server-required fields to `SocialAuthUser`. SDK setup and callback handling stay in the app lifecycle layer (`AppDelegate` and `FiilsaApp`), analogous to Android's `FillsaApplication` SDK initialization and manifest redirect activity.

## Project configuration

- Add `https://github.com/kakao/kakao-ios-sdk` through Swift Package Manager with `KakaoSDKUser`; its dependent Common and Auth modules resolve automatically.
- Store the Native App Key in the existing `KAKAO_NATIVE_APP_KEY` build setting, expose it through `Info.plist`, and initialize `KakaoSDK` during app launch.
- Register the URL scheme `kakao$(KAKAO_NATIVE_APP_KEY)` and the `kakaokompassauth` query scheme.
- Forward callback URLs from SwiftUI `onOpenURL` to `AuthController.handleOpenUrl` when `AuthApi.isKakaoTalkLoginUrl` accepts them.
- Remove the unused REST OAuth configuration and browser authentication implementation so no REST API key or client secret is shipped for Kakao login.

## Error handling

`SocialAuthError` gains a KakaoTalk-not-installed case. `LoginFeature` maps it to the Android-parity acknowledgement alert above. Missing Native App Key maps to the existing social-login-configuration toast, cancellation remains silent, and all other SDK/user profile failures map to the existing generic failure toast.

## Tests and verification

- Replace the obsolete “coming soon dialog” reducer test with test-first coverage that verifies Kakao tap starts the injected social-login effect and that the resulting user reaches the existing auth login action.
- Add reducer tests for KakaoTalk-not-installed, cancellation, and generic provider failure state/copy.
- Build the iOS target after Swift Package resolution and run `LoginFeatureTests`.
- Manually verify on a signed device with KakaoTalk installed because the KakaoTalk app-to-app redirect cannot be validated in Simulator.

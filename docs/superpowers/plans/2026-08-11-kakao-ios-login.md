# Kakao iOS Login Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the iOS Kakao “coming soon” alert with Android-parity KakaoTalk SDK authentication and the existing server login flow.

**Architecture:** The SwiftUI lifecycle owns Kakao SDK initialization and URL callback forwarding. `SocialAuthClient` wraps the SDK and converts the Kakao profile to the existing provider-neutral `SocialAuthUser`; `LoginFeature` owns loading, alert, error, and navigation state and invokes the unchanged `AuthUseCases.login` effect.

**Tech Stack:** SwiftUI, The Composable Architecture, Kakao iOS SDK (`KakaoSDKUser`), Swift Package Manager, XCTest, xcodebuild.

## Global Constraints

- Preserve Android parity: only KakaoTalk app login; show `카카오톡 설치 후 이용해주세요.` when KakaoTalk is unavailable; do not add browser Kakao Account login.
- Use the existing Kakao Developers app's Native App Key. Do not add keys, tokens, or secrets to source control.
- The server login payload stays `provider: "KAKAO"` with Kakao account ID, nickname, and profile image URL.
- Keep TCA separation: Views send actions, `LoginFeature` manages state/effects, and `SocialAuthClient` is the SDK boundary.
- Do not alter Apple login, guest login, server endpoints, account deletion, or sharing.
- The current iOS deployment target is 26.4, above Kakao SDK's iOS 13 minimum.

---

### Task 1: Specify and implement the Kakao TCA reducer path

**Files:**
- Modify: `FiilsaTests/LoginFeatureTests.swift`
- Modify: `Fiilsa/Presentation/Login/LoginFeature.swift`
- Modify: `Fiilsa/Presentation/Login/LoginView.swift`

**Interfaces:**
- Consumes: `SocialAuthClient.signInWithKakao: @Sendable () async throws -> SocialAuthUser`
- Consumes: `AuthUseCases.login: @Sendable (SocialAuthUser) async throws -> LoginResponse`
- Produces: `LoginFeature.Action.kakaoAuthenticationCompleted(Result<SocialAuthUser, LoginError>)`
- Produces: `LoginFeature.State.isKakaoTalkInstallDialogPresented: Bool`

- [ ] **Step 1: Replace the obsolete reducer test with a failing Kakao-start expectation.**

```swift
func testKakaoTapStartsAuthenticationInsteadOfShowingComingSoonDialog() async {
    let store = TestStore(initialState: LoginFeature.State()) {
        LoginFeature()
    }

    await store.send(.kakaoTapped) {
        $0.isProcessing = true
        $0.isKakaoComingSoonDialogPresented = false
    }
    await store.finish()
}
```

- [ ] **Step 2: Run the focused test and verify that it fails because the current reducer presents the coming-soon dialog.**

Run: `xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa -only-testing:FiilsaTests/LoginFeatureTests -destination 'platform=iOS Simulator,name=iPhone 17'`

Expected: `testKakaoTapStartsAuthenticationInsteadOfShowingComingSoonDialog` fails its state assertion; no compilation error.

- [ ] **Step 3: Add the reducer's minimal Kakao authentication effect.**

```swift
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

case let .kakaoAuthenticationCompleted(.success(user)):
    return login(user: user)

case let .kakaoAuthenticationCompleted(.failure(error)):
    return .send(.socialLoginCompleted(.failure(error)))
```

Extract the common server-login `.run` effect used by Apple and Kakao into `login(user:)`. Remove `isKakaoComingSoonDialogPresented` and `kakaoComingSoonDialogDismissed`; replace them with `isKakaoTalkInstallDialogPresented` and `kakaoTalkInstallDialogDismissed`. Add `LoginError.kakaoTalkNotInstalled` and map it to this alert state while retaining existing missing-configuration, cancellation, and generic-failure handling.

- [ ] **Step 4: Change the view from the coming-soon alert to the Android-parity installation alert.**

```swift
.alert(
    "카카오톡 설치 후 이용해주세요.",
    isPresented: Binding(
        get: { viewStore.isKakaoTalkInstallDialogPresented },
        set: { if !$0 { viewStore.send(.kakaoTalkInstallDialogDismissed) } }
    )
) {
    Button("확인", role: .cancel) {}
}
```

- [ ] **Step 5: Expand the reducer tests for end-to-end effect actions and errors.**

```swift
func testKakaoTapAuthenticatesThenLogsIntoBackend() async {
    let user = SocialAuthUser(provider: "KAKAO", oauthID: "42", nickname: "필사", profileImageURL: "https://example.com/profile.png")
    let response = LoginResponse(accessToken: "access", refreshToken: "refresh", memberSeq: 1, nickname: "필사", profileImageUrl: "https://example.com/profile.png")
    let store = TestStore(initialState: LoginFeature.State()) { LoginFeature() } withDependencies: {
        $0.socialAuthClient.signInWithKakao = { user }
        $0.authUseCases.login = { receivedUser in
            XCTAssertEqual(receivedUser, user)
            return response
        }
        $0.pushRegistrationClient.synchronize = { _ in }
    }

    await store.send(.kakaoTapped) { $0.isProcessing = true }
    await store.receive(.kakaoAuthenticationCompleted(.success(user)))
    await store.receive(.socialLoginCompleted(.success(response))) { $0.isProcessing = false }
    await store.receive(.delegate(.moveHome))
}
```

Add parallel tests whose injected Kakao closure throws `SocialAuthError.kakaoTalkNotInstalled`, `.cancelled`, and an arbitrary error. Assert, respectively: installation alert is presented; no toast or alert is shown; and `toastMessage == "로그인에 실패했습니다."`.

- [ ] **Step 6: Run the focused reducer test suite and verify it passes.**

Run: `xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa -only-testing:FiilsaTests/LoginFeatureTests -destination 'platform=iOS Simulator,name=iPhone 17'`

Expected: all `LoginFeatureTests` pass.

- [ ] **Step 7: Commit the tested reducer/UI change.**

```bash
git add FiilsaTests/LoginFeatureTests.swift Fiilsa/Presentation/Login/LoginFeature.swift Fiilsa/Presentation/Login/LoginView.swift
git commit -m "feat: start Kakao login from login feature"
```

### Task 2: Replace browser OAuth with Kakao SDK integration

**Files:**
- Modify: `Fiilsa/Core/Dependencies/AuthConfig.swift`
- Modify: `Fiilsa/Core/Dependencies/SocialAuthClient.swift`
- Modify: `Fiilsa/AppDelegate.swift`
- Modify: `Fiilsa/FiilsaApp.swift`
- Modify: `Fiilsa/Info.plist`
- Modify: `Fiilsa.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `AuthConfig.kakaoNativeAppKey: String`
- Produces: `SocialAuthClient.signInWithKakao` backed by `UserApi.shared.loginWithKakaoTalk` then `UserApi.shared.me`
- Produces: SwiftUI callback forwarding to `AuthController.handleOpenUrl(url:)`

- [ ] **Step 1: Add Kakao SDK packages and native-key configuration.**

Add `https://github.com/kakao/kakao-ios-sdk` as an Xcode Swift Package dependency and link `KakaoSDKUser` to the `Fiilsa` application target. Set an empty `KAKAO_NATIVE_APP_KEY` build setting in Debug and Release. Replace the two REST build settings and `AuthConfig` properties with one `kakaoNativeAppKey` property that reads `KAKAO_NATIVE_APP_KEY`.

- [ ] **Step 2: Configure the iOS app URL schemes without hard-coding the key.**

```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>kakao$(KAKAO_NATIVE_APP_KEY)</string>
</array>
<key>KAKAO_NATIVE_APP_KEY</key>
<string>$(KAKAO_NATIVE_APP_KEY)</string>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>kakaokompassauth</string>
</array>
```

Remove the obsolete `fillsa` URL type and REST redirect/key entries because no other feature consumes them.

- [ ] **Step 3: Replace `WebSocialAuthClient` with an SDK-backed client.**

```swift
guard !config.kakaoNativeAppKey.isEmpty else {
    throw SocialAuthError.missingConfiguration
}
guard UserApi.isKakaoTalkLoginAvailable() else {
    throw SocialAuthError.kakaoTalkNotInstalled
}

try await loginWithKakaoTalk()
let user = try await kakaoUser()
return SocialAuthUser(
    provider: "KAKAO",
    oauthID: String(user.id ?? 0),
    nickname: user.kakaoAccount?.profile?.nickname ?? "",
    profileImageURL: user.kakaoAccount?.profile?.profileImageUrl ?? ""
)
```

Wrap the SDK's completion handlers with checked throwing continuations. Map the SDK cancellation error to `SocialAuthError.cancelled`; map missing/invalid Kakao profile IDs and all other errors to the existing generic failure path. Delete `ASWebAuthenticationSession`, `WebAuthSessionStore`, `PresentationContextProvider`, REST URL creation, token exchange, and REST user-profile code. Preserve the Apple sign-in coordinator unchanged.

- [ ] **Step 4: Initialize the SDK and handle KakaoTalk return URLs.**

```swift
// AppDelegate.application(_:didFinishLaunchingWithOptions:)
KakaoSDK.initSDK(appKey: AuthConfig.current.kakaoNativeAppKey)

// FiilsaApp WindowGroup
.onOpenURL { url in
    guard AuthApi.isKakaoTalkLoginUrl(url) else { return }
    _ = AuthController.handleOpenUrl(url: url)
}
```

Import only `KakaoSDKCommon` in `AppDelegate` and `KakaoSDKAuth` in `FiilsaApp`; use `KakaoSDKUser` in `SocialAuthClient`.

- [ ] **Step 5: Build the application after package resolution.**

Run: `xcodebuild -quiet -project Fiilsa.xcodeproj -scheme Fiilsa -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -clonedSourcePackagesDirPath /tmp/fiilsa-kakao-packages CODE_SIGNING_ALLOWED=NO build`

Expected: exit status 0. If package fetching is blocked by the sandbox, rerun the same command with approved network/filesystem access rather than changing dependency versions.

- [ ] **Step 6: Commit the SDK/configuration integration.**

```bash
git add Fiilsa/Core/Dependencies/AuthConfig.swift Fiilsa/Core/Dependencies/SocialAuthClient.swift Fiilsa/AppDelegate.swift Fiilsa/FiilsaApp.swift Fiilsa/Info.plist Fiilsa.xcodeproj/project.pbxproj
git commit -m "feat: authenticate Kakao login with iOS SDK"
```

### Task 3: Update the login specification and verify the completed feature

**Files:**
- Modify: `docs/screens/1_login.md`
- Modify: `docs/social-login-implementation.md`
- Modify: `docs/unfinished-features.md`

**Interfaces:**
- Documents the final production behaviour of Tasks 1 and 2; no new runtime interface is introduced.

- [ ] **Step 1: Update the screen plan before release verification.**

Replace every statement that Kakao login is “준비 중” with: KakaoTalk-installed devices perform Kakao SDK login; KakaoTalk-unavailable devices show `카카오톡 설치 후 이용해주세요.`; cancellation stays on the login screen; other errors show `로그인에 실패했습니다.`. Record that the server receives provider `KAKAO`, account ID, nickname, and profile image URL.

- [ ] **Step 2: Replace REST OAuth documentation with the SDK configuration.**

Document the Native App Key, `kakao$(KAKAO_NATIVE_APP_KEY)` URL scheme, `kakaokompassauth` allowlist, SDK initialization, `onOpenURL` callback forwarding, and the fact that no REST API key or client secret is used by iOS login.

- [ ] **Step 3: Remove the obsolete social-login unfinished item.**

Change the social-login status to complete in `docs/unfinished-features.md`; retain any separate Kakao Talk Share decision as unfinished because it is outside this login task.

- [ ] **Step 4: Run final automated verification.**

Run: `xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,name=iPhone 17'`

Run: `xcodebuild -quiet -project Fiilsa.xcodeproj -scheme Fiilsa -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -clonedSourcePackagesDirPath /tmp/fiilsa-kakao-packages CODE_SIGNING_ALLOWED=NO build`

Expected: both commands exit 0. Record any simulator-service limitation separately; it must not be reported as a passing test run.

- [ ] **Step 5: Complete the signed-device acceptance check.**

On a physical iPhone with KakaoTalk installed and the registered `kbhdev.Fiilsa` bundle ID: tap the Kakao button, approve Kakao consent, return to Fiilsa, and confirm Home navigation with the existing account. On a device without KakaoTalk: tap the button and confirm only the installation alert appears.

- [ ] **Step 6: Commit documentation.**

```bash
git add docs/screens/1_login.md docs/social-login-implementation.md docs/unfinished-features.md
git commit -m "docs: record Kakao iOS login setup"
```

# 소셜 로그인 구현 정리

이 문서는 iOS 소셜 로그인 구현에서 준비한 것, 개발 순서, 남은 설정을 정리한다. Android 기준 동작은 `LoginViewModel.kt`와 `LoginView.kt`를 기준으로 맞췄다.

## 1. Android 동작 확인

Android는 로그인 버튼을 누르면 각 provider 인증을 먼저 수행한다.

- Kakao: Kakao SDK로 access token을 받고 `UserApiClient.me()`로 사용자 id, nickname, profileImage를 조회한다.
- Apple: `AuthenticationServices`로 Apple ID credential을 받고 user identifier, fullName을 읽는다.
- 서버 로그인 요청에는 provider token 자체를 보내지 않고, `DeviceData`, `UserData`, `syncData`를 보낸다.
- 서버 로그인 성공 후 access token, refresh token, username, profile image를 로컬에 저장하고 Home으로 이동한다.

## 2. iOS에서 준비한 구조

iOS는 Android의 ViewModel 역할을 TCA 방식으로 나눴다.

- `LoginFeature`: 버튼 클릭, 로딩, toast, 화면 이동 이벤트를 처리한다.
- `SocialAuthClient`: Apple/카카오 인증창을 열고 provider 사용자 정보를 만든다.
- `AuthUseCases`: 서버 로그인 요청을 만들고 성공 후 토큰/사용자 정보를 저장한다.
- `DefaultAuthRepository`: 실제 로그인/토큰 갱신 API를 호출한다.
- `AuthConfig`: Info.plist에서 OAuth 설정값을 읽는다.

Android로 비교하면 `LoginFeature`는 MVI ViewModel, `SocialAuthClient`는 Kakao SDK/Apple 로그인 SDK 부분, `AuthUseCases`는 로그인 use case와 로컬 저장 처리에 가깝다.

## 3. 개발 순서

1. Android 로그인 흐름을 먼저 확인했다.
2. iOS 로그인 화면을 `LoginFeature` TCA reducer와 연결했다.
3. 카카오/Apple 버튼 action에서 provider 인증 후 서버 로그인을 호출하도록 구성했다.
4. `DefaultAuthRepository`를 추가해 `/login`, `/refreshToken` API를 연결했다.
5. `AuthUseCases`에서 Android와 같은 `LoginRequest` 형태를 만들었다.
6. 로그인 성공 시 access token, refresh token, userName, profileImage를 저장하도록 연결했다.
7. 비회원 시작은 토큰을 비우고 온보딩 가이드로 이동하도록 연결했다.
8. OAuth 설정이 없거나 실패/취소될 때 화면이 멈추지 않도록 toast/취소 처리를 넣었다.
9. `Fiilsa/Info.plist`에 `kakao$(KAKAO_NATIVE_APP_KEY)` URL scheme과 `kakaokompassauth` allowlist를 등록해 카카오톡 인증 뒤 앱으로 돌아올 수 있게 했다.
10. Xcode build setting의 `KAKAO_NATIVE_APP_KEY`를 Info.plist로 주입하고, 앱 시작 시 Kakao SDK를 초기화하도록 연결했다.
11. Google 로그인 구현을 제거하고 Apple 로그인 entitlement와 `ASAuthorizationAppleIDProvider` 기반 인증 흐름으로 교체했다.

## 4. iOS OAuth 방식

카카오는 Android와 같은 Kakao iOS SDK를 사용한다. `SocialAuthClient`가 카카오톡 앱 인증과 사용자 프로필 조회를 감싸고, `LoginFeature`는 인증 결과로 기존 서버 로그인 effect만 실행한다.

- Apple은 iOS 기본 `ASAuthorizationAppleIDProvider`로 인증한다.
- Apple의 `credential.user`를 `oAuthId`, `"APPLE"`을 `oAuthProvider`, `"IOS"`를 `deviceData.osType`으로 기존 로그인 API에 보낸다.
- Apple의 `fullName`은 최초 로그인에서만 제공되므로, 값이 있을 때 표시 이름으로 조합해 nickname에 넣고 이후 nil이면 빈 문자열을 보낸다.
- 카카오는 `UserApi.shared.loginWithKakaoTalk`으로 카카오톡 앱 인증을 진행한다.
- 카카오톡이 설치되지 않은 기기에서는 Android와 같은 `"카카오톡 설치 후 이용해주세요."` 안내 다이얼로그만 표시한다.
- Apple은 `ASAuthorizationAppleIDCredential.user`를 서버 로그인용 `oAuthId`로 사용한다.
- 카카오는 `UserApi.shared.me`로 사용자 정보를 조회한다.

## 5. 아직 필요한 외부 설정

코드는 연결되어 있고, iOS 앱 내부 callback 설정도 준비되어 있다. 실제 로그인 성공까지는 provider 콘솔에 iOS Bundle ID를 등록하고 Xcode build setting에 Native App Key를 설정해야 한다.

- Kakao Native App Key
- iOS Bundle ID: `kbhdev.Fiilsa`
- Apple Developer App ID의 Sign in with Apple capability

`Fiilsa/Info.plist`에는 Kakao용 URL scheme `kakao$(KAKAO_NATIVE_APP_KEY)`와 `kakaokompassauth` allowlist가 등록되어 있다. `FiilsaApp`의 `onOpenURL`이 카카오톡에서 돌아온 URL을 SDK에 전달한다. REST API key와 client secret은 iOS 로그인에 사용하지 않는다.

Apple 로그인 출시 전 설정은 `docs/apple-login-release-checklist.md`를 기준으로 확인한다.
TestFlight 배포와 실기기 검증은 `docs/testflight-distribution-guide.md`를 기준으로 진행한다.

## 6. 현재 사용자 경험

- Kakao 설정값이 없으면 카카오 버튼을 눌렀을 때 `"소셜 로그인 설정이 필요합니다."` toast가 표시된다.
- 사용자가 인증창을 닫으면 별도 에러 toast 없이 로그인 화면에 남는다.
- 서버 로그인 실패나 provider 응답 파싱 실패는 `"로그인에 실패했습니다."` toast로 표시된다.
- 로그인 성공 시 Home으로 이동한다.
- Apple 로그인도 인증 성공 후 카카오와 같은 `/api/v1/auth/login` 서버 흐름을 사용한다.

## 7. 검증 결과

`xcodebuild -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,name=iPhone 17' build -quiet` 빌드를 통과했다.

`Fiilsa/Info.plist`의 OAuth key와 URL scheme이 빌드된 앱 번들에 포함되는 것을 확인했다.
남은 검증은 실제 Kakao OAuth 설정과 Apple Developer capability를 적용한 뒤 실기기/시뮬레이터에서 로그인 성공 여부를 확인하는 것이다.

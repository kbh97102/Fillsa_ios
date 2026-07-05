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
9. `Fiilsa/Info.plist`를 추가하고 `fillsa` URL scheme을 등록해 OAuth 인증 후 앱으로 돌아올 수 있게 했다.
10. Xcode build setting 값을 Info.plist의 `KAKAO_REST_API_KEY`, `KAKAO_REDIRECT_URI`로 주입하도록 연결했다.
11. Google 로그인 구현을 제거하고 Apple 로그인 entitlement와 `ASAuthorizationAppleIDProvider` 기반 인증 흐름으로 교체했다.

## 4. iOS OAuth 방식

현재 구현은 별도 SDK를 바로 추가하지 않고 `ASWebAuthenticationSession`을 사용한다. Android의 AppAuth 브라우저 인증 플로우와 비슷하다.

- Apple은 iOS 기본 `ASAuthorizationAppleIDProvider`로 인증한다.
- 카카오는 REST API OAuth 인증 코드 방식으로 인증한다.
- 카카오는 인증 성공 후 callback URL에서 `code`를 받고, token endpoint로 교환한다.
- Apple은 `ASAuthorizationAppleIDCredential.user`를 서버 로그인용 `oAuthId`로 사용한다.
- 카카오는 `/v2/user/me` API로 사용자 정보를 조회한다.

## 5. 아직 필요한 외부 설정

코드는 연결되어 있고, iOS 앱 내부 callback 설정도 준비되어 있다. 실제 로그인 성공까지는 provider 콘솔에 실제 앱 키와 redirect URI를 등록해야 한다.

- Kakao REST API key
- Kakao redirect URI: `fillsa://oauth/kakao`
- Apple Developer App ID의 Sign in with Apple capability

`Fiilsa/Info.plist`에는 Kakao용 URL scheme `fillsa`가 등록되어 있다. Kakao 콘솔에도 위 redirect URI를 정확히 같은 문자열로 등록해야 Safari 인증 후 앱으로 돌아올 수 있다.

## 6. 현재 사용자 경험

- Kakao 설정값이 없으면 카카오 버튼을 눌렀을 때 `"소셜 로그인 설정이 필요합니다."` toast가 표시된다.
- 사용자가 인증창을 닫으면 별도 에러 toast 없이 로그인 화면에 남는다.
- 서버 로그인 실패나 provider 응답 파싱 실패는 `"로그인에 실패했습니다."` toast로 표시된다.
- 로그인 성공 시 Home으로 이동한다.

## 7. 검증 결과

`xcodebuild -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,name=iPhone 17' build -quiet` 빌드를 통과했다.

`Fiilsa/Info.plist`의 OAuth key와 URL scheme이 빌드된 앱 번들에 포함되는 것을 확인했다.
남은 검증은 실제 Kakao OAuth 설정과 Apple Developer capability를 적용한 뒤 실기기/시뮬레이터에서 로그인 성공 여부를 확인하는 것이다.

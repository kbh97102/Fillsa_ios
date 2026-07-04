# iOS 소셜 로그인 코드 이해하기

이 문서는 필사앱 iOS 소셜 로그인 구현을 처음 보는 개발자를 위한 설명이다. Swift, SwiftUI, TCA, iOS OAuth 흐름을 잘 모른다고 가정하고 작성했다.

Android 개발자 관점으로 비교하면 다음과 같다.

- SwiftUI `View`는 Jetpack Compose UI와 비슷하다.
- TCA `Feature`는 MVI ViewModel과 비슷하다.
- TCA `State`는 화면 상태다.
- TCA `Action`은 사용자의 클릭, API 결과, 화면 이동 이벤트다.
- `@Dependency`는 Hilt로 주입받는 use case나 repository와 비슷하다.
- `ASWebAuthenticationSession`은 Android의 AppAuth 브라우저 인증 플로우와 비슷하다.

---

## 1. 전체 흐름

소셜 로그인은 한 번에 서버 로그인을 하는 것이 아니다. 먼저 구글/카카오에서 사용자를 인증하고, 그 결과로 얻은 사용자 정보를 필사앱 서버에 보낸다.

현재 iOS 코드는 다음 순서로 동작한다.

```text
LoginView
  -> 사용자가 카카오/구글 버튼 클릭
  -> LoginFeature가 action 처리
  -> SocialAuthClient가 구글/카카오 OAuth 인증
  -> SocialAuthUser 생성
  -> AuthUseCases가 서버 LoginRequest 생성
  -> DefaultAuthRepository가 로그인 API 호출
  -> access token, refresh token, userName, profileImage 저장
  -> Home 화면으로 이동
```

여기서 중요한 점은 구글/카카오 access token을 그대로 필사앱 서버에 보내지 않는다는 것이다. Android 코드와 동일하게 provider, oauth id, nickname, profile image 정보를 서버 로그인 요청에 담는다.

---

## 2. 화면은 로그인 로직을 직접 알지 않는다

파일:

- `Fiilsa/Presentation/Login/LoginView.swift`

`LoginView`는 SwiftUI 화면이다. Android로 치면 Compose 함수에 가깝다.

카카오 버튼 코드는 이렇게 되어 있다.

```swift
LoginButton(
    icon: .kakao,
    text: "카카오 계정으로 시작하기",
    backgroundColor: Color(hex: 0xFEE500),
    onClick: {
        viewStore.send(.kakaoTapped)
    }
)
```

구글 버튼도 같은 방식이다.

```swift
LoginButton(
    icon: .google,
    text: "구글 계정으로 시작하기",
    backgroundColor: Color(hex: 0xF2F2F2),
    onClick: {
        viewStore.send(.googleTapped)
    }
)
```

여기서 `viewStore.send(.kakaoTapped)`가 핵심이다. 버튼이 눌렸다는 사실만 `LoginFeature`로 보낸다.

Android MVI로 비교하면 이런 느낌이다.

```kotlin
onClick = {
    viewModel.onEvent(LoginEvent.KakaoTapped)
}
```

즉, View는 카카오 SDK, 서버 API, 토큰 저장을 전혀 모른다. View는 이벤트만 보낸다.

---

## 3. LoginFeature는 화면의 ViewModel 역할을 한다

파일:

- `Fiilsa/Presentation/Login/LoginFeature.swift`

`LoginFeature`는 TCA의 reducer다. Android MVI의 ViewModel과 reducer를 합친 역할로 이해하면 된다.

### State

```swift
@ObservableState
struct State: Equatable {
    var isOnboarding = false
    var isProcessing = false
    var toastMessage: String?
}
```

이 값들은 화면이 그릴 상태다.

- `isOnboarding`: 온보딩 중 로그인 화면인지 여부
- `isProcessing`: 로그인 처리 중인지 여부
- `toastMessage`: 화면 아래에 보여줄 메시지

Android로 치면 `LoginUiState`에 들어갈 값들이다.

### Action

```swift
enum Action: Equatable {
    case kakaoTapped
    case googleTapped
    case nonMemberTapped
    case closeTapped
    case socialLoginCompleted(Result<LoginResponse, LoginError>)
    case toastDismissed
    case delegate(Delegate)
}
```

Action은 화면에서 일어난 일, 비동기 작업 결과, 부모 화면으로 올릴 이벤트를 모두 표현한다.

- `kakaoTapped`: 카카오 버튼 클릭
- `googleTapped`: 구글 버튼 클릭
- `nonMemberTapped`: 비회원 시작 클릭
- `socialLoginCompleted`: 소셜 로그인 + 서버 로그인 결과
- `delegate`: AppFeature에게 화면 이동을 요청하는 이벤트

---

## 4. 카카오 버튼을 누르면 어떤 코드가 실행될까?

`LoginFeature`에서 카카오 버튼 action을 처리하는 부분이다.

```swift
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
```

한 줄씩 보면 다음과 같다.

```swift
guard !state.isProcessing else { return .none }
```

이미 로그인 중이면 중복 클릭을 막는다.

```swift
state.isProcessing = true
```

로그인 처리 중 상태로 바꾼다. 이 값 때문에 버튼이 disabled 된다.

```swift
return .run { send in ... }
```

TCA에서 비동기 작업을 실행하는 방식이다. Android ViewModel에서 `viewModelScope.launch { ... }` 하는 것과 비슷하다.

```swift
let user = try await socialAuthClient.signInWithKakao()
```

카카오 인증을 진행하고, 카카오 사용자 정보를 앱 공통 모델인 `SocialAuthUser`로 받는다.

```swift
let response = try await authUseCases.login(user)
```

카카오 사용자 정보를 필사앱 서버 로그인 API로 보낸다.

```swift
await send(.socialLoginCompleted(.success(response)))
```

로그인 성공 결과를 다시 reducer action으로 보낸다. TCA에서는 비동기 작업이 끝난 뒤 직접 state를 바꾸지 않고, 다시 action을 보내 state를 변경한다.

---

## 5. SocialAuthClient는 provider 인증만 담당한다

파일:

- `Fiilsa/Core/Dependencies/SocialAuthClient.swift`

`SocialAuthClient`는 구글/카카오 인증을 담당한다.

```swift
struct SocialAuthClient {
    var signInWithGoogle: @Sendable () async throws -> SocialAuthUser
    var signInWithKakao: @Sendable () async throws -> SocialAuthUser
}
```

결과는 항상 `SocialAuthUser`다.

```swift
struct SocialAuthUser: Equatable {
    let provider: String
    let oauthID: String
    let nickname: String
    let profileImageURL: String
}
```

구글이든 카카오든 최종적으로 서버에 필요한 정보는 동일하다.

- provider: `"GOOGLE"` 또는 `"KAKAO"`
- oauthID: provider가 주는 사용자 고유 id
- nickname: 사용자 이름
- profileImageURL: 프로필 이미지

그래서 provider별 응답을 앱 내부 공통 모델로 변환한다.

---

## 6. iOS에서 OAuth 인증창을 여는 방식

iOS에서는 `ASWebAuthenticationSession`을 사용했다.

```swift
let session = ASWebAuthenticationSession(
    url: url,
    callbackURLScheme: callbackScheme
) { callbackURL, error in
    ...
}
session.start()
```

이 코드는 시스템 인증창을 연다. 사용자는 Safari 기반 화면에서 구글/카카오 로그인을 한다. 로그인이 끝나면 redirect URI를 통해 다시 앱으로 돌아온다.

Android의 AppAuth 흐름과 비교하면 다음과 같다.

```text
Android AppAuth
  -> Chrome Custom Tabs 열기
  -> redirect URI로 앱 복귀
  -> authorization code 받기

iOS ASWebAuthenticationSession
  -> Safari 인증 세션 열기
  -> callback URL scheme으로 앱 복귀
  -> authorization code 받기
```

이 흐름 때문에 iOS에서는 URL scheme 설정이 매우 중요하다. 예를 들어 redirect URI가 다음과 같다면:

```text
fillsa://oauth/google
```

앱은 `fillsa` scheme을 처리할 수 있도록 Xcode URL Types에 등록되어 있어야 한다.

---

## 7. 구글 로그인 코드 흐름

구글 로그인은 `signInWithGoogle()`에서 처리한다.

먼저 설정값을 확인한다.

```swift
guard !config.googleClientID.isEmpty,
      let redirectURI = URL(string: config.googleRedirectURI),
      let callbackScheme = redirectURI.scheme else {
    throw SocialAuthError.missingConfiguration
}
```

설정값이 없으면 `missingConfiguration` 에러가 발생한다. 이 에러는 나중에 `"소셜 로그인 설정이 필요합니다."` toast로 바뀐다.

그 다음 PKCE 값을 만든다.

```swift
let verifier = Self.codeVerifier()
let challenge = Self.codeChallenge(from: verifier)
```

PKCE는 모바일 앱 OAuth에서 authorization code를 더 안전하게 쓰기 위한 방식이다. Android AppAuth에서도 일반적으로 사용하는 흐름이다.

구글 인증 URL을 만든다.

```swift
var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
components?.queryItems = [
    URLQueryItem(name: "client_id", value: config.googleClientID),
    URLQueryItem(name: "redirect_uri", value: config.googleRedirectURI),
    URLQueryItem(name: "response_type", value: "code"),
    URLQueryItem(name: "scope", value: "openid email profile"),
    URLQueryItem(name: "code_challenge", value: challenge),
    URLQueryItem(name: "code_challenge_method", value: "S256")
]
```

인증창에서 로그인이 끝나면 callback URL이 돌아온다.

```swift
let callbackURL = try await authenticate(url: authURL, callbackScheme: callbackScheme)
let code = try authorizationCode(from: callbackURL)
```

받은 code를 token endpoint로 교환한다.

```swift
let tokenData = try await requestForm(
    url: URL(string: "https://oauth2.googleapis.com/token")!,
    items: [
        "grant_type": "authorization_code",
        "code": code,
        "client_id": config.googleClientID,
        "redirect_uri": config.googleRedirectURI,
        "code_verifier": verifier
    ]
)
```

응답에서 `id_token`을 꺼내고 JWT payload를 읽는다.

```swift
let idToken = token["id_token"] as? String
let payload = Self.jwtPayload(idToken)
```

마지막으로 필사앱 공통 사용자 모델로 바꾼다.

```swift
return SocialAuthUser(
    provider: "GOOGLE",
    oauthID: payload["sub"] as? String ?? "",
    nickname: payload["name"] as? String ?? "",
    profileImageURL: payload["picture"] as? String ?? ""
)
```

---

## 8. 카카오 로그인 코드 흐름

카카오도 기본 흐름은 구글과 같다.

먼저 카카오 인증 URL을 만든다.

```swift
var components = URLComponents(string: "https://kauth.kakao.com/oauth/authorize")
components?.queryItems = [
    URLQueryItem(name: "client_id", value: config.kakaoRestAPIKey),
    URLQueryItem(name: "redirect_uri", value: config.kakaoRedirectURI),
    URLQueryItem(name: "response_type", value: "code")
]
```

인증 후 callback URL에서 code를 꺼낸다.

```swift
let callbackURL = try await authenticate(url: authURL, callbackScheme: callbackScheme)
let code = try authorizationCode(from: callbackURL)
```

code를 카카오 token endpoint로 보낸다.

```swift
let tokenData = try await requestForm(
    url: URL(string: "https://kauth.kakao.com/oauth/token")!,
    items: [
        "grant_type": "authorization_code",
        "client_id": config.kakaoRestAPIKey,
        "redirect_uri": config.kakaoRedirectURI,
        "code": code
    ]
)
```

카카오는 구글처럼 id token payload만으로 사용자 정보를 가져오지 않고, access token으로 사용자 정보 API를 호출한다.

```swift
var request = URLRequest(url: URL(string: "https://kapi.kakao.com/v2/user/me")!)
request.httpMethod = "GET"
request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
```

응답에서 nickname, profile image를 꺼낸다.

```swift
let account = object["kakao_account"] as? [String: Any]
let profile = account?["profile"] as? [String: Any]
```

그리고 공통 모델로 바꾼다.

```swift
return SocialAuthUser(
    provider: "KAKAO",
    oauthID: object["id"].map { String(describing: $0) } ?? "",
    nickname: profile?["nickname"] as? String ?? "",
    profileImageURL: profile?["profile_image_url"] as? String ?? ""
)
```

---

## 9. AuthUseCases는 필사앱 서버 로그인 요청을 만든다

파일:

- `Fiilsa/Core/Dependencies/AuthUseCasesDependency.swift`

provider 인증이 끝나면 `SocialAuthUser`가 생긴다. 하지만 이것만으로 앱 로그인이 끝난 것은 아니다. 필사앱 서버에 로그인 요청을 보내야 한다.

그 역할을 `AuthUseCases`가 한다.

```swift
struct AuthUseCases {
    var login: @Sendable (_ user: SocialAuthUser) async throws -> LoginResponse
}
```

실제 구현은 `LoginUseCase`에 있다.

```swift
private struct LoginUseCase {
    let authRepository: AuthRepository
    let localRepository: LocalRepository

    func callAsFunction(user: SocialAuthUser) async throws -> LoginResponse {
        ...
    }
}
```

Android로 치면 `LoginUseCase.invoke(user)` 또는 `LoginViewModel.login()` 내부 로직과 비슷하다.

---

## 10. 서버 LoginRequest 구성

서버 요청은 세 부분으로 구성된다.

```swift
let request = LoginRequest(
    loginData: LoginData(
        deviceData: DeviceData(...),
        userData: UserData(...)
    ),
    syncData: localQuotes.map { ... }
)
```

### deviceData

```swift
deviceData: DeviceData(
    deviceId: DeviceIDProvider.current(),
    osType: "IOS",
    appVersion: APIAppVersionProvider.current(),
    osVersion: UIDevice.current.systemVersion,
    deviceModel: UIDevice.current.model
)
```

iOS 기기 정보를 담는다.

- `deviceId`: 앱에서 생성해 UserDefaults에 저장한 UUID
- `osType`: `"IOS"`
- `appVersion`: 앱 버전
- `osVersion`: iOS 버전
- `deviceModel`: 기기 모델

Android의 `Build.MODEL`, OS version, device id를 넣는 것과 같은 목적이다.

### userData

```swift
userData: UserData(
    oAuthProvider: user.provider,
    oAuthId: user.oauthID,
    nickname: user.nickname,
    profileImageUrl: user.profileImageURL
)
```

provider 인증으로 얻은 사용자 정보를 서버 형식에 맞게 넣는다.

### syncData

```swift
syncData: localQuotes.map {
    DailySyncData(
        dailyQuoteSeq: $0.dailyQuoteSeq,
        typingQuoteRequest: TypingQuoteRequest(
            typingKorQuote: $0.korTyping,
            typingEngQuote: $0.engTyping
        ),
        memoRequest: MemoRequest(memo: $0.memo),
        likeRequest: LikeRequest(likeYn: $0.likeYn)
    )
}
```

비회원 상태에서 로컬에 쌓인 필사, 메모, 좋아요 데이터를 서버 로그인 시 함께 동기화하기 위한 값이다.

---

## 11. 서버 API 호출과 로컬 저장

요청을 만든 뒤 서버 로그인을 호출한다.

```swift
let response = try await authRepository.login(request)
```

성공하면 서버 응답을 로컬에 저장한다.

```swift
try await SetAccessTokenUseCase(localRepository: localRepository)(response.accessToken)
try await SetRefreshTokenUseCase(localRepository: localRepository)(response.refreshToken)
try await SetUserNameUseCase(localRepository: localRepository)(response.nickname)
try await localRepository.setImageURI(response.profileImageUrl)
try await ClearLocalDataUseCase(localRepository: localRepository)()
```

이 단계가 끝나면 앱은 로그인 상태가 된다.

- access token 저장
- refresh token 저장
- username 저장
- profile image 저장
- 로컬 필사 데이터 정리

Android로 치면 DataStore/LocalStorage/TokenStore에 로그인 결과를 저장하는 부분이다.

---

## 12. Repository는 API 호출만 담당한다

파일:

- `Fiilsa/Data/Repositories/DefaultAuthRepository.swift`

```swift
struct DefaultAuthRepository: AuthRepository {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClientFactory.noToken()) {
        self.apiClient = apiClient
    }

    func login(_ requestBody: LoginRequest) async throws -> LoginResponse {
        let request = APIRequest(
            method: .post,
            path: APIEndpoint.login,
            body: requestBody,
            requiresAuthorization: false
        )
        return try await apiClient.send(request, responseType: LoginResponse.self)
    }
}
```

Repository는 OAuth 인증도 모르고, 화면 이동도 모른다. 그저 `LoginRequest`를 서버로 보내고 `LoginResponse`를 받는다.

Clean Architecture 관점에서 보면 책임 분리가 이렇게 된다.

```text
View
  화면 표시, 클릭 전달

Feature
  상태 변경, 이벤트 처리, use case 호출

UseCase
  앱 비즈니스 흐름 구성

Repository
  API 호출

APIClient
  실제 HTTP 통신
```

---

## 13. 성공하면 어떻게 Home으로 이동할까?

로그인이 성공하면 `LoginFeature`로 다시 결과 action이 들어온다.

```swift
case .socialLoginCompleted(.success):
    state.isProcessing = false
    return .send(.delegate(.moveHome))
```

여기서 직접 Home 화면을 띄우지 않는다. `LoginFeature`는 로그인 화면의 feature이기 때문에 앱 전체 화면 전환은 부모인 `AppFeature`에게 맡긴다.

그래서 `.delegate(.moveHome)`을 보낸다.

Android로 비유하면 Fragment나 Compose screen 내부에서 직접 NavController를 들고 이동할 수도 있지만, MVI 구조에서는 navigation event를 상위로 올리는 것과 비슷하다.

---

## 14. 실패하면 어떻게 처리할까?

실패는 세 종류로 나눴다.

```swift
enum LoginError: Error, Equatable {
    case missingConfiguration
    case cancelled
    case failed
}
```

### 설정 누락

```swift
case .missingConfiguration:
    state.toastMessage = "소셜 로그인 설정이 필요합니다."
```

Google client id, Kakao REST API key, redirect URI 같은 값이 없을 때다.

### 사용자가 취소

```swift
case .cancelled:
    state.toastMessage = nil
```

사용자가 인증창을 닫은 것은 에러라기보다 취소에 가깝기 때문에 toast를 띄우지 않는다.

### 일반 실패

```swift
case .failed:
    state.toastMessage = "로그인에 실패했습니다."
```

토큰 교환 실패, 사용자 정보 파싱 실패, 서버 로그인 실패 등이 여기에 해당한다.

---

## 15. 아직 필요한 iOS 설정

현재 코드는 로그인 흐름을 연결해 둔 상태다. 하지만 실제 provider 로그인을 완료하려면 iOS 앱 설정이 필요하다.

필요한 값은 다음과 같다.

- `GOOGLE_CLIENT_ID`
- `GOOGLE_REDIRECT_URI`
- `KAKAO_REST_API_KEY`
- `KAKAO_REDIRECT_URI`
- Xcode URL Types callback scheme

이 값들은 `AuthConfig`가 읽는다.

```swift
struct AuthConfig: Equatable {
    let googleClientID: String
    let googleRedirectURI: String
    let kakaoRestAPIKey: String
    let kakaoRedirectURI: String
}
```

앱 설정에 값이 없으면 `SocialAuthError.missingConfiguration`이 발생한다.

---

## 16. 왜 이렇게 나눴을까?

한 파일에서 전부 처리할 수도 있다. 예를 들어 `LoginView`에서 카카오 인증, 서버 로그인, 토큰 저장까지 모두 할 수도 있다.

하지만 그렇게 하면 문제가 생긴다.

- 화면 코드가 너무 커진다.
- 테스트하기 어렵다.
- 구글/카카오 인증 방식을 바꿀 때 화면 코드까지 흔들린다.
- 서버 로그인 API 변경과 UI 변경이 강하게 엮인다.

그래서 역할을 나눴다.

```text
LoginView
  "버튼이 눌렸다"만 전달

LoginFeature
  "로그인을 시작하고 결과에 따라 상태를 바꾼다"

SocialAuthClient
  "provider 인증만 담당한다"

AuthUseCases
  "필사앱 서버 로그인 흐름을 담당한다"

DefaultAuthRepository
  "서버 API 호출만 담당한다"
```

이 구조는 Android의 MVI + Clean Architecture와 같은 방향이다.

---

## 17. 처음 읽을 때 추천 순서

코드를 처음 읽는다면 아래 순서로 보는 것이 좋다.

1. `LoginView.swift`
   - 버튼이 어떤 action을 보내는지 본다.

2. `LoginFeature.swift`
   - action이 어떤 비동기 작업을 실행하는지 본다.

3. `SocialAuthClient.swift`
   - 구글/카카오 인증이 어떻게 `SocialAuthUser`로 바뀌는지 본다.

4. `AuthUseCasesDependency.swift`
   - `SocialAuthUser`가 서버 `LoginRequest`로 어떻게 바뀌는지 본다.

5. `DefaultAuthRepository.swift`
   - 실제 API 호출이 어디서 일어나는지 본다.

이 순서대로 보면 화면 클릭부터 서버 로그인 완료까지 한 줄로 이어진다.

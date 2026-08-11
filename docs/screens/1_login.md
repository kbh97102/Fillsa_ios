# [온보딩/로그인 페이지] `1.login`

온보딩 로그인(첫 진입)과 이후 재로그인 화면 두 가지로 구분된다.

카카오 버튼은 Android와 동일하게 카카오톡 앱 로그인을 시작한다. 카카오톡이 설치되지 않은 기기에서는 `카카오톡 설치 후 이용해주세요.` 안내 다이얼로그를 표시하고, 카카오계정 브라우저 로그인으로 대체하지 않는다.

---

## 온보딩 로그인 (첫 진입)

### 버튼

| 버튼 | 동작 |
|------|------|
| 카카오 간편 로그인 | 카카오톡 SDK 로그인 후 서버 로그인. 카카오톡 미설치 시 `카카오톡 설치 후 이용해주세요.` 안내 다이얼로그 표시 |
| Apple로 시작하기 | Apple 로그인 진행 |
| 비회원으로 시작하기 | 비회원 상태로 Home 이동 |

### 문구

- "로그인 후, 나만의 필사를 안전하게 저장할 수 있습니다."
- "로그인 시, [이용약관](https://home.fillsa.store/7vgjr4m1n5gkk2dwpy86) 및 [개인정보 처리방침](https://home.fillsa.store/3p4kj92yn5qwkm57q1x8)에 동의하는 것으로 간주됩니다."
  - 이용약관 / 개인정보 처리방침 클릭 시 해당 노션 페이지로 이동

---

## 재로그인 화면 (로그인 페이지 진입 시)

### 버튼

| 버튼 | 동작 |
|------|------|
| 카카오 간편 로그인 | 카카오톡 SDK 로그인 후 서버 로그인. 카카오톡 미설치 시 `카카오톡 설치 후 이용해주세요.` 안내 다이얼로그 표시 |
| Apple로 시작하기 | Apple 로그인 진행 |
| X (닫기) | 현재 화면에서 벗어남 |

### 문구

- "로그인 후, 나만의 필사를 안전하게 저장할 수 있습니다."
- "로그인 시, [이용약관](https://home.fillsa.store/7vgjr4m1n5gkk2dwpy86) 및 [개인정보 처리방침](https://home.fillsa.store/3p4kj92yn5qwkm57q1x8)에 동의하는 것으로 간주됩니다."
  - 이용약관 / 개인정보 처리방침 클릭 시 해당 노션 페이지로 이동

---

## 모달

### `modal_login` — 비회원 사진 업로드 접근 시

> "로그인을 통해 사진 업로드 기능을 누려보세요!"

| 버튼 | 동작 |
|------|------|
| 로그인 하러가기 | 로그인 페이지로 이동 |
| 취소 | 모달 닫기 |

---

## API

### 로그인

```
POST /api/v1/auth/login
```

**Request Body: `LoginRequest`**

| 필드 | 타입 | 설명 |
|------|------|------|
| (Firebase/Kakao SDK 토큰 등 소셜 인증 정보) | — | 소셜 로그인 후 서버 인증 |

**Response: `LoginResponse`**

#### Apple 로그인 요청값

- `loginData.userData.oAuthProvider`: `"APPLE"`
- `loginData.userData.oAuthId`: `ASAuthorizationAppleIDCredential.user` (`sub`)
- `loginData.deviceData.osType`: `"IOS"`
- `loginData.userData.nickname`: Apple이 최초 인증에서 제공한 `fullName`으로 만든 표시 이름
- Apple은 이름을 최초 동의 시 한 번만 제공하므로, 재로그인에서 `fullName`이 없으면 빈 nickname을 보내고 서버의 기존 회원정보를 사용한다.
- Apple은 프로필 이미지를 제공하지 않으므로 `profileImageUrl`은 빈 문자열을 보낸다.
- FCM 토큰을 이미 받을 수 있으면 `deviceData.pushToken`, `deviceData.pushAgreed`를 함께 보낸다. 토큰이 아직 없으면 두 필드는 생략하고, 토큰 발급 뒤 별도 푸시 기기 등록 API로 보정한다.

### iOS 전환 결정

- Android 원본은 Google/Kakao 로그인을 제공하지만, iOS 앱에서는 Google 로그인을 제거하고 Apple/Kakao 로그인으로 구성한다.
- Apple 로그인은 `AuthenticationServices`의 `ASAuthorizationAppleIDProvider`를 사용한다.
- Apple 로그인 결과의 `credential.user`를 서버 로그인 요청의 `oAuthId`로 전달하고, provider 값은 `"APPLE"`을 사용한다.
- Apple 인증 성공 후 카카오와 동일하게 `POST /api/v1/auth/login`을 호출하고, 응답의 access/refresh token과 사용자 정보를 로컬에 저장한다.
- Apple 로그인은 앱의 entitlements와 Apple Developer App ID capability에서 `Sign in with Apple`이 활성화되어야 한다.
- 카카오 로그인은 `KakaoSDKUser`로 카카오톡 앱 인증을 수행한다. 인증 후 카카오 사용자 ID, 닉네임, 프로필 이미지 URL을 provider `"KAKAO"`와 함께 기존 로그인 API에 보낸다.
- 사용자가 카카오 인증을 취소하면 로그인 화면에 남는다. 카카오톡 미설치와 일반 인증 실패는 각각 설치 안내 다이얼로그와 `"로그인에 실패했습니다."` toast로 표시한다.

### 토큰 갱신 (인터셉터 자동 처리)

```
POST /api/v1/auth/refresh
```

**Request Body: `TokenRefreshRequest`**  
**Response: `TokenInfo`**

- 401/403 응답 수신 시 자동 토큰 갱신 후 재시도

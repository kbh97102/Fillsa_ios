# [온보딩/로그인 페이지] `1.login`

온보딩 로그인(첫 진입)과 이후 재로그인 화면 두 가지로 구분된다.

카카오 버튼은 Android와 동일하게 카카오톡 앱 로그인을 시작한다. 카카오톡이 설치되지 않은 기기에서는 `카카오톡 설치 후 이용해주세요.` 안내 다이얼로그를 표시하고, 카카오계정 브라우저 로그인으로 대체하지 않는다.

## iOS 회원 전용 진입과 로그아웃 — 1차 구현 완료 (2026-10-09)

- 수정 순서와 테스트: [회원 전용 시작 및 로그아웃 구현 계획](1_login_member_only_implementation_plan.md)
- 실행 결과와 캡처: [회원 전용 시작 및 로그아웃 QA](1_login_member_only_qa_2026-10-09.md)
- 이번 화면 이동 변경은 2026-10-09 사용자 요청에 따라 Figma 대조 없이 진행한다.
- iOS는 로그인한 회원만 Home에 진입한다. 스플래시에서 **첫 실행 여부와 로그인 여부를 모두 확인**하고, 결과별 이동은 [랜딩/스플래시 계획](0_onboarding.md)에 따른다.
- My Page에서 로그아웃하면 로컬 세션 정리 후 **항상 로그인 화면으로 이동**한다. My Page를 비회원 상태로 다시 보여주지 않는다.
- 로그아웃 완료는 `MyPageFeature`가 상위 `AppFeature`에 전달하고, `AppFeature`가 로그인 화면 전환과 회원 화면 상태 정리를 담당한다. 이는 Android의 ViewModel/MVI 이벤트를 상위 내비게이션에서 처리하는 방식에 해당한다.
- 로그아웃 요청을 UserDefaults에 먼저 기록하고 Keychain 토큰을 정리한다. 토큰 삭제가 실패해도 남은 토큰만으로 Home에 진입할 수 없으며, 정상 로그인 후 차단 표시를 해제한다.
- 수용 조건: 로그아웃 직후 로그인 화면 표시, 로그아웃 후 앱 재시작 시 로그인 화면 표시, 로그인된 상태로 재시작 시 Home 표시, 첫 실행에서 미로그인 상태일 때 로그인 화면 표시.
- 스플래시 분기, 로그아웃 후 이동, 재시작 시 세션 판정은 구현됐다. 로그아웃 버튼 행 전체를 탭할 수 있도록 터치 영역도 지정했다.
- 로그인 화면의 닫기 동작, 세션 만료, 회원 탈퇴, 남아 있는 비회원 전용 경로가 회원 전용 원칙과 충돌하는지 후속 검토한다. 해당 동작의 변경 범위는 별도로 정한다.

---

## 온보딩 로그인 (첫 진입)

### 버튼

| 버튼 | 동작 |
|------|------|
| 카카오 간편 로그인 | 카카오톡 SDK 로그인 후 서버 로그인. 카카오톡 미설치 시 `카카오톡 설치 후 이용해주세요.` 안내 다이얼로그 표시 |
| Apple로 시작하기 | Apple 로그인 진행 |

2026-10-09: iOS 로그인 화면의 비회원 시작 버튼은 사용자 요청으로 제거한다. 이번 변경은 버튼 표시만 대상으로 하며 Figma 대조는 사용자 요청에 따라 생략한다.

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

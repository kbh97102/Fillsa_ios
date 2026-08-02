# 미완성 기능 추적

이 문서는 iOS 전환 앱에서 아직 Android parity 기준으로 완성되지 않은 기능을 추적한다.  
화면별 상세 동작은 `docs/screens/` 문서를 기준으로 하고, 여기서는 남은 구현 단위와 우선순위만 관리한다.

## 우선순위 요약

| 우선순위 | 영역 | 상태 | 이유 |
|----------|------|------|------|
| P0 | 소셜 로그인 | 부분 구현 | Apple 로그인 앱 설정은 연결됨. Kakao provider 콘솔 키 등록/실기기 검증 필요 |
| P0 | 공유 화면 저장/공유 | 부분 구현 | 카카오 SDK 템플릿 공유 여부만 결정 필요 |
| P1 | 알림 설정/예약 | 부분 구현 | 로컬 알림 예약/해제는 구현됨. 오늘 명언 본문 동적 구성은 남음 |
| P1 | 회원 탈퇴 | 미구현 | Android 회원 전용 기능 parity 필요 |
| P1 | 전역 토큰 만료/에러 처리 | 부분 구현 | 저장소/인터셉터는 있으나 화면 반영 구조가 부족함 |
| P2 | 팝업 API 노출 | 미구현 | repository는 있으나 UI 표시 흐름이 없음 |
| P2 | 테마 dark 디자인 parity | 부분 구현 | 주요 색상 토큰/핵심 화면은 대응됨. 전체 화면 육안 비교 필요 |

---

## P0. 소셜 로그인

관련 문서:

- `docs/screens/1_login.md`
- `docs/social-login-implementation.md`
- `docs/apple-login-release-checklist.md`
- `docs/testflight-distribution-guide.md`

현재 상태:

- `LoginView`는 `LoginFeature`와 연결되어 카카오/Apple/비회원 버튼 action을 처리한다.
- `SocialAuthClient`가 카카오는 `ASWebAuthenticationSession`, Apple은 `ASAuthorizationAppleIDProvider` 기반 인증창을 연다.
- `DefaultAuthRepository`가 서버 로그인/토큰 갱신 API와 연결되어 있다.
- `AuthUseCases`가 Android `LoginViewModel.login()`처럼 deviceData, userData, syncData를 구성한다.
- 로그인 성공 후 access token, refresh token, userName, profileImage를 로컬 저장소에 저장하고 로컬 필사 데이터를 정리한다.
- 로그인 성공 후 Home으로 이동한다.
- OAuth 설정값이 없으면 `"소셜 로그인 설정이 필요합니다."` toast를 표시한다.
- `Fiilsa/Info.plist`에 Kakao OAuth callback scheme `fillsa`가 등록되어 있다.
- Kakao 기본 redirect URI는 `fillsa://oauth/kakao`로 연결되어 있다.
- `Fiilsa/Fiilsa.entitlements`에 Sign in with Apple entitlement가 연결되어 있다.

남은 작업:

- [x] 카카오 로그인 SDK 연동 또는 iOS용 인증 흐름 결정
- [x] Apple 로그인 인증 흐름 구현
- [x] `DefaultAuthRepository` 구현
- [x] 로그인 request/response를 서버 API와 연결
- [x] 성공 시 Keychain에 access/refresh token 저장
- [x] 성공 시 UserDefaults에 userName/profileImage 저장
- [x] 로그인 성공 후 Home 이동
- [x] 실패/취소 상태 처리
- [ ] iOS용 Kakao REST API key 준비
- [x] Xcode URL Types에 OAuth callback scheme 등록
- [x] iOS 앱 build setting과 Info.plist OAuth 설정 연결
- [x] Sign in with Apple entitlement 연결
- [ ] Apple Developer App ID에서 Sign in with Apple capability 활성화 확인
- [ ] 서버 `APPLE` provider 허용 및 identity token 검증 방식 결정
- [ ] TestFlight 실기기 빌드에서 Apple 로그인 검증
- [ ] 실제 provider 콘솔 설정 후 실기기/시뮬레이터 로그인 검증
- [ ] 카카오톡 앱 직접 로그인 SDK가 필요한지 결정

검증 기준:

- 앱 첫 진입 로그인 화면에서 소셜 로그인 성공 시 Home으로 이동한다.
- 마이페이지에서 회원 정보가 표시된다.
- 앱 재실행 후 로그인 상태가 유지된다.

---

## P0. 공유 화면 저장/공유

관련 문서:

- `docs/screens/2_home.md`의 `2-4.img_share`
- Android reference:
  - `/Users/gangbohun/AndroidStudioProjects/Fillsa/presentation/src/main/java/com/arakene/presentation/ui/home/ShareView.kt`
  - `/Users/gangbohun/AndroidStudioProjects/Fillsa/presentation/viewmodel/ShareViewModel.kt`

현재 상태:

- Home/Typing에서 공유 화면으로 이동한다.
- quote/author 전달은 된다.
- 제목/부제, paging 카드, 복사 버튼이 존재한다.
- 저장 버튼은 선택된 공유 카드를 이미지로 렌더링해 사진 앱에 저장한다.
- 카카오톡 버튼은 현재 Android 구현과 동일하게 일반 이미지 공유 시트를 띄운다.
- 첫 진입 가이드 오버레이는 로컬 `SHARE_DESCRIPTION` 값과 연결되어 있다.
- Android drawable 배경은 SwiftUI gradient/stripe로 재현되어 있다.

남은 작업:

- [x] Android 공유 배경 drawable 8개를 iOS에서 gradient/stripe로 재현
- [x] `ShareFeature` 추가
- [x] 첫 진입 가이드 표시 여부를 `SHARE_DESCRIPTION` 로컬 값과 연결
- [x] 선택된 공유 카드를 이미지로 렌더링
- [x] 저장 버튼: 이미지 생성 후 사진 앱 저장
- [x] 공유 버튼 또는 카카오톡 버튼: 우선 `UIActivityViewController`로 이미지 공유
- [ ] 카카오 SDK 템플릿 공유 여부 결정
- [x] 저장/복사 결과 toast 표시
- [x] 사진 저장 권한 문구 `NSPhotoLibraryAddUsageDescription` 추가

검증 기준:

- 선택한 카드 배경/문구 그대로 이미지가 저장된다.
- 복사 버튼은 Android처럼 `"{quote} - {author}"` 텍스트를 복사한다.
- 공유 버튼은 iOS 공유 시트를 띄운다.
- 첫 진입 가이드는 한 번 닫으면 다시 뜨지 않는다.

남은 결정:

- 카카오 SDK 템플릿 공유는 로그인 SDK 결정 이후 함께 판단한다.

---

## P1. 알림 설정/예약

관련 문서:

- `docs/screens/5_2_inform.md`

현재 상태:

- Splash에서 알림 권한 요청 여부를 한 번 체크하고, 허용 상태면 오전 9시 알림 예약을 보정한다.
- `AlertFeature`가 토글 상태 로드, 권한 확인/요청, 알림 예약/해제, toast 안내를 처리한다.
- `AlertView`는 TCA store 기반으로 동작한다.
- 알림 ON/OFF 값은 `SettingsClient`를 통해 로컬 저장소에 유지된다.

남은 작업:

- [x] `AlertFeature` 추가
- [x] 알림 토글 상태를 `SettingsClient`와 연결
- [x] 토글 ON 시 권한 상태 확인
- [x] 권한 미결정이면 권한 요청
- [x] 권한 허용 시 오전 9시 로컬 알림 예약
- [x] 토글 OFF 시 예약 알림 취소
- [x] 권한 거절 상태 최소 안내
- [ ] 설정 앱 이동 방식 결정
- [ ] 오늘의 명언 문구를 알림 본문에 동적으로 구성하는 방식 결정

검증 기준:

- 알림 ON/OFF가 앱 재실행 후 유지된다.
- ON 상태에서 로컬 알림이 예약된다.
- OFF 상태에서 예약 알림이 제거된다.
- 현재 iOS 알림 본문은 고정 문구다. Android처럼 당일 명언을 넣으려면 별도 백그라운드 갱신 또는 서버 푸시 설계가 필요하다.

---

## P1. 회원 탈퇴

관련 문서:

- `docs/screens/5_2_inform.md`

현재 상태:

- `CommonRepository.deleteResign()` 구현은 있다.
- `AlertFeature`가 로그인 상태를 조회한다.
- 회원일 때만 탈퇴 버튼을 노출한다.
- 탈퇴 버튼 클릭 시 Android 문구 기준 확인 모달을 표시한다.
- 확인 시 `deleteResign()` 호출 후 로컬 세션과 사용자 정보를 삭제하고 Home으로 이동한다.

남은 작업:

- [x] 알림 화면에서 로그인 상태 조회
- [x] 회원일 때만 탈퇴 버튼 노출
- [x] 탈퇴 확인 모달 구현
- [x] 확인 시 `deleteResign()` 호출
- [x] 성공 시 로컬 토큰/사용자 정보 삭제
- [x] Home으로 이동
- [x] 실패 상태 toast/alert 처리

검증 기준:

- 비회원에게 탈퇴 버튼이 보이지 않는다.
- 회원이 탈퇴 성공 후 비회원 상태로 전환된다.

---

## P1. 전역 토큰 만료/에러 처리

관련 문서:

- `docs/android-analysis.md`
- `docs/ios-development-plan.md`
- `docs/session-expiration-flow.md`

현재 상태:

- `FillsaRequestInterceptor`가 인증 요청에 bearer token을 주입한다.
- `401`/`403` 수신 시 원 요청당 한 번만 refresh token 갱신을 시도한다.
- refresh token이 없거나 갱신에 실패하거나 재시도 후에도 인증 실패가 유지되면 `SessionExpirationEvent`를 발행한다.
- `AppFeature`가 세션 만료 이벤트를 구독하고 `SessionClient.logout()` 후 Home/MyPage/List/Calendar state를 비회원 기준으로 재생성한다.

남은 작업:

- [x] 토큰 갱신 실패 시 공통 action으로 AppFeature에 전달
- [x] 로그인 만료 시 로컬 세션 삭제
- [x] 로그인 화면 또는 Home 비회원 상태로 이동
- [ ] Android `WithBaseErrorHandling`의 전체 에러 코드별 toast/alert 정책 정리

검증 기준:

- 만료된 refresh token으로 API 호출 시 앱이 무한 retry하지 않는다.
- 세션 만료 후 회원 UI가 비회원 UI로 전환된다.

---

## P2. 팝업 API 노출

관련 문서:

- `docs/screens/5_mypage.md`

현재 상태:

- `CommonRepository.getPopupGeneral()` 구현은 있다.
- `CommonRepository.getPopupVersionUpdate(currentVersion:)` 구현은 있다.
- `GeneralPopupFeature`가 main/Home/MyPage 진입 시 한 번 팝업 API를 조회한다.
- 팝업 큐는 Android 우선순위와 동일하게 `VERSION_UPDATE` → `NOTICE` → `EVENT` 순서로 표시한다.
- `GeneralPopupView`가 이미지 전용 팝업과 제목/내용 팝업을 표시한다.
- `오늘 보지 않기`는 `HiddenPopupClient.add`로 저장한다.
- 앱에서 팝업 조회 전에 날짜가 바뀌었으면 hidden popup 목록을 비운다.

남은 작업:

- [x] Android 팝업 표시 위치와 조건 재확인
- [x] 버전 업데이트 팝업 표시 흐름 구현
- [x] 일반 팝업 표시 흐름 구현
- [x] 오늘 보지 않기/숨김 처리와 `HiddenPopupClient` 연결
- [ ] 실제 API 응답 데이터로 이미지/텍스트 팝업 QA
- [ ] Android에서 주석 처리된 `getPopupGeneral()` 호출을 제품 기준으로 다시 확인

검증 기준:

- API 응답에 따라 팝업이 표시된다.
- 숨긴 팝업은 다시 표시되지 않는다.

---

## P2. 테마 dark 디자인 parity

관련 문서:

- `docs/screens/5_3_theme.md`

현재 상태:

- 마이페이지에서 테마 선택/저장은 연결되어 있다.
- AppView에 `preferredColorScheme` 적용은 되어 있다.
- `FillsaColor`에 Android `FillsaColorScheme` 기준 의미 토큰이 추가되어 있다.
- Splash/Home/List/Calendar/MyPage의 주요 배경, 컨테이너, 본문 텍스트는 light/dark 토큰을 사용한다.

남은 작업:

- [x] Android dark color token 확인
- [x] iOS `FillsaColor`를 light/dark 대응 구조로 정리
- [x] Splash/Home/List/Calendar/MyPage 주요 색상 토큰 적용
- [ ] Splash/Home/List/Calendar/MyPage dark 화면 육안 비교
- [ ] 팝업/상세/서브 화면까지 dark 색상 확대 적용 여부 결정

검증 기준:

- Android dark mode와 iOS dark mode의 주요 화면 색상이 일치한다.

---

## 낮은 우선순위 또는 보류

- 위젯 제공: Android 기능 목록에는 있으나 현재 iOS 전환 범위에서 별도 Widget Extension 계획이 없다.
- 카카오 SDK 템플릿 공유: 로그인 SDK 결정 이후 함께 판단하는 편이 효율적이다.
- 하단 광고 영역: `docs/screens/common.md` 기준 V2 항목으로 분리되어 있다.

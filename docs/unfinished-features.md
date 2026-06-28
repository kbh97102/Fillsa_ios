# 미완성 기능 추적

이 문서는 iOS 전환 앱에서 아직 Android parity 기준으로 완성되지 않은 기능을 추적한다.  
화면별 상세 동작은 `docs/screens/` 문서를 기준으로 하고, 여기서는 남은 구현 단위와 우선순위만 관리한다.

## 우선순위 요약

| 우선순위 | 영역 | 상태 | 이유 |
|----------|------|------|------|
| P0 | 소셜 로그인 | 미구현 | 회원 기능 검증의 전제 조건 |
| P0 | 공유 화면 저장/공유 | 부분 구현 | 현재 사용자 버튼 중 일부가 동작하지 않음 |
| P1 | 알림 설정/예약 | 부분 구현 | 토글 저장은 있으나 실제 알림 예약 흐름이 없음 |
| P1 | 회원 탈퇴 | 미구현 | Android 회원 전용 기능 parity 필요 |
| P1 | 전역 토큰 만료/에러 처리 | 부분 구현 | 저장소/인터셉터는 있으나 화면 반영 구조가 부족함 |
| P2 | 팝업 API 노출 | 미구현 | repository는 있으나 UI 표시 흐름이 없음 |
| P2 | 테마 dark 디자인 parity | 부분 구현 | color scheme은 적용되나 색상 토큰 대부분이 고정값 |

---

## P0. 소셜 로그인

관련 문서:

- `docs/screens/1_login.md`

현재 상태:

- `LoginView` UI는 존재한다.
- 카카오/구글 버튼의 action이 비어 있다.
- `AuthRepository` 프로토콜은 존재한다.
- `DefaultAuthRepository` 구현은 없다.
- 로그인 성공 후 access token, refresh token, userName, profileImage 저장 흐름이 연결되어 있지 않다.

남은 작업:

- [ ] 카카오 로그인 SDK 연동 또는 iOS용 인증 흐름 결정
- [ ] 구글 로그인 SDK 연동 또는 iOS용 인증 흐름 결정
- [ ] `DefaultAuthRepository` 구현
- [ ] 로그인 request/response를 서버 API와 연결
- [ ] 성공 시 Keychain에 access/refresh token 저장
- [ ] 성공 시 UserDefaults에 userName/profileImage 저장
- [ ] 로그인 성공 후 Home 이동
- [ ] 실패/취소/카카오톡 미설치 상태 처리

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

- Splash에서 알림 권한 요청 여부를 한 번 체크한다.
- `AlertView`는 `@AppStorage("alarm_key")`로 토글 값을 저장한다.
- 실제 오전 9시 로컬 알림 예약/해제 로직은 없다.
- 알림 화면은 TCA Feature로 분리되어 있지 않다.

남은 작업:

- [ ] `AlertFeature` 추가
- [ ] 알림 토글 상태를 `SettingsClient`와 연결
- [ ] 토글 ON 시 권한 상태 확인
- [ ] 권한 미결정이면 권한 요청
- [ ] 권한 허용 시 오전 9시 로컬 알림 예약
- [ ] 토글 OFF 시 예약 알림 취소
- [ ] 권한 거절 상태 안내 및 설정 앱 이동 방식 결정
- [ ] 오늘의 명언 문구로 알림 내용 구성 가능 여부 확인

검증 기준:

- 알림 ON/OFF가 앱 재실행 후 유지된다.
- ON 상태에서 로컬 알림이 예약된다.
- OFF 상태에서 예약 알림이 제거된다.

---

## P1. 회원 탈퇴

관련 문서:

- `docs/screens/5_2_inform.md`

현재 상태:

- `CommonRepository.deleteResign()` 구현은 있다.
- `AlertView`의 `isLogged`는 로컬 `@State false`라 실제 로그인 상태와 연결되어 있지 않다.
- 탈퇴 버튼 action이 비어 있다.
- 탈퇴 확인 모달이 없다.

남은 작업:

- [ ] 알림 화면에서 로그인 상태 조회
- [ ] 회원일 때만 탈퇴 버튼 노출
- [ ] 탈퇴 확인 모달 구현
- [ ] 확인 시 `deleteResign()` 호출
- [ ] 성공 시 로컬 토큰/사용자 정보 삭제
- [ ] Home으로 이동
- [ ] 실패 상태 toast/alert 처리

검증 기준:

- 비회원에게 탈퇴 버튼이 보이지 않는다.
- 회원이 탈퇴 성공 후 비회원 상태로 전환된다.

---

## P1. 전역 토큰 만료/에러 처리

관련 문서:

- `docs/android-analysis.md`
- `docs/ios-development-plan.md`

현재 상태:

- `FillsaRequestInterceptor`와 token expired 저장소는 존재한다.
- Android의 `WithBaseErrorHandling`처럼 화면 공통 에러/로그아웃 처리를 담당하는 iOS 흐름은 아직 약하다.

남은 작업:

- [ ] 토큰 갱신 실패 시 공통 action으로 AppFeature에 전달
- [ ] 로그인 만료 시 로컬 세션 삭제
- [ ] 로그인 화면 또는 Home 비회원 상태로 이동
- [ ] 공통 API 실패 toast/alert 정책 정리

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
- 실제 앱 시작/Home 진입 시 팝업을 표시하는 UI 흐름은 없다.
- 숨김 팝업 저장소는 존재한다.

남은 작업:

- [ ] Android 팝업 표시 위치와 조건 재확인
- [ ] 버전 업데이트 팝업 표시 흐름 구현
- [ ] 일반 팝업 표시 흐름 구현
- [ ] 오늘 보지 않기/숨김 처리와 `HiddenPopupClient` 연결

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
- 다만 `FillsaColor`의 주요 색상은 고정값이라 Android dark theme과 완전 동일하지 않을 수 있다.

남은 작업:

- [ ] Android dark color token 확인
- [ ] iOS `FillsaColor`를 light/dark 대응 구조로 정리
- [ ] Splash/Home/List/Calendar/MyPage dark 화면 비교

검증 기준:

- Android dark mode와 iOS dark mode의 주요 화면 색상이 일치한다.

---

## 낮은 우선순위 또는 보류

- 위젯 제공: Android 기능 목록에는 있으나 현재 iOS 전환 범위에서 별도 Widget Extension 계획이 없다.
- 카카오 SDK 템플릿 공유: 로그인 SDK 결정 이후 함께 판단하는 편이 효율적이다.
- 하단 광고 영역: `docs/screens/common.md` 기준 V2 항목으로 분리되어 있다.

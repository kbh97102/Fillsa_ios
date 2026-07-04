# Wave 1 병렬 구현 계획 및 검증 기록

이 문서는 알림 설정/예약, 전역 토큰 만료 처리, 팝업 API 노출, dark theme parity 작업의 목표와 구현 계획, 사용 기술 선택 이유, 검증 결과를 정리한다.

## 1. 작업 목표

Wave 1의 목표는 Android parity 기준으로 남아 있던 독립 기능들을 병렬로 처리하는 것이다.

대상 기능:

- 알림 설정/예약
- 전역 토큰 만료/에러 처리
- 팝업 API 노출
- Dark theme parity

회원 탈퇴, 소셜 로그인 provider 콘솔 설정, 카카오 SDK 템플릿 공유는 이번 Wave 1 범위에서 제외했다. 회원 탈퇴는 알림 화면과 파일 충돌 가능성이 높고, 소셜 로그인/카카오 공유는 외부 provider 설정과 기획 결정이 필요하기 때문이다.

## 2. 병렬 작업 전략

각 작업은 서로 다른 책임 영역을 갖도록 분리했다.

| 작업 | 주 소유 영역 | 충돌 위험 |
|------|--------------|-----------|
| 알림 설정/예약 | `AlertFeature`, `AlertView`, `NotificationPermissionClient`, Splash 보정 | `AppFeature`, `AppView` |
| 토큰 만료 처리 | `FillsaRequestInterceptor`, session expiration event/client, App root 처리 | `AppFeature`, `AppView` |
| 팝업 API 노출 | `GeneralPopupFeature`, `GeneralPopupView`, `HiddenPopupClient` | `AppFeature`, `AppView`, docs |
| Dark theme parity | `FillsaColor`, 주요 화면 색상 토큰 | 낮음 |

`AppFeature`, `AppView`, `docs/unfinished-features.md`는 여러 작업에서 동시에 변경될 수 있으므로 최종 통합 시 메인에서 직접 검토했다.

## 3. 사용 기술과 선택 이유

### TCA

사용 위치:

- `AlertFeature`
- `GeneralPopupFeature`
- `AppFeature` session expiration 구독

선택 이유:

- 이 프로젝트의 iOS 아키텍처 기준이 TCA 스타일 MVI다.
- Android의 ViewModel/MVI state/event 구조와 가장 가깝다.
- 화면 상태, 사용자 액션, 비동기 effect를 한 곳에서 추적할 수 있다.
- `@Dependency`를 사용하면 테스트용 client 교체가 쉽다.

대안:

- SwiftUI `@State`, `@AppStorage`만 사용
- ObservableObject ViewModel 사용
- UIKit coordinator 기반 상태 관리

선택하지 않은 이유:

- `@State`/`@AppStorage`만 사용하면 화면 안에 권한 요청, API 호출, 저장 로직이 섞인다.
- ObservableObject도 가능하지만 현재 앱의 다른 화면 구조와 맞지 않는다.
- UIKit coordinator는 SwiftUI/TCA 기반 프로젝트에 과한 구조다.

### UserNotifications

사용 위치:

- `NotificationPermissionClient`
- `SplashFeature`
- `AlertFeature`

선택 이유:

- iOS 로컬 알림 권한 확인, 권한 요청, 예약, 취소를 담당하는 Apple 기본 프레임워크다.
- 매일 오전 9시 반복 알림은 `UNCalendarNotificationTrigger`로 구현할 수 있다.
- 별도 외부 라이브러리가 필요 없다.

대안:

- 서버 push notification
- `BGTaskScheduler`로 백그라운드 갱신 후 알림 예약
- 외부 notification wrapper 라이브러리

선택하지 않은 이유:

- 서버 push는 APNs 서버 연동과 토큰 관리가 필요해 범위가 커진다.
- `BGTaskScheduler`는 실행 시점이 보장되지 않아 매일 9시 알림 목적에 맞지 않는다.
- 외부 wrapper는 현재 필요한 기능 대비 이득이 작다.

제약:

- Android WorkManager처럼 알림 시점에 네트워크로 오늘의 명언을 가져오는 구조는 iOS 로컬 반복 알림만으로는 어렵다. 현재 본문은 고정 문구다.

### Alamofire RequestInterceptor

사용 위치:

- `FillsaRequestInterceptor`

선택 이유:

- 프로젝트의 API 계층이 이미 Alamofire 기반이다.
- Alamofire의 `RequestInterceptor`는 request adapt와 retry를 한 곳에서 처리한다.
- access token 주입, 401/403 refresh retry, retry 실패 이벤트 발행을 같은 계층에서 다룰 수 있다.

대안:

- 각 repository/use case에서 401/403 직접 처리
- APIClient 내부에서 모든 에러를 직접 분기
- URLSession 기반 자체 interceptor 구현

선택하지 않은 이유:

- repository마다 처리하면 중복이 커지고 누락 위험이 있다.
- APIClient에 모두 넣으면 인증 처리와 HTTP 송수신 책임이 섞인다.
- URLSession 자체 구현은 기존 Alamofire 구조를 버리는 큰 변경이다.

### NotificationCenter + AsyncStream

사용 위치:

- `SessionExpirationEventCenter`
- `SessionExpirationClient`
- `AppFeature.task`

선택 이유:

- Data/API 계층은 TCA를 직접 import하지 않는 편이 좋다.
- interceptor에서 발생한 세션 만료 이벤트를 앱 루트 `AppFeature`까지 올려야 한다.
- `NotificationCenter`는 계층 간 직접 의존을 줄이는 기본 이벤트 전달 수단이다.
- `AsyncStream`으로 감싸면 TCA `.run` effect에서 `for await`로 자연스럽게 구독할 수 있다.

대안:

- interceptor가 직접 `AppFeature.Action`을 호출
- singleton 상태 저장 후 주기적 polling
- Combine `PassthroughSubject`

선택하지 않은 이유:

- Data 계층이 App/TCA action을 알면 Clean Architecture 경계가 깨진다.
- polling은 반응이 늦고 불필요한 작업이 생긴다.
- Combine도 가능하지만 현재 코드가 Swift concurrency 중심이라 `AsyncStream`이 더 단순하다.

### SwiftUI Dynamic Color

사용 위치:

- `FillsaColor.dynamic(light:dark:)`

선택 이유:

- Android의 `FillsaColorScheme`처럼 의미 기반 색상 토큰을 만들 수 있다.
- `UIColor { traitCollection in ... }`를 통해 light/dark mode에 자동 대응한다.
- 기존 SwiftUI `Color` 사용 패턴을 크게 바꾸지 않는다.

대안:

- asset catalog color set 사용
- 화면마다 `@Environment(\.colorScheme)`로 직접 분기
- 다크 모드 전용 별도 theme 객체 생성

선택하지 않은 이유:

- asset catalog는 관리에는 좋지만 현재 코드의 정적 `FillsaColor` 구조와 연결 작업이 더 크다.
- 화면마다 분기하면 중복이 많고 누락 위험이 높다.
- 별도 theme 객체는 앱 전체 구조 변경이 커진다.

## 4. 세부 구현 계획과 결과

### 4.1 알림 설정/예약

목표:

- 알림 토글 상태를 로컬 저장소와 연결한다.
- 토글 ON 시 권한 확인/요청 후 매일 오전 9시 알림을 예약한다.
- 토글 OFF 시 예약 알림을 취소한다.
- 앱 재실행 후에도 ON 상태면 Splash에서 예약을 보정한다.

구현:

- `AlertFeature` 추가
  - `onAppear`: `SettingsClient.getAlarm()`으로 저장된 토글 상태 로드
  - `alarmToggled(true)`: 권한 상태 확인, 필요 시 요청, 허용 시 예약
  - `alarmToggled(false)`: 예약 취소 및 저장값 false
  - 실패/거절 시 toast message 설정
- `NotificationPermissionClient` 확장
  - `authorizationStatus`
  - `requestAuthorization`
  - `scheduleDailyQuoteNotification`
  - `cancelDailyQuoteNotification`
- `SplashFeature` 보정
  - 저장값이 ON이고 권한이 허용이면 매일 오전 9시 알림 재예약
  - 권한이 사라졌으면 저장값 OFF 처리

검증 기준:

- 토글 ON/OFF가 앱 재실행 후 유지된다.
- ON 상태에서 pending notification이 예약된다.
- OFF 상태에서 pending notification이 제거된다.

남은 이슈:

- 권한 거절 시 설정 앱 이동 UX는 아직 결정하지 않았다.
- 오늘의 명언을 알림 본문에 넣으려면 push 또는 별도 백그라운드 갱신 전략이 필요하다.

### 4.2 전역 토큰 만료/에러 처리

목표:

- 401/403 발생 시 refresh token으로 원 요청을 1회 재시도한다.
- refresh token이 없거나 갱신 실패하면 세션 만료 이벤트를 앱 루트로 전달한다.
- 세션 만료 시 로컬 토큰을 삭제하고 회원 UI를 비회원 상태로 전환한다.
- 무한 retry를 방지한다.

구현:

- `FillsaRequestInterceptor`
  - access token 자동 주입
  - 401/403에서 `request.retryCount == 0`일 때만 refresh retry
  - refresh 실패, refresh token 없음, 재시도 후 실패 시 `SessionExpirationEvent` 발행
- `SessionExpirationEvent`
  - `missingRefreshToken`
  - `refreshFailed`
  - `retryRejected`
- `SessionExpirationClient`
  - `NotificationCenter` 이벤트를 `AsyncStream`으로 변환
- `AppFeature`
  - `.task`에서 session expiration stream 구독
  - `.sessionExpired`에서 `sessionClient.logout()` 실행
  - Home/List/Calendar/MyPage state 초기화

검증 기준:

- 만료된 access token에서 refresh token으로 1회 재시도한다.
- refresh 실패 시 무한 retry하지 않는다.
- 세션 만료 후 회원 상태 UI가 초기화된다.

남은 이슈:

- Android `WithBaseErrorHandling`의 전체 에러 코드별 dialog/snackbar 정책은 별도 작업으로 남아 있다.

### 4.3 팝업 API 노출

목표:

- 앱 main/Home/MyPage 진입 시 일반 팝업과 버전 업데이트 팝업을 조회한다.
- Android와 동일한 우선순위로 팝업을 표시한다.
- 일반 팝업의 `오늘 보지 않기` 숨김 처리를 연결한다.

구현:

- `GeneralPopupFeature` 추가
  - `loadIfNeeded`: 한 번만 팝업 API 조회
  - `getPopupGeneral()`, `getPopupVersionUpdate(currentVersion:)` 호출
  - `VERSION_UPDATE -> NOTICE -> EVENT` 우선순위 정렬
  - 일반 팝업은 `HiddenPopupClient.isHidden(seq)` 확인
- `GeneralPopupView` 추가
  - 이미지 팝업
  - 텍스트 팝업
  - 닫기
  - 오늘 보지 않기
- `HiddenPopupClient.clearAllIfNeeded`
  - 날짜가 바뀌면 숨김 목록 초기화
  - Android `ClearHiddenInfoWorker` 역할을 iOS에서는 조회 시점 정리로 처리
- `AppFeature/AppView`
  - main/Home/MyPage 진입 지점에서 `.generalPopup(.loadIfNeeded)` 실행
  - App root overlay로 팝업 표시

검증 기준:

- API 응답이 있으면 우선순위대로 팝업이 표시된다.
- 오늘 보지 않기 처리한 일반 팝업은 같은 날 다시 표시되지 않는다.
- 날짜가 바뀌면 숨김 목록이 초기화된다.

남은 이슈:

- 실제 서버 응답으로 이미지/텍스트 팝업 QA가 필요하다.
- 버전 업데이트 팝업 클릭 시 App Store 이동은 Android에도 없어 추가하지 않았다.

### 4.4 Dark theme parity

목표:

- Android `FillsaColorScheme` 기준으로 iOS 색상 토큰을 light/dark 대응 구조로 정리한다.
- 주요 화면의 고정 색상을 의미 기반 토큰으로 교체한다.

구현:

- `FillsaColor`에 semantic token 추가
  - `background`
  - `onBackground1`
  - `onBackground2`
  - `backgroundContainer`
  - `primaryContainer`
  - `outline`
  - `toastMessageBackground`
- 주요 화면 색상 교체
  - Home
  - QuoteList
  - Calendar
  - MyPage
  - Common header/bottom navigation

검증 기준:

- 앱의 `preferredColorScheme` 변경 시 주요 화면 색상이 자동으로 바뀐다.
- Android dark token과 iOS semantic token이 같은 역할을 한다.

남은 이슈:

- 실제 시뮬레이터에서 Android/iOS 화면을 나란히 두고 육안 QA가 필요하다.
- 팝업/상세/서브 화면 전체까지 dark token을 확대할지는 후속 범위다.

## 5. 검증 기록

실행한 검증:

```bash
xcodebuild -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,name=iPhone 17' build -quiet
```

결과:

- 빌드 성공
- 기존 warning은 남아 있다.
  - TCA `ViewStore` deprecation warning
  - Swift 6 actor/sendable 관련 warning
  - Preview layout warning

추가로 worker별 검증에서 확인된 내용:

- 팝업 작업은 단독 빌드 성공
- Dark theme 작업은 `git diff --check` 통과 및 `FillsaColor.swift` 단독 타입체크 통과
- 알림/토큰 작업 중간 빌드 실패는 병렬 통합 전 충돌성 오류였고, 최종 통합 후 전체 빌드는 성공

## 6. 후속 작업

Wave 1 이후 남은 주요 작업:

- 회원 탈퇴
- 소셜 로그인 provider 콘솔 설정 및 URL Types 등록
- 카카오 SDK 템플릿 공유 여부 결정
- 공통 API 에러 dialog/snackbar 정책
- 실제 기기/시뮬레이터 QA
  - 알림 권한 허용/거절
  - 팝업 서버 응답
  - 세션 만료
  - dark mode 화면 비교

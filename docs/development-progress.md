# Development Progress

## 2026-10-25 · iOS 신규 QA

- 2026-10-20 등록 iOS 관련 8건의 원인 분석·해결 계획을 Notion에 기록하고 상태를 In progress로 변경했다.
- 로그인 Google·로고·약관, 첫 로그인 온보딩, 저장 결과 팝업, 복사 토스트, 이미지 보기 표현, 연도 쉼표, Calendar 좋아요, 타이핑 안내를 구현했다.
- 사용자 결정: 온보딩 설치 후 첫 로그인 1회 / 저장 팝업 재저장 재노출 / 확인 Home·취소 팝업만 닫기 / 일반 완료도 리뉴얼 팝업 사용.
- 기능 검증: 기존 7건 140 테스트 통과, 로그인 최종 Light/Dark 2건 통과, 저장 결과 포함 전체 단위·팝업 UI 142건 통과. 각 실행은 중복을 포함하므로 합산하지 않는다.
- 전체 Figma 시각 수용은 Blocked. 360/390pt 프레임, 미등록 폰트 및 기존 배경 화면 차이가 남아 있다. 실계정 OAuth·실서버 v2 저장·이미지 업로드/삭제는 미검증.
- [QA 기록](design-qa/2026-10-25-ios-qa.md) · [원문·원인·수정 HTML 보고서](design-qa/2026-10-25-ios-qa-report.html). Notion은 최종 완료로 전환하지 않았다.

## Current Phase

Phase 2: Local Storage And Session

Current status:

- Keychain-backed token storage is in place.
- UserDefaults-backed settings storage is in place.
- Authenticated/no-token Alamofire API client factories are in place.
- Local quote and streak persistence is implemented with system SQLite.
- Android-matching local/session use cases are in place.
- TCA dependency clients are in place for local quote, session, settings, streak, hidden popup, and common APIs.
- The app now starts from a TCA-backed splash route.
- The shared global loading spinner is excluded from the splash route; the other 13 routable display states retain it when loading is active (2026-10-03).

## Phase Checklist

### Phase 0. Project Foundation

- [x] Add TCA package dependency.
- [x] Resolve Swift Package dependencies.
- [x] Create foundation folder structure.
- [x] Create `AppFeature`.
- [x] Create `AppView`.
- [x] Create tab route model for Home/List/Calendar/My page.
- [x] Replace default `ContentView` entry with the app shell.
- [x] Add initial Android-derived color tokens.
- [x] Add initial Android-derived typography tokens.
- [x] Build generic iOS target successfully.

Build command used:

```bash
xcodebuild -project Fiilsa.xcodeproj -scheme Fiilsa -configuration Debug -destination generic/platform=iOS -derivedDataPath /private/tmp/FiilsaDerivedData CODE_SIGNING_ALLOWED=NO -skipMacroValidation build
```

Result:

```text
BUILD SUCCEEDED
```

Notes:

- TCA resolved to `swift-composable-architecture` 1.26.0.
- The first CLI build requires `-skipMacroValidation` unless Xcode has already trusted the package macros.
- The current UI is only a temporary routing shell. Android-parity screen UI starts after common UI and screen-specific implementation phases.

## Phase 1. Core Domain And Data Contracts

- [x] Read Android request models.
- [x] Read Android response models.
- [x] Read Android repository interfaces.
- [x] Add Swift request models:
  - `LoginRequest`
  - `TokenRefreshRequest`
  - `TypingQuoteRequest`
  - `LikeRequest`
  - `MemoRequest`
  - `LocalQuoteInfo`
- [x] Add Swift response models:
  - `DailyQuote`
  - `DailyQuoteNoToken`
  - `LoginResponse`
  - `TokenInfo`
  - `MemberTypingQuoteResponse`
  - `MemberQuoteImageResponse`
  - `MemberQuotesResponse`
  - `PageResponseMemberQuotesResponse`
  - `MemberMonthlyQuoteResponse`
  - `MemberQuotesData`
  - `MonthlySummaryData`
  - `MonthlyQuoteResponse`
  - `NoticeResponse`
  - `PageResponseNoticeResponse`
  - `PopupResponse`
  - `MemberStreakResponse`
  - `ErrorResponse`
- [x] Add `YN` support enum.
- [x] Add endpoint constants matching Android `ApiEndPoint.kt`.
- [x] Add `APIEnvironment` with Android production base URL `https://api.fillsa.com`.
- [x] Add Alamofire-backed `APIClient` skeleton.
- [x] Add `FillsaRequestInterceptor` skeleton for bearer token injection and one-time refresh retry.
- [x] Add repository protocols:
  - `AuthRepository`
  - `HomeRepository`
  - `TypingRepository`
  - `CalendarRepository`
  - `QuoteListRepository`
  - `CommonRepository`
  - `LocalRepository`
- [x] Build generic iOS target successfully.

Build command used:

```bash
xcodebuild -project Fiilsa.xcodeproj -scheme Fiilsa -configuration Debug -destination generic/platform=iOS -derivedDataPath /private/tmp/FiilsaDerivedData CODE_SIGNING_ALLOWED=NO -skipMacroValidation build
```

Result:

```text
BUILD SUCCEEDED
```

Notes:

- API networking uses Alamofire 5.12.0.
- `APIClient` now wraps `Alamofire.Session` and keeps endpoint/path/body construction in project-owned request types.
- Token refresh retry is wired through `FillsaRequestInterceptor` and `APIClientFactory.authenticated(...)`.

## Next Phase

Phase 2: Local Storage And Session

Planned next tasks:

- [x] Implement Keychain-backed token storage.
- [x] Implement UserDefaults-backed settings.
- [x] Wire token storage into Alamofire interceptor/client factory.
- [x] Add session state check through `LocalRepository.isLoggedIn()`.
- [x] Choose local quote/streak persistence: system SQLite.
- [x] Implement `quoteInfo` local quote persistence.
- [x] Implement `streak_info` persistence.
- [x] Match Android local quote deletion rule when like is changed to `N` and typing/memo are empty.
- [x] Add local quote clearing through `LocalRepository.clear()`.
- [x] Wire guest/member local quote behavior into domain use cases.
- [x] Add session/settings use cases for first-open, login status, token, alarm, user name, dark mode, and token-expired state.
- [x] Add member/local streak selection use cases.
- [x] Add TCA dependency clients that expose repositories/use cases to features.
- [x] Add default `CommonRepository` implementation for notice, popup, resign, and member streak APIs.
- [x] Start wiring dependencies into the first real TCA screen feature.
- [x] Add notification permission dependency for splash startup behavior.
- [x] Add SplashFeature state/action/reducer.
- [x] Add SplashView matching the Android splash text, layout size, and startup timing structure.
- [x] Route app startup through splash.
- [x] Route first open to login and later opens to home, matching Android splash logic.
- [x] Replace the temporary splash animation placeholder with the Android Lottie asset/rendering path.

Build command used:

```bash
xcodebuild -project Fiilsa.xcodeproj -scheme Fiilsa -configuration Debug -destination generic/platform=iOS -derivedDataPath /private/tmp/FiilsaDerivedData CODE_SIGNING_ALLOWED=NO -skipMacroValidation build
```

Result:

```text
BUILD SUCCEEDED
```

Notes:

- `SQLiteLocalStore` mirrors Android Room table names `quoteInfo` and `streak_info`.
- `quoteInfo` uses `dailyQuoteSeq` as the primary key and saves with `INSERT OR REPLACE`, matching Android `OnConflictStrategy.REPLACE`.
- `streak_info` uses `date` as the primary key and keeps Android's today/yesterday streak count behavior.
- Use cases are value-type wrappers with `callAsFunction`, matching Android's `operator fun invoke()` usage style.
- TCA features can now access live dependencies through `@Dependency(\.localQuoteClient)`, `@Dependency(\.sessionClient)`, `@Dependency(\.settingsClient)`, `@Dependency(\.streakClient)`, `@Dependency(\.hiddenPopupClient)`, and `@Dependency(\.commonClient)`.
- `SplashFeature` checks notification permission only once, persists alarm usage/request state, waits for the splash animation completion signal, then routes through `AppFeature`.
- Splash uses Lottie 4.6.1 through Swift Package Manager and renders the Android `lottie_splash` / `lottie_splash_dark` JSON assets.

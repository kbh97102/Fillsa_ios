# Development Progress

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

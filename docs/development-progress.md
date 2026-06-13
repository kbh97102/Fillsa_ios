# Development Progress

## Current Phase

Phase 2: Local Storage And Session

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
- [x] Add URLSession-backed `APIClient` skeleton.
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

## Next Phase

Phase 2: Local Storage And Session

Planned next tasks:

- Implement Keychain-backed token storage.
- Implement UserDefaults-backed settings.
- Choose and implement local quote/streak persistence.
- Wire login/session state dependency.
- Add local data clearing and guest/member local quote behavior.

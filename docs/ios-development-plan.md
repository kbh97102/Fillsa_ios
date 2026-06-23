# iOS Development Plan

## Principles

- Match Android design and behavior exactly.
- Do not add UI, features, flows, states, animations, or copy without explicit approval.
- Always read the relevant screen planning file in `docs/screens/` before implementing a screen.
- When planning and Android code differ, use Android as the source of truth and record the difference.
- Build with MVI and Clean Architecture. Use TCA for the MVI layer.

## Target Architecture

Use a folder structure that mirrors Android Clean Architecture while fitting SwiftUI and TCA.

```text
Fiilsa/
  App/
    FiilsaApp.swift
    AppFeature.swift
    AppView.swift
    AppRoute.swift
  Core/
    DesignSystem/
    Navigation/
    Effects/
    Extensions/
    Utilities/
  Domain/
    Models/
    Requests/
    Responses/
    Repositories/
    UseCases/
  Data/
    API/
    DTO/
    Repositories/
    Persistence/
    Keychain/
    UserSettings/
  Presentation/
    Common/
    Splash/
    OnboardingGuide/
    Login/
    Home/
    Typing/
    Share/
    Calendar/
    QuoteList/
    QuoteDetail/
    MemoInsert/
    MyPage/
    Notice/
    AlertSettings/
  Resources/
    Fonts/
```

## TCA Mapping

Android ViewModel/action/effect pairs should become TCA features.

| Android source | iOS TCA feature |
|---|---|
| `MainNavHost.kt`, `Screens.kt` | `AppFeature` with route/path state |
| `LoginViewModel.kt`, `LoginAction` | `LoginFeature` |
| `HomeViewModel.kt`, `HomeAction`, `HomeEffect` | `HomeFeature` |
| `TypingViewModel.kt`, `TypingAction`, `TypingEffect` | `TypingFeature` |
| `CalendarViewModel.kt`, `CalendarAction` | `CalendarFeature` |
| `ListViewModel.kt`, `QuoteListAction`, `QuoteListState` | `QuoteListFeature` |
| `MyPageViewModel.kt`, `MyPageAction` | `MyPageFeature`, `AlertSettingsFeature`, `ThemeFeature` |
| Notice paging in `MyPageViewModel` | `NoticeListFeature`, `NoticeDetailFeature` |
| `ShareViewModel.kt`, `ShareAction` | `ShareFeature` |

Each feature should use this shape:

```swift
@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
    }

    enum Action: Equatable {
    }

    @Dependency(\.homeClient) var homeClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
        }
    }
}
```

## Dependency Plan

Layer ownership:

```text
Presentation Feature/Reducer
-> @Dependency(\.someUseCase)
-> Core/Dependencies liveValue
-> Domain UseCase
-> Domain Repository protocol
-> Data Repository implementation
-> API / local DB / UserDefaults / Keychain
```

- `Domain/UseCases` contains plain Swift use case structs. They must not import `ComposableArchitecture` and must not know concrete data implementations.
- `Domain/Repositories` contains repository protocols used by use cases.
- `Data/Repositories` contains concrete repository implementations and may use `APIClient`, SQLite, UserDefaults, Keychain, or other platform storage.
- `Core/Dependencies` is the TCA composition layer. It registers `DependencyKey` / `DependencyValues` and builds `liveValue` by connecting `LiveRepositories` to Domain use cases.
- `App` owns app startup, routing, and root feature wiring. Do not put per-feature use case `liveValue` registration in `App` unless the dependency is truly app-wide orchestration.
- Reducers should call use case dependencies, not repositories or API clients directly.

Use cases are the place for business flows that combine multiple data operations. For example, login should call the auth repository, then save access token, refresh token, user name, or other local session data through the local repository inside the login use case. Reducers should only send the login action, receive the result action, and update screen state.

Required early dependencies:

| Need | Proposed iOS choice |
|---|---|
| MVI/TCA | Swift Composable Architecture |
| HTTP | Native `URLSession` client wrapped in dependencies |
| Token storage | Keychain wrapper |
| Local settings | UserDefaults-backed settings client |
| Local quote/streak DB | SwiftData/Core Data, after confirming target/runtime constraints |
| Image picking | SwiftUI `PhotosPicker` and camera bridge only where Android has the feature |
| Share sheet | `UIActivityViewController` bridge |
| Clipboard | `UIPasteboard` dependency |
| Notifications | `UserNotifications` dependency |
| Social login | Kakao/Google SDKs after confirming app keys and bundle setup |

Avoid adding nonessential packages until a feature requires them.

## Development Phases

### Phase 0. Project Foundation

Goal: Replace the default SwiftUI template with app infrastructure only.

Tasks:

- Add TCA package.
- Create the folder structure.
- Create `AppFeature`, `AppView`, and route enum/path state.
- Move the SwiftUI entry point to render `AppView`.
- Add a design system shell:
  - colors from Android `colors.xml`
  - typography names from Android `FillsaTheme`
  - spacing constants only when directly observed from Android UI
- Import Android fonts:
  - Pretendard
  - GangwonEduAll
- Copy required Android drawable/image assets into `Assets.xcassets` with original names where practical.

Verification:

- App builds.
- Empty route shell renders.
- No extra user-facing feature is added.

### Phase 1. Core Domain And Data Contracts

Goal: Establish models, requests, repository protocols, and API clients before screen work.

Tasks:

- Create response models matching Android:
  - `DailyQuote`
  - `DailyQuoteNoToken`
  - `MemberTypingQuote`
  - `MemberQuoteImage`
  - `MemberMonthlyQuote`
  - `MemberQuotesData`
  - `MonthlySummary`
  - `MemberQuotesResponse`
  - `PageResponse`
  - `NoticeResponse`
  - `PopupResponse`
  - `LoginResponse`
  - `TokenInfo`
  - `MemberStreak`
- Create request models:
  - `LoginRequest`
  - `TokenRefreshRequest`
  - `LikeRequest`
  - `TypingQuoteRequest`
  - `MemoRequest`
  - `LocalQuoteInfo`
- Create repository protocols:
  - `AuthRepository`
  - `HomeRepository`
  - `TypingRepository`
  - `CalendarRepository`
  - `QuoteListRepository`
  - `NoticeRepository`
  - `CommonRepository`
  - `LocalQuoteRepository`
  - `SettingsRepository`
- Create Domain use cases that mirror Android use cases and keep feature-facing business flows out of reducers:
  - login and token/session flows
  - daily quote loading and like flows
  - local quote insert/update/delete/memo/like flows
  - calendar monthly quote loading
  - quote list and memo save flows
  - settings and notification preference flows
- Build URLSession client with:
  - base URL configuration
  - token injection
  - refresh token retry for 401/403
  - no-token API path support
- Register TCA dependencies in `Core/Dependencies` by wrapping Domain use cases in dependency structs. `liveValue` belongs in this composition layer, not in `Domain` or `Data`.

Verification:

- Unit tests for endpoint construction and JSON decoding from sample payloads when available.
- No screen behavior implemented beyond what is needed to compile.

### Phase 2. Local Storage And Session

Goal: Match Android guest/member behavior.

Tasks:

- Implement token storage.
- Implement settings:
  - first open
  - user name
  - profile image URI
  - alarm usage
  - notification permission requested
  - dark mode type
- Implement local quote/streak persistence:
  - local quote insert/update/delete
  - like update
  - memo update
  - quote lookup by `dailyQuoteSeq`
  - date range paging/listing
  - streak completion state
- Implement login state dependency.
- Implement logout and local data clearing.

Verification:

- Unit tests for local quote merge behavior.
- Unit tests for guest like, memo, typing, and cleanup rules.

### Phase 3. Navigation And Common UI

Goal: Build the shared app shell exactly once.

Tasks:

- Implement root navigation corresponding to Android `Screens`.
- Implement common header:
  - Home/List/Calendar: logo + user icon.
  - MyPage: logo only.
- Implement bottom tabs:
  - Home
  - List
  - Calendar
  - My page
- Implement bottom text ad area per `docs/screens/common.md`.
- Hide bottom tab/ad on typing and memo entry screens.
- Implement shared dialogs, snackbar/toast, loading spinner, and image dialog shell.

Verification:

- Navigation state tests for route transitions.
- Visual comparison against Android before feature-specific screen work.

### Phase 4. Onboarding And Login

Planning files:

- `docs/screens/0_onboarding.md`
- `docs/screens/0_onboarding_guide.md`
- `docs/screens/1_login.md`

Tasks:

- First-launch notification permission flow.
- Onboarding guide with Android guide images and same button behavior.
- Login screen:
  - Kakao login
  - Google login
  - guest start
  - terms/privacy links
  - close button on relogin flow
- Login request syncs local guest data.

Verification:

- Guest path reaches onboarding guide/Home as Android does.
- Login reducer tests cover success, failure, and local sync clearing.

### Phase 5. Home, Typing, Image, Share

Planning file:

- `docs/screens/2_home.md`

Tasks:

- Home daily quote:
  - today default
  - previous/next date constraints
  - Korean/English switch
  - author link
  - copy quote text
  - like
  - share route
- Guest/member daily quote fetch and local merge.
- Typing screen:
  - saved typing fetch
  - character correctness rendering
  - save on back
  - explicit save dialog behavior
  - like/share/copy
- Member image upload/delete flow.
- Share screen with Android share backgrounds and same save/share/copy actions.

Verification:

- Reducer tests for date movement, like behavior, guest merge, and typing save.
- Visual screenshots compared to Android screen references.

### Phase 6. Calendar

Planning files:

- `docs/screens/3_calendar.md`
- `docs/screens/3_calendar_feature_spec.md`

Tasks:

- Monthly calendar.
- Start date and future date constraints.
- Selected date state.
- Member monthly API.
- Guest monthly API plus local quote/streak merge.
- Completion/like/streak indicators.
- Monthly count section.
- Bottom quote section.
- Navigation to Home and List with selected date/month.

Verification:

- Reducer tests for month change, day selection, bottom quote, count navigation.
- Local merge tests for guest calendar state.

### Phase 7. List, Detail, Memo

Planning file:

- `docs/screens/4_list.md`

Tasks:

- Quote list with date range and like filter.
- Member server paging.
- Guest local paging.
- Date range picker matching Android behavior.
- Item card with quote/memo/image/like state.
- Detail screen.
- Memo entry screen with bottom tab/ad hidden.
- Memo save for member and guest.

Verification:

- Reducer tests for filters, date selection, item navigation, memo save.
- Confirm Android-code-vs-planning default date rule before implementation.

### Phase 8. My Page, Notice, Alert, Theme

Planning files:

- `docs/screens/5_mypage.md`
- `docs/screens/5_1_notice.md`
- `docs/screens/5_2_inform.md`
- `docs/screens/5_3_theme.md`

Tasks:

- My Page guest/member layouts.
- Login route from guest state.
- Logout.
- Notice list and detail.
- Alarm toggle and notification scheduling.
- Withdraw confirmation and API call.
- Theme selection popup and immediate theme application.

Verification:

- Reducer tests for login/logout/withdraw/theme/alarm.
- Notice paging decode and loading tests.

### Phase 9. Optional Android-Parity Extensions

Only start after explicit approval.

Tasks:

- WidgetKit extension for Android widget parity.
- More complete background refresh strategy.
- Production ad integration if Android ad provider and iOS counterpart are confirmed.

## Initial Implementation Order

Recommended immediate order:

1. Add TCA and foundation folder structure.
2. Implement design tokens and asset/font import.
3. Implement app routing shell and common UI placeholders using Android assets.
4. Implement Domain/Data contracts and API client.
5. Implement local storage.
6. Build screens in this order:
   1. Splash/onboarding/login
   2. Home
   3. Typing
   4. Share/image
   5. Calendar
   6. List/detail/memo
   7. My Page/notice/alert/theme

This order keeps the app navigable early while preserving the Android feature dependencies.

## Risks And Decisions Needed

| Area | Risk | Decision needed |
|---|---|---|
| Android code vs planning | Some behavior differs, such as List default start date and dialog copy | Default to Android unless user says otherwise |
| Social login | Kakao/Google/Firebase require app keys, URL schemes, bundle setup | Confirm credentials and SDK setup timing |
| Local DB | SwiftData is convenient but may depend on deployment target and migration needs | Confirm persistence choice before implementation |
| Assets | Android vector drawables need conversion or recreation in asset catalog | Decide whether to convert all upfront or per screen |
| Widget | Android has widget support, but iOS requires a separate target | Defer until approved |
| Ads | Android has ad UI/components, provider details need confirmation | Start with exact UI surface only, integrate provider later |

## Definition Of Done Per Screen

For each screen:

1. Read the screen planning file.
2. Inspect the corresponding Android Compose UI and ViewModel.
3. Record any planning-vs-code mismatch in `docs/android-analysis.md` or a screen-specific note.
4. Implement State, Action, Reducer, dependencies, and SwiftUI view.
5. Keep UI and copy identical to Android.
6. Add reducer tests for state transitions and side effects.
7. Build the app.
8. Capture screenshots and compare visually against Android references when available.

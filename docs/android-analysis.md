# Android App Analysis

## Scope

- iOS target repository: `/Users/gangbohun/iosProjects/Fiilsa`
- Android source of truth: `/Users/gangbohun/AndroidStudioProjects/Fillsa`
- Planning documents:
  - `docs/planning.md`
  - `docs/screens/`

This document records the current Android app structure and behavior that the iOS conversion must preserve.

## Planning Summary

The product is a writing practice app centered on daily quotes. The planned screens are:

| Screen | Planning file | Main behavior |
|---|---|---|
| Common UI | `docs/screens/common.md` | Header, bottom tab bar, bottom text ad |
| Onboarding permission | `docs/screens/0_onboarding.md` | First launch notification permission prompt |
| Onboarding guide | `docs/screens/0_onboarding_guide.md` | Sequential guide images, skip/next/start buttons |
| Login | `docs/screens/1_login.md` | Kakao login, Google login, guest start, terms/privacy links |
| Home | `docs/screens/2_home.md` | Daily quote, language switch, quote typing, image upload, copy, like, share |
| Calendar | `docs/screens/3_calendar.md` | Monthly quote calendar, completion/like/streak indicators, month stats |
| List | `docs/screens/4_list.md` | Quote history, like filter, date range, detail, memo |
| My Page | `docs/screens/5_mypage.md` | Profile/login state, notice, alarm, app version, theme, logout |
| Notice | `docs/screens/5_1_notice.md` | Notice list and detail |
| Alarm/account | `docs/screens/5_2_inform.md` | Daily notification toggle, account withdrawal |
| Theme | `docs/screens/5_3_theme.md` | System/light/dark selection |

## Android Project Structure

The Android app already follows a Clean Architecture style:

| Module | Path | Role |
|---|---|---|
| `app` | `app/src/main/java/com/arakene/fillsa` | Application, DI modules, workers, widget |
| `presentation` | `presentation/src/main/java/com/arakene/presentation` | Compose UI, navigation, view models, UI actions/effects/state |
| `domain` | `domain/src/main/java/com/arakene/domain` | Use cases, repository interfaces, requests, responses, domain models |
| `data` | `data/src/main/java/com/arakene/data` | Retrofit APIs, repository implementations, Room DB, DataStore/cache/token utilities |
| `compose-util` | `compose-util` | Shared Compose utilities |

The iOS conversion should mirror this separation with Swift modules/folders for Presentation, Domain, Data, and Core.

## Android Navigation

Android navigation is defined in:

- `presentation/ui/common/MainNavHost.kt`
- `presentation/util/Screens.kt`
- `presentation/util/MyPageScreens.kt`

Routes currently present:

| Android route | iOS feature target |
|---|---|
| `Splash` | `SplashFeature` |
| `Login(isOnBoarding)` | `LoginFeature` |
| `OnBoardingGuide` | `OnboardingGuideFeature` |
| `Home(targetYear, targetMonth, targetDay)` | `HomeFeature` |
| `DailyQuote(dailyQuoteDto)` | `TypingFeature` |
| `Share(quote, author)` | `ShareFeature` |
| `QuoteList(startDate)` | `QuoteListFeature` |
| `QuoteDetail(...)` | `QuoteDetailFeature` |
| `MemoInsert(savedMemo, memberQuoteSeq)` | `MemoInsertFeature` |
| `Calendar` | `CalendarFeature` |
| `MyPage` | `MyPageFeature` |
| `MyPageScreens.Notice` | `NoticeListFeature` |
| `MyPageScreens.Alert` | `AlertSettingsFeature` |
| `MyPageScreens.NoticeDetail(noticeResponse)` | `NoticeDetailFeature` |

The bottom navigation items are Home, List, Calendar, and My page. Bottom navigation and the text ad are hidden on input screens such as typing and memo entry.

## Presentation Pattern

Android uses a lightweight MVI pattern:

- `BaseViewModel` receives `Action`.
- Feature-specific sealed actions live mostly in `presentation/util/action/Action.kt`.
- One-off navigation/dialog/snackbar events are emitted as `Effect`.
- Feature UI reads mutable state from the ViewModel.

Important action groups:

| Action group | Android source | iOS TCA mapping |
|---|---|---|
| `LoginAction` | `presentation/util/action/Action.kt` | `LoginFeature.Action` |
| `HomeAction` | `presentation/util/action/Action.kt` | `HomeFeature.Action` |
| `TypingAction` | `presentation/util/action/Action.kt` | `TypingFeature.Action` |
| `CalendarAction` | `presentation/util/action/Action.kt` | `CalendarFeature.Action` |
| `QuoteListAction` | `presentation/util/action/QuoteListAction.kt` | `QuoteListFeature.Action` |
| `MyPageAction` | `presentation/util/action/Action.kt` | `MyPageFeature.Action` |
| `ShareAction` | `presentation/util/action/Action.kt` | `ShareFeature.Action` |

For iOS, implement this using TCA:

- `State` replaces Compose mutable state.
- `Action` mirrors Android actions.
- `Reducer` mirrors ViewModel action handling.
- `Effect` handles API calls, storage, login SDK, image picker, clipboard, share sheet, dialogs, and navigation.

## Data And API

Android API definitions:

- Authenticated API: `data/network/FillsaApi.kt`
- No-token API: `data/network/FillsaNoTokenApi.kt`
- Token refresh API: `data/network/TokenApi.kt`
- Endpoint constants: `data/network/ApiEndPoint.kt`

Endpoints currently used:

| Feature | Method/path |
|---|---|
| Login | `POST /api/v1/auth/login` |
| Token refresh | `POST /api/v1/auth/refresh` |
| Daily quote, guest | `GET /api/v1/quotes/daily?quoteDate=yyyy-MM-dd` |
| Daily quote, member | `GET /api/v1/member-quotes/daily?quoteDate=yyyy-MM-dd` |
| Like | `POST /api/v1/member-quotes/{dailyQuoteSeq}/like` |
| Upload image | `POST /api/v1/member-quotes/{dailyQuoteSeq}/images` |
| Delete image | `DELETE /api/v1/member-quotes/{dailyQuoteSeq}/images` |
| Typing save | `POST /api/v1/member-quotes/{dailyQuoteSeq}/typing` |
| Typing fetch | `GET /api/v1/member-quotes/{dailyQuoteSeq}/typing` |
| Quote list | `GET /api/v2/member-quotes` |
| Memo save | `POST /api/v1/member-quotes/{memberQuoteSeq}/memo` |
| Monthly quotes, guest | `GET /api/v1/quotes/monthly?yearMonth=yyyy-MM` |
| Monthly quotes, member | `GET /api/v2/member-quotes/monthly?yearMonth=yyyy-MM` |
| Notices | `GET /api/v1/notices?size=30&page={page}` |
| Withdraw | `DELETE /api/v1/auth/withdraw` |
| Member streaks | `GET /api/v1/member-streaks` |
| General popup | `GET /api/v1/popups/general` |
| Version update popup | `GET /api/v1/popups/version-update?currentVersion=0.0.2` |

The iOS API layer should use the same request/response names where practical and keep endpoint paths unchanged.

## Local Data

Android local persistence uses Room and DataStore.

Room entities:

| Entity | Android source | Purpose |
|---|---|---|
| `LocalQuoteInfoEntity` | `data/db/LocalQuoteInfoEntity.kt` | Guest/local quote typing, like, memo, date |
| `StreakInfoEntity` | `data/db/StreakInfoEntity.kt` | Local streak date and completion state |
| `WidgetQuoteInfoEntity` | `data/db/WidgetQuoteInfoEntity.kt` | Widget quote data |

Important local quote fields:

- `dailyQuoteSeq`
- `korQuote`
- `engQuote`
- `korAuthor`
- `engAuthor`
- `korTyping`
- `engTyping`
- `likeYn`
- `memo`
- `date`
- `dayOfWeek`

DataStore-backed settings and auth data include:

- access token
- refresh token
- user name
- profile image URI
- alarm usage
- notification permission requested flag
- dark mode type
- first open state
- hidden popup state

iOS should map these to:

- Keychain for access/refresh token.
- UserDefaults or app storage for lightweight settings.
- SwiftData/Core Data or SQLite for local quote and streak records.

## Feature Behavior Notes

### Login

Source:

- `presentation/viewmodel/LoginViewModel.kt`
- `presentation/ui/LoginView.kt`

Behavior:

- Supports Google and Kakao login.
- Supports guest start.
- Terms and privacy links open:
  - `https://home.fillsa.store/7vgjr4m1n5gkk2dwpy86`
  - `https://home.fillsa.store/3p4kj92yn5qwkm57q1x8`
- Login request sends device data, OAuth user data, and local guest sync data.
- After successful login, local quote data is cleared.

Android implementation detail to preserve:

- Guest start clears local tokens and navigates to onboarding guide.
- Login syncs local typing, memo, and like data via `syncData`.

### Home

Source:

- `presentation/viewmodel/HomeViewModel.kt`
- `presentation/ui/home/HomeView.kt`

Behavior:

- Default date is today.
- Previous date cannot go before `DateCondition.startDay`.
- Next date cannot go after today.
- Guest uses no-token daily quote API and merges local like state.
- Member uses member daily quote API and server like/image state.
- Quote tap navigates to typing screen.
- Share tap navigates to share screen.
- Image tap:
  - Guest: login dialog.
  - Member: image dialog.
- Like:
  - Member: server `POST /like`.
  - Guest: local DB insert/update.
- Image upload/delete is member-only.

Android dialog copy currently differs slightly from the planning doc:

- Guest image dialog title in code: `로그인 후 사용하실 수 있습니다.`
- Image delete dialog in code: `이미지를 삭제하시겠습니까?` / `삭제 후 이미지를 되돌릴 수 없습니다. 😢`

Use Android code as the source of truth unless the user asks to follow the planning copy instead.

### Typing

Source:

- `presentation/viewmodel/TypingViewModel.kt`
- `presentation/ui/home/TypingQuoteView.kt`

Behavior:

- Fetches saved typing from server for members and local DB for guests.
- Back action saves typing.
- Explicit save hides keyboard and saves typing.
- Completion condition: Korean typing equals Korean quote or English typing equals English quote.
- Guest completion writes local streak information.
- Member save posts typing to server.
- Like works in both member and guest modes.
- Save result may show completion / incomplete dialogs.

### Calendar

Source:

- `presentation/viewmodel/CalendarViewModel.kt`
- `presentation/ui/calendar/CalendarView.kt`
- `docs/screens/3_calendar_feature_spec.md`

Behavior:

- Default selected date is today.
- Month change fetches monthly data and selects the first day of that month.
- Bottom quote click navigates to Home with the selected date.
- Count click navigates to List with selected `yyyy-MM`.
- Member uses `/api/v2/member-quotes/monthly`.
- Guest uses `/api/v1/quotes/monthly` and merges local quote/streak data.
- Guest completion is derived from non-empty local Korean or English typing.

Date constraints from planning:

- Start date: 2025-06-16.
- Future dates disabled.
- Future month navigation disabled.

### List And Detail

Source:

- `presentation/viewmodel/ListViewModel.kt`
- `presentation/ui/quotelist/*`

Behavior:

- Default start date in Android code is June 1 of the current year.
- End date defaults to today.
- `startDate` route argument can override the list start date.
- Like filter toggles between all/history behavior and liked-only behavior.
- Member list uses server paging.
- Guest list uses local paging and maps local entities to `MemberQuotesResponse`.
- Item tap navigates to detail.
- Memo tap navigates to memo entry.
- Memo save:
  - Member: server API.
  - Guest: local DB update.

Planning states a V2 default of recent 6 months after 2026. Android code currently uses June 1 of the current year. Preserve Android behavior unless the user approves changing to the planning V2 rule.

### My Page, Notice, Alert, Theme

Source:

- `presentation/viewmodel/MyPageViewModel.kt`
- `presentation/ui/mypage/*`

Behavior:

- Guest sees login entry.
- Member sees user name/profile image and logout.
- Notice list is paged.
- Alarm usage is local setting.
- Withdraw calls API, then logs out and navigates Home.
- Theme type is stored locally and supports system/light/dark.

### Widget And Workers

Source:

- `app/src/main/java/com/arakene/fillsa/widget/*`
- `app/src/main/java/com/arakene/fillsa/*Worker.kt`

Android provides:

- Daily notification worker.
- Streak info worker.
- Hidden popup cleanup worker.
- App widget with quote previews/configuration.

iOS equivalents need separate implementation decisions:

- Notifications: `UserNotifications`.
- Widgets: WidgetKit extension.
- Background refresh: iOS background tasks are constrained and cannot be mapped one-to-one without product confirmation.

Do not add the WidgetKit extension until the user explicitly approves that scope.

## Design Assets And Tokens

Android assets live mainly in:

- `presentation/src/main/res/drawable`
- `presentation/src/main/res/font`
- `presentation/src/main/res/raw`

Important fonts:

- Pretendard weights 100-900.
- GangwonEduAll light/bold for quote text.

Important colors:

| Token | Hex |
|---|---|
| `purple01` | `#5C65FF` |
| `purple02` | `#D3D5FF` |
| `primary` | `#FFEFCC` |
| `yellow02` | `#FFCB5C` |
| `green_1a` | `#1ACE35` |
| `gray_100` | `#EEEEEE` |
| `gray_200` | `#E0E0E0` |
| `gray_300` | `#BDBDBD` |
| `gray_400` | `#9E9E9E` |
| `gray_500` | `#616161` |
| `gray_600` | `#424242` |
| `gray_700` | `#212121` |

Typography from Android `FillsaTheme`:

| Style | Font | Weight | Size | Line height |
|---|---|---:|---:|---:|
| heading1 | Pretendard | bold | 32 | 48 |
| heading2 | Pretendard | bold | 28 | 42 |
| heading3 | Pretendard | bold | 24 | 36 |
| heading4 | Pretendard | bold | 20 | 30 |
| subtitle1 | Pretendard | bold | 16 | 24 |
| subtitle2 | Pretendard | bold | 14 | 21 |
| body1 | Pretendard | regular | 20 | 30 |
| body2 | Pretendard | regular | 16 | 24 |
| body3 | Pretendard | regular | 14 | 21 |
| body4 | Pretendard | regular | 12 | 18 |
| quote | GangwonEduAll | regular | 16 | 24 |

iOS should import these fonts and drawable assets before building pixel-matched screens.

## iOS Repository Current State

The iOS project is currently a default SwiftUI app:

- `Fiilsa/FiilsaApp.swift`
- `Fiilsa/ContentView.swift`
- `Fiilsa/Assets.xcassets`

No feature, domain, data, networking, persistence, or TCA structure exists yet.

The Xcode project uses file-system synchronized groups, so new files placed under `Fiilsa/` should be recognized by the project without manually editing `project.pbxproj`.

## Open Questions Before Implementation

These should be confirmed before implementing the affected area:

1. Whether to follow Android code over planning doc when copy or default date behavior differs.
2. Whether iOS should include a WidgetKit extension in the first conversion scope.
3. Whether iOS should use SwiftData/Core Data or a lightweight SQLite wrapper for local quote/streak storage.
4. Which iOS social login SDK setup is already available or should be added first: Kakao, Google, Firebase.
5. Whether ad behavior should be real ad integration or placeholder until Android ad provider details are ported.

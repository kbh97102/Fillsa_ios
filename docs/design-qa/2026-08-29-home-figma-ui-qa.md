# Home Figma UI QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=2929-13556
- Target frames/nodes: `2929:13556` (`2.home`); metadata reports 360×821, although the implementation request listed 360×720.
- Full-frame reference image: `docs/design-qa/assets/home-figma/2026-08-29-home-figma-reference.png` (360×821; root background, status bar, safe area, bottom navigation, and ad area included).
- Runtime target: iOS Simulator, light state, deterministic Home quote state (pending).
- Runtime full-frame capture: unavailable — CoreSimulatorService could not be reached on 2026-08-29.
- Crop boundaries: reference full frame `0,0,360,821`; runtime capture pending.
- Comparison method: component and assembled full-frame side-by-side/overlay after a simulator becomes available.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Status/top surface | `2929:13557`, `2929:15476` | Light | Pending |
| Date controls | `2929:17013`, `2929:17161`, `2929:17154`, `2929:13653` | One completed date, current date selected | Pending |
| Locale prompt | `2929:15520` | Korean selected | Pending |
| Quote card | `2929:13642` | Light/default quote | Pending |
| Quote actions | `2929:15521` | Not liked | Pending |
| Question/answer | `2929:13630` | Empty answer | Pending |
| Bottom navigation/ad | `3087:29254`, `3087:29249` | Home selected | Blocked — Figma has 3 items; existing app preserves 4 items including QuoteList by approved scope |

## Validation rounds

### Round 1

| Scope | Difference | Fix | Result |
|---|---|---|---|
| RED runtime frame | The focused Home UI test could not launch on a simulator because CoreSimulatorService was unavailable; no runtime screenshot could be produced. | Retry from a host with an available iOS Simulator after implementation. | Blocked |
| Bottom navigation | Figma node `3087:29254` has Home/Calendar/My page only, while the existing shared navigation includes QuoteList as a fourth destination. | Not changed: removing or redesigning shared navigation is out of this Home-only task scope. | Blocked |
| Build | `xcodebuild` stopped before compiling the app because the existing Swift package checkout could not resolve `SwiftSyntax`/macro dependencies. | Re-resolve the package graph from a healthy Xcode/Simulator environment, then run the focused Home UI test. | Blocked |

### Round 2

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Home UI test fixture | `-ui-testing-home` reached `AppFeature.task`, which could reload persisted theme/session state after the deterministic launch state was installed. | Added the test argument to the startup-effect exclusion guard and added a UI test that verifies the post-startup light background. | Pending runtime verification |
| Home feedback | The Figma layout rewrite had removed rendering/dismissal of the existing `toastMessage` state. | Restored the prior toast presentation and 1.6-second `toastDismissed` lifecycle. | Pending runtime verification |
| Like action | The Figma action row always rendered the static outline-heart asset. | Reused the existing `HeartActionIcon` with `isLike` to render filled/outlined live state while retaining the same toggle action. | Pending runtime verification |

### Round 3

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Week strip completion | Earlier selected dates were displayed as completed without a completion source. | `HomeFeature` now receives only actual local `StreakInfo` records through `StreakClient.getAllLocal()` and exposes only records with `isDailyWritingCompleted == true`. | Pending runtime verification |
| Header streak | Header did not receive a streak value. | `HomeFeature` loads `StreakClient.getCurrentCount()` and passes a positive genuine count to `HomeHeader`; unavailable/zero values render no streak detail. | Pending runtime verification |
| Completion badge/date key | Completed dates lacked the Figma `2929:17161` badge and used a hard-coded KST date formatter. | `HomeWeekStrip` overlays the downloaded `home_completed_streak` 18×18 Figma asset only for genuine, non-selected completed dates. `HomeCompletionDateKey` uses injected `Calendar.current`, matching SQLiteLocalStore date semantics. | Pending runtime verification |
| Selected/completed priority | A selected date that was also complete used the completed purple background, creating a hybrid state. | `HomeWeekStripDayState` resolves selected before completed: white selected background, gray selected text, purple border, and no completion badge. | Pending runtime verification |
| Quote card/action row | Figma nodes `2929:13642` and `2929:15503` were not represented by explicitly named Home Figma components. | `HomeQuoteCard` uses the persisted texture/search assets, preserves author navigation and previous/next semantics (today blocks forward). `HomeQuoteActionRow` uses 16pt local action assets, 42pt row/dividers, and the existing live like/copy/share/image actions. | Pending runtime verification |

## Final assembled-screen result

- Full-frame reference/capture comparison: reference available at the recorded persistent path; runtime capture unavailable.
- Final runtime capture: unavailable.
- Result: Blocked
- Remaining differences: all runtime component and assembled-frame differences remain unverified until a 360×821-equivalent simulator/device capture can be taken; the 3-item Figma bottom navigation differs intentionally from the existing 4-item shared app navigation (QuoteList retained).

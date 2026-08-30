# Calendar Figma UI QA

## Reference and state (rework)

- Figma file: `VdFocqyqTgevMVCQxwAQ2X`
- Light Figma section: `2929:13366`; inspected render nodes: [basic `2985:21952` (360×816)](assets/calendar-figma/2026-08-30-calendar-basic-2985-21952-reference.png), [expanded/incomplete `2985:22510` (360×1101)](assets/calendar-figma/2026-08-30-calendar-incomplete-2985-22510-reference.png), and [expanded/completed `2987:22796` (360×1101)](assets/calendar-figma/2026-08-30-calendar-completed-2987-22796-reference.png).
- Existing dark render node `3039:28370` remains the dark palette reference; the reworked selected composition uses the existing dark token/asset appearances.
- Asset catalog source bytes: Figma heart/fire at 12pt and 16pt, plus the 100pt empty-handwriting character with a dark appearance variant. They are committed as vector 1× universal assets; no temporary Figma URL is retained.

## Component comparison

| Area | Implementation | Result |
|---|---|---|
| Header | `HomeHeader`: x20 Figma logo, genuine loaded streak, existing profile action; no Calendar-specific extra controls | Implemented |
| Root and month card | `CalendarView` / `CalendarMonthSection`: 320×396 at x20, radius 12, #FFCB5C light outline and existing dark treatment | Implemented |
| Month controls/grid | Existing reducer-backed previous/next and selection retained; exact fixed 36pt columns / 11pt gutters, weekday 40pt/date rows 50pt | Implemented |
| Day record state | `CalendarRecordIndicators`: heart for genuine like, flame for `completed || todayCompleted`; selected cell 36×50/r10; Figma 12pt source SVGs | GREEN test |
| Legend | Existing quote-list action retained; Figma 16pt heart/flame assets and real monthly like/writing counts | Implemented |
| Detail/empty companion | Incomplete selection has the 100pt Figma character/message and a tappable 80pt quote. Completed selection has 133pt detail/action composition plus the Figma question/answer form. `completed || todayCompleted` is shared with the indicator. | GREEN test |
| Detail actions / answer CTA | Calendar reducer has only `bottomQuoteTapped` and `countTapped`; no Calendar copy/share/like/image or answer persistence/navigation contract exists. Figma action row is intentionally non-mutating; 200-grapheme answer remains in-memory and CTA has no side effect. | Blocked — a separately owned Calendar record/action contract is needed |
| Dark photo modal | Figma dark reference contains a photo-edit overlay but Calendar has no new modal contract in scope | Blocked — intentionally not added |
| Shared bottom navigation/ad | Figma has three tabs; app owns four shared tabs including QuoteList | Blocked — product navigation decision required |

## Evidence

- RED: `selectedDayPresentationUsesCompletedDetailWhenOnlyTodayCompletedIsTrue` was added before `CalendarSelectedDayPresentation`; focused compilation failed exactly because that presentation mapper did not exist.
- GREEN: `xcodebuild test -quiet -only-testing:FiilsaTests/CalendarFeatureTests …` passed the focused 5-test suite, including month load/selection behavior and `completed=false, todayCompleted=true` → completed detail.
- Runtime capture: the actual iPhone 17 Pro boot completed, but it shut down before install/launch (`CoreSimulator.SimError 405: Unable to lookup in current state: Shutdown`). No current rendered frame was produced and no simulator service was killed or reconfigured.

## Final status

Component implementation: Pass with the intentionally non-mutating Calendar detail actions/answer CTA documented above. Assembled full-frame status: Blocked pending a rendered current-runtime basic and selected/expanded capture, Calendar action/answer contracts, and the intentional 3-tab Figma versus 4-tab shared-navigation product decision.

# Calendar Figma UI QA

## Reference and state

- Figma file: `VdFocqyqTgevMVCQxwAQ2X`
- Light render node: `2985:21952` (360×816)
- Dark render node: `3039:28370` (360×816)
- Durable visual references downloaded from the Figma asset export: `/private/tmp/fiilsa-calendar-assets/calendar-light-2985-21952.png` and `/private/tmp/fiilsa-calendar-assets/calendar-dark-3039-28370.png`.
- Asset catalog source bytes: Figma heart/fire at 12pt and 16pt, plus the 100pt empty-handwriting character with a dark appearance variant. They are committed as vector 1× universal assets; no temporary Figma URL is retained.

## Component comparison

| Area | Implementation | Result |
|---|---|---|
| Root and month card | `CalendarView` / `CalendarMonthSection`: #FFEFCC/#212121 root, 20pt inset, 12pt card, #FFCB5C light outline and #616161 dark outline | Implemented |
| Month controls/grid | Existing reducer-backed previous/next and selected-day actions retained; 24pt Figma arrow asset continues to be used | Implemented |
| Day record state | `CalendarRecordIndicators`: heart for genuine like, flame for genuine writing completion; Figma 12pt source SVGs | GREEN test |
| Legend | Existing quote-list action retained; Figma 16pt heart/flame assets and real monthly like/writing counts | Implemented |
| Detail/empty companion | Existing Home navigation retained; selected incomplete writing uses Figma character and message, quote card adapts to light/dark Figma color treatment | Implemented |
| Dark photo modal | Figma dark reference contains a photo-edit overlay but Calendar has no new modal contract in scope | Blocked — intentionally not added |
| Shared bottom navigation/ad | Figma has three tabs; app owns four shared tabs including QuoteList | Blocked — product navigation decision required |

## Evidence

- RED: focused `CalendarFeatureTests` failed to compile before `CalendarRecordIndicators` existed.
- GREEN: `xcodebuild test -only-testing:FiilsaTests/CalendarFeatureTests …` passed all 3 tests (record indicator mapping, load state, month-change selection/load).
- Runtime captures: launch installed the current app and wrote `/private/tmp/fiilsa-calendar-light-2985-21952-runtime.png`, but it caught the splash screen before Calendar rendered. A follow-up screenshot request failed with `CoreSimulatorService connection became invalid`, `simdiskimaged ... crashed or is not responding`, and connection refused. Dark launch/capture could not safely proceed; no simulator service was killed or reconfigured.

## Final status

Component implementation: Pass. Assembled full-frame status: Blocked pending a rendered current-runtime light/dark capture and the intentional 3-tab Figma versus 4-tab shared-navigation product decision.

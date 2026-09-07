# iOS Home Interactions Implementation Report

## Status

Implementation is implemented and current build/test/runtime evidence is retained. Strict visual acceptance remains **Blocked solely because** the available iPhone 17 Pro viewport is 402×874pt while the Figma target is 360×821.

## Changes

- Extended `HomeFeature` with inline-calendar, zero-streak tooltip, and Home-session question-answer state/actions.
- Added `HomeInlineCalendar` and `HomeStreakTooltip`; assembled them in `HomeView` with outside-tap dismissal.
- Kept quote-card typing navigation unchanged. The question CTA records locally in Home state, shows `답변을 기록했어요.`, and exposes edit state without an API or persistence contract.
- Connected the tooltip's Figma link to the existing Calendar tab in `AppView`.
- Added reducer and UI regression coverage for question/session flow, date strip bounds, calendar trigger, and tooltip exclusivity.
- Updated the Home screen specification and authored the design-QA record.

## Commands and results

| Command | Result |
|---|---|
| Simulator build with `/tmp/fiilsa-home-baseline-derived` and `/tmp/fiilsa-firebase-packages` | Passed (exit 0). |
| Root-reported fresh `HomeFeatureTests` + `AppFeatureTests` final run | Passed (exit 0). |
| Serialized `HomeUITests` final run on `89410CC6-A661-4252-B810-0E54DE5FB620` | Passed (exit 0). |
| Current build installed and launched with Home fixtures | Passed; retained full simulator evidence. |

Earlier package-cache and simulator-service failures in the historical follow-up notes below are superseded by the final successful build, test, install, and capture evidence above.

## Capture paths

- Figma retained references: `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/`.
- Runtime captures: `runtime-ios-default-light.png`, `runtime-ios-calendar-open-light.png`, `runtime-ios-question-done-light.png`, `runtime-ios-question-toast-light.png`, `runtime-ios-streak-tooltip-light.png`, `runtime-ios-image-modal-light.png`, and `runtime-ios-default-dark.png`; see `docs/design-qa/2026-09-07-ios-home-interactions-qa.md`.

## Changed files

- `Fiilsa/App/AppView.swift`
- `Fiilsa/Presentation/Home/HomeFeature.swift`
- `Fiilsa/Presentation/Home/HomeFigmaComponents.swift`
- `Fiilsa/Presentation/Home/HomeInlineCalendar.swift`
- `Fiilsa/Presentation/Home/HomeStreakTooltip.swift`
- `Fiilsa/Presentation/Home/HomeView.swift`
- `FiilsaTests/HomeFeatureTests.swift`
- `FiilsaUITests/HomeUITests.swift`
- `docs/screens/2_home.md`
- `docs/design-qa/2026-09-07-ios-home-interactions-qa.md`

## Self-review

- The monthly trigger does not navigate to Calendar; it toggles the inline popup.
- Outside taps close either active Home overlay; valid calendar dates select, close, and reload the daily quote.
- Completed markers derive only from `isDailyWritingCompleted`; selected appearance wins.
- The question flow has no API/persistence side effect and never invokes `openTyping`.
- The existing quote/image, copy, and like callbacks remain intact.
- Figma's shared-navigation discrepancy remains deliberately unchanged.

## Concerns

- Build, dark-mode capture, and targeted Home/App/UI tests are no longer blocked; final evidence is retained.
- The Home screen documents `Blocked`, not `Pass`, solely because a 360×821 runtime target is required for strict full-frame Figma acceptance.

## Follow-up: runtime/review fixes

### Review fixes

- Added explicit streak-load state so the purple outlined zero-streak warning is neither rendered nor actionable before a genuine streak result is available. A positive result also clears any visible zero-state tooltip.
- The tooltip's Calendar link now dismisses its Home overlay before selecting the existing Calendar tab.
- Calendar month arrows, menus, and reducer state are bounded to the supported start month through the current month. The year/month labels now use the rounded border and shadow visible in the retained Figma frame.
- Added regression coverage for pre-load warning suppression, positive-load tooltip cleanup, valid calendar selection/reload, outside dismissal, and month-range bounds.

### Historical runtime/build evidence (superseded)

| Command | Result |
|---|---|
| `xcrun simctl list devices` | Passed: iPhone 17 Pro `89410CC6-A661-4252-B810-0E54DE5FB620` is booted (iOS 26.5). |
| Prescribed simulator build with `/tmp/fiilsa-firebase-packages` | Failed before Fiilsa compilation: unresolved SwiftSyntax macro modules in `swift-perception` and `swift-case-paths`. |
| Fallback build with a fresh derived-data package graph | Failed with the same unresolved SwiftSyntax macro-module error. |
| Targeted Home/App/UI test invocation on the booted device | No final test-suite result before the harness wait limit; not counted as passing. |
| `xcrun swiftc -parse` on modified Swift files | Passed syntax parsing. |

This was an earlier environment failure only; it was superseded by the successful final build, install, launch, capture, and test runs recorded above.

## Follow-up: historical base-simulator runtime attempt (superseded)

| Command | Result |
|---|---|
| Serialized `xcodebuild test` for `HomeUITests` on `89410CC6-A661-4252-B810-0E54DE5FB620` | `testHomeCalendarAndQuestionRemainInHome` passed. `testHomeRendersTheFigmaQuestionAndAnswerState` and `testHomeFixtureStaysLightAfterTheAppStartupTask` failed at their shared initial `home.quoteCard` wait after test-host launch, before their individual assertions. |
| `xcrun simctl install` / `launch` known-good `/tmp/fiilsa-home-baseline-derived/.../Fiilsa.app` | Passed; direct launch reached the Home fixture. |
| `xcrun simctl io ... screenshot runtime-ios-default-light.png` | Passed; retained partial Home evidence at 402×874pt. |
| Follow-up build with the new state fixtures | Failed (exit 65) before Fiilsa compilation on unresolved package macro modules. |

The earlier fixture build failure is superseded by the current-build captures. Strict Figma QA remains `Blocked` only because the available iPhone 17 Pro runtime is 402×874pt rather than 360×821.

## Follow-up: captured-state review and final correction

- Reviewed six retained current-build captures: default light/dark, calendar-open light, question-done light, streak-tooltip light, and image-modal light.
- Corrected `HomeWeekStrip` so selected and completed days no longer share the purple-filled appearance: selected uses the Figma light/dark surface with primary text and purple outline; completed uses the purple fill with white text.
- Updated the standard Home UI-testing fixture to the Figma default 100-day streak and made the zero-streak fixture explicitly reset that state.
- Attempted the required rebuild with `/tmp/fiilsa-home-baseline-derived` and `/tmp/fiilsa-firebase-packages`; it exited 65 before Fiilsa compilation because `swift-perception`/`swift-case-paths` could not load SwiftSyntax macro modules. Therefore the two final corrections are not represented in recaptured runtime images.

This historical note is superseded by the successful final build, install, recapture, and test evidence.

## Final runtime evidence update

The final correction was subsequently rebuilt and captured successfully.

| Command/evidence | Result |
|---|---|
| `xcodebuild -quiet -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' -derivedDataPath /tmp/fiilsa-home-baseline-derived -clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages CODE_SIGNING_ALLOWED=NO build` | Passed (exit 0). |
| Install current app, then overwrite default/calendar-open/streak-tooltip/dark captures | Passed. The retained paths now represent the final current build. |
| Captures reviewed | `runtime-ios-default-light.png`, `runtime-ios-calendar-open-light.png`, `runtime-ios-question-done-light.png`, `runtime-ios-streak-tooltip-light.png`, `runtime-ios-image-modal-light.png`, `runtime-ios-default-dark.png`. |

The refreshed default light/dark captures show the Figma-default 100-day streak and outlined selected day; refreshed calendar-open and streak-tooltip captures confirm the corrected selected/completed distinction and zero-streak state. Question-done and image-modal remain current unaffected-state evidence.

Acceptance is still **Blocked**, not Pass: all available runtime captures are iPhone 17 Pro 402×874pt frames, while the Figma acceptance target is 360×821. This platform-target mismatch makes a strict full-frame Figma comparison invalid.

## Follow-up: quote-card accessibility assertion

Fresh serialized reproduction showed that `HomeUITests.testHomeRendersTheFigmaQuestionAndAnswerState` failed only at the initial `app.otherElements["home.quoteCard"]` assertion. In that same fixture run, `오늘의 질문`, `home.answer`, `home.answerRecord`, and `home.registerImage` were already present. Source inspection confirmed the root cause: `HomeQuoteCard` is a SwiftUI `Button`, while the UI test was querying the unrelated `otherElements` accessibility collection.

The smallest correction changes the two `home.quoteCard` UI-test queries to `app.buttons["home.quoteCard"]`. It does not change the product UI, layout, or fixture state.

| Command | Result |
|---|---|
| Targeted serialized `xcodebuild test ... -only-testing:FiilsaUITests/HomeUITests/testHomeRendersTheFigmaQuestionAndAnswerState ... -parallel-testing-enabled NO -maximum-parallel-testing-workers 1` on `89410CC6-A661-4252-B810-0E54DE5FB620` | Passed (exit 0). |
| Serialized `xcodebuild test ... -only-testing:FiilsaUITests/HomeUITests ... -parallel-testing-enabled NO -maximum-parallel-testing-workers 1` on the same simulator with `/tmp/fiilsa-home-baseline-derived` and `/tmp/fiilsa-firebase-packages` | Passed (exit 0). |

The strict visual acceptance remains **Blocked**: the retained current-build runtime captures are 402×874pt iPhone 17 Pro frames, whereas the Figma acceptance target is 360×821. The passing UI suite resolves the assertion-type defect only; it does not remove that platform-target limitation.

## Final reviewer evidence update

- Hid `HomeQuestionAnswerCard`'s native `TextEditor` scroll surface so dark mode renders the specified `#424242` answer field instead of the native editor background.
- Matched Figma toast `3110:34293` with a rounded dark rectangle and green confirmation icon. The normal 1.6-second dismissal remains intact; the existing question-done launch fixture alone retains the toast for capture.
- Rebuilt (exit 0), installed, and inspected current-build `runtime-ios-default-dark.png`, `runtime-ios-question-done-light.png`, `runtime-ios-question-toast-light.png`, and `runtime-ios-image-modal-light.png`.
- Root's fresh final `HomeFeatureTests` + `AppFeatureTests` and serialized `HomeUITests` both passed (exit 0). Local post-review rechecks also passed for `HomeFeatureTests` and serialized `HomeUITests` (exit 0). A combined AppFeature/HomeFeature/UI invocation returned exit 65 only because the test-host app launched `SplashFeature` without test values for its unrelated notification/push dependencies; Xcode identifies those two AppFeature failures as possible host-app false positives, so no Home source change was made.

The final strict acceptance state is **Blocked only by** the 402×874pt simulator viewport versus the 360×821 Figma target.

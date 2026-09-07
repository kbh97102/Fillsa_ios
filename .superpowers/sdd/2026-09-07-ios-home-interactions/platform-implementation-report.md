# iOS Home Interactions Implementation Report

## Status

Implementation is implemented, but acceptance is pending runtime evidence; current runtime visual acceptance is **Blocked**.

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
| `xcodebuild -quiet -project Fiilsa.xcodeproj -scheme Fiilsa -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages CODE_SIGNING_ALLOWED=NO build` | Blocked before app compilation: supplied package cache cannot resolve SwiftSyntax macro modules under Xcode 26.6. |
| `xcrun simctl list devices available` | Blocked: CoreSimulatorService connection invalid/refused; no simulator runtime/device set available. |
| Targeted `xcodebuild test` for `HomeFeatureTests`, `AppFeatureTests`, and `HomeUITests` | Blocked: the unavailable simulator service prevented a test result bundle from being produced. |
| `xcrun swiftc -parse` over the modified Swift sources | Passed syntax parsing. |
| `git diff --check` | Passed. |

Targeted Home/App and UI tests could not be completed because the simulator service is unavailable; runtime screenshot capture could not be attempted for the same reason.

## Capture paths

- Figma retained references: `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/`.
- Runtime captures: unavailable; see `docs/design-qa/2026-09-07-ios-home-interactions-qa.md`.

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

- Full-frame visual QA, dark-mode verification, UI-test execution, and build success remain blocked by the unavailable simulator service and the package-cache/Xcode macro dependency mismatch.
- The Home screen documents `Blocked`, not `Pass`; a working simulator and resolved dependencies are required for final acceptance.

## Follow-up: runtime/review fixes

### Review fixes

- Added explicit streak-load state so the purple outlined zero-streak warning is neither rendered nor actionable before a genuine streak result is available. A positive result also clears any visible zero-state tooltip.
- The tooltip's Calendar link now dismisses its Home overlay before selecting the existing Calendar tab.
- Calendar month arrows, menus, and reducer state are bounded to the supported start month through the current month. The year/month labels now use the rounded border and shadow visible in the retained Figma frame.
- Added regression coverage for pre-load warning suppression, positive-load tooltip cleanup, valid calendar selection/reload, outside dismissal, and month-range bounds.

### Runtime/build evidence

| Command | Result |
|---|---|
| `xcrun simctl list devices` | Passed: iPhone 17 Pro `89410CC6-A661-4252-B810-0E54DE5FB620` is booted (iOS 26.5). |
| Prescribed simulator build with `/tmp/fiilsa-firebase-packages` | Failed before Fiilsa compilation: unresolved SwiftSyntax macro modules in `swift-perception` and `swift-case-paths`. |
| Fallback build with a fresh derived-data package graph | Failed with the same unresolved SwiftSyntax macro-module error. |
| Targeted Home/App/UI test invocation on the booted device | No final test-suite result before the harness wait limit; not counted as passing. |
| `xcrun swiftc -parse` on modified Swift files | Passed syntax parsing. |

No build artifact was produced, so install/launch and the requested default/calendar/question/streak/light/dark runtime captures could not be performed. The QA record and screen status remain `Blocked` pending a compatible Swift package/Xcode environment.

## Follow-up: base-simulator runtime attempt

| Command | Result |
|---|---|
| Serialized `xcodebuild test` for `HomeUITests` on `89410CC6-A661-4252-B810-0E54DE5FB620` | `testHomeCalendarAndQuestionRemainInHome` passed. `testHomeRendersTheFigmaQuestionAndAnswerState` and `testHomeFixtureStaysLightAfterTheAppStartupTask` failed at their shared initial `home.quoteCard` wait after test-host launch, before their individual assertions. |
| `xcrun simctl install` / `launch` known-good `/tmp/fiilsa-home-baseline-derived/.../Fiilsa.app` | Passed; direct launch reached the Home fixture. |
| `xcrun simctl io ... screenshot runtime-ios-default-light.png` | Passed; retained partial Home evidence at 402×874pt. |
| Follow-up build with the new state fixtures | Failed (exit 65) before Fiilsa compilation on unresolved package macro modules. |

The direct capture cannot satisfy final Figma QA because the available iPhone 17 Pro runtime size is 402×874pt, not 360×821. The fixture build failure prevented current-build calendar-open, question-done/toast, streak-tooltip, image-modal, and dark captures. The screen and QA status therefore remain `Blocked`.

## Follow-up: captured-state review and final correction

- Reviewed six retained current-build captures: default light/dark, calendar-open light, question-done light, streak-tooltip light, and image-modal light.
- Corrected `HomeWeekStrip` so selected and completed days no longer share the purple-filled appearance: selected uses the Figma light/dark surface with primary text and purple outline; completed uses the purple fill with white text.
- Updated the standard Home UI-testing fixture to the Figma default 100-day streak and made the zero-streak fixture explicitly reset that state.
- Attempted the required rebuild with `/tmp/fiilsa-home-baseline-derived` and `/tmp/fiilsa-firebase-packages`; it exited 65 before Fiilsa compilation because `swift-perception`/`swift-case-paths` could not load SwiftSyntax macro modules. Therefore the two final corrections are not represented in recaptured runtime images.

Acceptance remains pending: the existing six captures are current-build partial evidence at 402×874pt, while the corrected final state needs a successful build, install, and recapture before it can be compared again.

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

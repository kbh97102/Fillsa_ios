# iOS Home Interactions Implementation Report

## Status

Implementation complete; runtime visual acceptance is **Blocked** on this host.

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

# Home Figma UI QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=2929-13556
- Target frames/nodes: `2929:13556` default Home, `3039:26518` dark Home, `3139:1501` calendar-open, `3110:33782` question flow, `2929:18871` streak tooltip, and `3223:5107` image flow.
- Full-frame reference images: `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/fillsa-home-default.png`, `fillsa-home-calendar-open.png`, `fillsa-home-question-flow.png`, `fillsa-home-streak-tooltip.png`, and `fillsa-home-image-flow.png`. Each retained Figma export includes the 360×821 root, status bar, safe area, bottom navigation, and home indicator/ad area.
- Runtime target: iPhone 17 Pro (`89410CC6-A661-4252-B810-0E54DE5FB620`), iOS 26.5, **402×874pt**. This differs from the required 360×821 Figma target; its evidence is therefore partial only.
- Runtime full-frame captures: `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/runtime-ios-default-light.png`, `runtime-ios-calendar-open-light.png`, `runtime-ios-question-done-light.png`, `runtime-ios-question-toast-light.png`, `runtime-ios-streak-tooltip-light.png`, `runtime-ios-image-modal-light.png`, and `runtime-ios-default-dark.png`. These seven current-build iPhone 17 Pro captures are partial evidence only because their 402×874 frame differs from Figma's 360×821 target.
- Crop boundaries: full 360×821 frames for every reference; no runtime crop exists.
- Comparison method: side-by-side visual inspection of retained Figma exports and the seven current-build full simulator captures. This remains partial evidence only: the viewport sizes differ, so an acceptance overlay is invalid.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| HomeInlineCalendar | `2929:16227`–`2929:16258` | open, month/year navigation, selected/disabled days | Blocked |
| HomeWeekStrip | `3204:2435` | selected day at right edge; genuine completion markers | Blocked |
| HomeQuestionAnswerCard | `3087:29376`, `3139:1399`, `3087:29378` | default, focused, recorded/edit | Blocked |
| Home toast | `3110:34293` | `답변을 기록했어요.` | Blocked |
| HomeStreakTooltip | `2929:19015`–`2929:19017` | zero-streak tooltip and Calendar link | Blocked |
| Existing quote/image actions | `2929:19645`, `2929:19784`, `3223:5107` | copy, like, image dialog | Blocked |
| Assembled Home | `2929:13556`, `3039:26518` | light/dark full frame | Blocked |

## Validation rounds

### Round 1

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Calendar open reference | The initial popup grid used 32pt vertical rows, leaving excess blank space compared with the 40pt Figma row rhythm. | Set the day grid to 32pt cells with 8pt row spacing; retain 248×335 popup bounds. | Component source review only; runtime comparison blocked. |
| Week strip reference | Selected day needed the same purple fill/white type treatment visible in the retained open-calendar frame, while selection still suppresses the completion badge. | Updated selected-state foreground/background; state resolver still prioritizes selected over completed. | Component source review only; runtime comparison blocked. |
| Question flow reference | Focus state requires a purple input outline; recorded state must not route to quote typing. | Added `@FocusState` outline, Home reducer session answer state, record toast, and edit action. | Component source review only; runtime comparison blocked. |
| Tooltip reference | Tooltip must be reachable only from zero streak and link to the existing Calendar tab. | Added reducer visibility state, outside-tap close layer, and `AppView` Calendar tab callback. | Component source review only; runtime comparison blocked. |

### Round 2

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Streak loading/zero state | `nil` had represented both an unresolved streak request and a confirmed zero, so the warning could be rendered/tapped before genuine data arrived. | Added explicit `isStreakStateLoaded`, gated rendering/taps, and dismisses a visible tooltip when a positive result arrives. | Source/reducer regression coverage added; current-build runtime capture blocked. |
| Tooltip Calendar link | The tab callback did not clear Home overlay state first. | Dispatch tooltip dismissal before selecting the existing Calendar tab. | Source/reducer regression coverage added; current-build runtime capture blocked. |
| Calendar bounds and selector visuals | Month controls could reach invalid months and selector labels lacked the reference surface. | Bound reducer/menu/arrow transitions to start month...current month; added bordered, shadowed rounded selector labels. | Source review only; current-build runtime capture blocked. |
| Warning icon | Zero-state warning was a gray filled system symbol, not the purple outlined reference appearance. | Replaced it with a purple outlined triangle. | Source review only; current-build runtime capture blocked. |

No further rounds were possible. The iPhone 17 Pro simulator is now booted and usable, but `xcodebuild` stops before compiling Fiilsa because the package graph cannot resolve `SwiftSyntax`, `SwiftSyntaxMacros`, `SwiftDiagnostics`, `SwiftSyntaxBuilder`, and `SwiftCompilerPlugin` for `swift-perception`/`swift-case-paths` under Xcode 26.6. No current app bundle is available to install or capture. The targeted test invocation compiled until the harness wait limit without emitting a test-suite result, so it is not counted as a pass.

### Round 3

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Known-good default Home, light | The installed fixture reaches Home and provides a retained full simulator frame, but the iPhone 17 Pro is 402×874pt rather than Figma's 360×821. Its top system chrome, available vertical space, and shared four-tab bar therefore cannot be acceptance-compared pixel-for-pixel. | No visual correction: changing target device or global navigation is out of Home scope. Retained the capture only as partial behavioral/layout evidence. | Partial evidence; not final acceptance. |
| Calendar/question interaction UI test | Serialized execution on the base device exercised the calendar and Home-session question flow. | No correction required from this test: `testHomeCalendarAndQuestionRemainInHome` passed. | Passed. |
| Shared Home fixture tests | `testHomeRendersTheFigmaQuestionAndAnswerState` and `testHomeFixtureStaysLightAfterTheAppStartupTask` both failed at the common `home.quoteCard` existence wait after Xcode launched the test-host app; neither reached its subsequent assertions. | No Home-assertion change made: direct `simctl` launch of the known-good app did render Home, while the Xcode-hosted launch did not expose the element. | Blocked test-host launch discrepancy; not counted as pass. |

The earlier follow-up fixture binary attempt exited 65 while resolving package macro modules; its incorrectly light-rendered dark capture was deleted rather than retained as false evidence. The separately retained Round 3 `runtime-ios-default-dark.png` is the valid current-build dark evidence listed above.

### Round 4

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Current-build default/calendar/streak/day strip | The six retained current-build captures exposed the selected day using the purple completed-day fill. Figma `3204:2435` and the calendar-open reference instead use a white (or dark surface) selected day with primary text and purple outline; only completed days are purple-filled. | Restored selected/completed visual distinction: selected uses `HomeFigmaPalette.cardBackground` plus primary text and purple outline; completed remains purple-filled with white text. | Source correction complete; recapture blocked by the follow-up build failure. |
| Default fixture streak | The generic Home UI-testing fixture did not model the Figma default 100-day streak. | The default fixture now has `isStreakStateLoaded = true` and `streakCount = 100`; the zero-streak fixture explicitly sets count to `nil`. | Source correction complete; recapture blocked by the follow-up build failure. |

The six current-build paths above are retained for reinspection. The final correction could not be rebuilt into a seventh artifact: the explicit rebuild command using `/tmp/fiilsa-home-baseline-derived` and `/tmp/fiilsa-firebase-packages` exited 65 in `swift-perception`/`swift-case-paths` macro compilation. It is therefore not valid to claim the Round 4 visual result as captured or accepted.

### Round 5

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Current corrected simulator build | Earlier Round 4 recapture was unavailable. | The current `cd7ed7b` source built successfully with the known-good derived-data path and was installed on the base iPhone 17 Pro. | Build passed (exit 0). |
| Default Home, light/dark | The selected day had previously been indistinguishable from a completed day, and the normal fixture did not show the Figma default streak. | Refreshed `runtime-ios-default-light.png` and `runtime-ios-default-dark.png` show the outlined selected 12th and 100-day header streak. | Partial runtime evidence verified. |
| Calendar-open and streak-tooltip | The final selected-day correction and zero-state warning needed runtime evidence. | Refreshed `runtime-ios-calendar-open-light.png` and `runtime-ios-streak-tooltip-light.png`; the popup remains visible, and the outlined purple warning/tooltip state is reachable. | Partial runtime evidence verified. |
| Question-done and image-modal | These Home states were unaffected by the last source correction. | Retained `runtime-ios-question-done-light.png` and `runtime-ios-image-modal-light.png` from the current build. | Partial runtime evidence verified. |

Build command: `xcodebuild -quiet -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' -derivedDataPath /tmp/fiilsa-home-baseline-derived -clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages CODE_SIGNING_ALLOWED=NO build` — exit 0. The current app was installed before the four affected captures were overwritten.

### Post-QA test correction (not a visual validation round)

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Quote-card UI assertion | The Home fixture rendered the question, answer, and its actions, but the test looked for `home.quoteCard` in `otherElements`. `HomeQuoteCard` is implemented as a SwiftUI `Button`, so that query could never find it. | Changed only the UI-test query to `app.buttons["home.quoteCard"]`; no rendered Home UI changed. | Targeted `testHomeRendersTheFigmaQuestionAndAnswerState` passed (exit 0), and the serialized `HomeUITests` suite passed (exit 0). |

Serialized suite command: `xcodebuild -quiet test -project Fiilsa.xcodeproj -scheme Fiilsa -only-testing:FiilsaUITests/HomeUITests -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' -derivedDataPath /tmp/fiilsa-home-baseline-derived -clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages CODE_SIGNING_ALLOWED=NO` — exit 0. The first sandboxed attempt could not write Xcode's shared module and SwiftPM caches; the rerun with access to those standard caches passed.

## Post-round-5 reviewer evidence update

This is a targeted evidence update, not a sixth visual validation round.

| Scope | Root cause/difference | Fix and current-build evidence | Result |
|---|---|---|---|
| Dark question editor | `TextEditor` retained its native scroll surface above the specified dark `#424242` field. | Hid the native scroll content background and kept the editor itself clear, so `HomeFigmaPalette.answerFieldBackground` owns the surface. Refreshed `runtime-ios-default-dark.png`. | Partial runtime evidence verified. |
| Recorded-answer toast `3110:34293` | The Home toast was text-only and Capsule-shaped. | Replaced it with the project’s rounded dark toast surface and green `checkmark.circle.fill`; retained `runtime-ios-question-toast-light.png` with a fixture-only dismissal guard. | Partial runtime evidence verified. |
| Selected-day current states | Question-done and image-modal evidence predated the final selected/completed distinction. | Refreshed `runtime-ios-question-done-light.png` and `runtime-ios-image-modal-light.png`; both show the outlined selected 12th. | Partial runtime evidence verified. |

The current simulator build passed (exit 0). Root's fresh final `HomeFeatureTests` plus `AppFeatureTests` and the serialized `HomeUITests` suite each passed (exit 0); local post-review rechecks also passed for `HomeFeatureTests` and serialized `HomeUITests` (exit 0). The normal production toast still dismisses after 1.6 seconds; only the guarded question-done capture fixture retains it for evidence.

## Final assembled-screen result

- Full-frame reference/capture comparison: Figma references are 360×821; retained runtime light capture is 402×874, so no valid full-frame overlay or side-by-side acceptance comparison can be produced.
- Final runtime capture: the seven paths listed above, including refreshed dark, question-done, image-modal, and visible question-toast evidence.
- Result: Blocked after round 5.
- Remaining differences: a 360×821 runtime target is required for final full-frame comparison. The iPhone 17 Pro's 402×874 viewport prevents strict Figma-frame acceptance; no product change is made for that platform-target limitation.

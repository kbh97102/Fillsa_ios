# Home Figma UI QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=2929-13556
- Target frames/nodes: `2929:13556` default Home, `3039:26518` dark Home, `3139:1501` calendar-open, `3110:33782` question flow, `2929:18871` streak tooltip, and `3223:5107` image flow.
- Full-frame reference images: `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/fillsa-home-default.png`, `fillsa-home-calendar-open.png`, `fillsa-home-question-flow.png`, `fillsa-home-streak-tooltip.png`, and `fillsa-home-image-flow.png`. Each retained Figma export includes the 360×821 root, status bar, safe area, bottom navigation, and home indicator/ad area.
- Runtime target: iOS simulator, 360×821, light and dark, default/calendar-open/question-focus/question-done-toast/streak-tooltip/image-modal states.
- Runtime full-frame capture: unavailable. `xcrun simctl list devices available` failed because CoreSimulatorService is disconnected.
- Crop boundaries: full 360×821 frames for every reference; no runtime crop exists.
- Comparison method: source-level component geometry/state review against the retained full-frame exports. This is partial evidence only, not final visual acceptance.

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

No further rounds were possible: no runtime app can be launched or captured. `xcrun simctl list devices available` reports a refused CoreSimulatorService connection. The requested simulator build is additionally blocked before app sources compile by unresolved `SwiftSyntax`, `SwiftSyntaxMacros`, `SwiftDiagnostics`, `SwiftSyntaxBuilder`, and `SwiftCompilerPlugin` modules in `/tmp/fiilsa-firebase-packages` under Xcode 26.6. The targeted test invocation could not yield an `.xcresult` because the simulator service is unavailable.

## Final assembled-screen result

- Full-frame reference/capture comparison: references listed above; runtime capture unavailable, so no overlay or side-by-side artifact can be produced.
- Final runtime capture: unavailable.
- Result: Blocked after round 1.
- Remaining differences: final runtime geometry, typography, system chrome, dark frame, image modal, and all interaction-state visuals require a working simulator. The deliberately preserved shared four-tab navigation also differs from the Figma three-tab composition, per screen scope.

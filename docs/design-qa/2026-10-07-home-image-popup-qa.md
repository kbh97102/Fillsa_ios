# Home image popup Figma UI QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=3223-4773
- Target nodes: full Home image-view frame `3223:4773`; `notice_popup` `3223:4966`; image background `3223:4967`.
- Full-frame reference image: `docs/design-qa/assets/home-responsive-layout/2026-09-27/figma-home-image-dialog.png` (360×821, light; includes root background, status bar, safe area, navigation and home indicator). Figma MCP design context and screenshots refreshed 2026-10-07 for both nodes.
- Popup reference: Figma child `3223:4966`, x=20, y=225, width=320, height=373 in the full frame.
- Runtime target: iPhone 17e, iOS 26.4 simulator, light, 390×844pt (1170×2532px); default gradient, local 640×80 wide and 80×640 tall solid red PNG fixtures. Fixture files: `Fiilsa/UITestFixtures/home-dialog-{wide,tall}.png`. The red fixtures make image fill and clipping measurable; Figma uses a photographic source image.
- Runtime full-frame captures: `docs/design-qa/assets/home-image-popup/2026-10-07/runtime-default.png`, `runtime-wide.png`, `runtime-tall.png` (same directory). Each contains root background, status bar, safe area, navigation and home indicator.
- Runtime video: `docs/design-qa/assets/home-image-popup/2026-10-07/runtime-tall-fixture.mp4` (5s, H.264, tall red test fixture visible).
- Crop boundaries: Figma full frame (0,0,360,821), popup (20,225,320,373). Runtime full frame (0,0,390,844), popup approximately (20,194.7,350,407.7) in points; screenshots are 3× scale.
- Comparison method: `docs/design-qa/assets/home-image-popup/2026-10-07/figma-vs-runtime-wide.png` side-by-side at 1pt per output pixel. Left is the Figma 360×821 frame, right is the 390×844 runtime frame. XCTest also compares the default/wide/tall confirmation button frames and checks loaded red pixels inside, absent outside.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Photo background | `3223:4967` | Loaded, cropped inside popup | Partial: wide/tall red images remain inside fixed visual boundary; source image differs from Figma photo |
| Dialog container | `3223:4966` | Stable 320:373 geometry regardless of source image | Partial: image changes do not resize the visual container at 390pt viewport |
| Assembled Home | `3223:4773` | Light with loaded image modal | Blocked: runtime viewport is 390×844 vs Figma 360×821, and fixture image differs |

## Validation rounds

### Round 1 — reproduction

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Dialog with 640×80 image | Before fix, accessibility frame reported 5624×703pt versus default approximately 350×408pt; visible layout and controls were displaced. | None yet | Fail; `FiilsaUITests/HomeUITests.swift::testImageDialogKeepsFrameForWideAndTallImages`, `docs/design-qa/assets/home-image-popup/2026-10-07/test-results.txt` |
| Dialog with 80×640 image | Before fix, accessibility frame reported 350×2800pt; controls were displaced. | None yet | Fail; same test/log |
| Full Home | Popup no longer matched the Figma 320:373 component ratio when image content controlled the container. | None yet | Fail for affected component |

The first iOS 26.5 runner attempt ended before tests with Mach error -308. The serial iOS 26.4 run executed the red test and confirmed the actual layout problem.

### Round 2 — fixed visual boundary

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Image/background `3223:4967` | `scaledToFill` image exceeded the parent layout proposal. | Explicit popup width from available screen width minus 40pt; height from Figma 373:320 ratio; image framed and clipped before layering controls. | Visual crop and control positions stable in runtime screenshot. XCTest's `dialog.frame` remained enlarged because SwiftUI exposed unclipped image bounds in the accessibility tree. |
| Assembled Home | Runtime screenshot shows the popup boundary at 20pt side insets and a constant 350×408pt visual frame. | None beyond component fix. | Partial; strict full-frame acceptance still unavailable. |

### Round 3 — image-present regression and capture

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Popup frame/control row | Wide/tall images should leave controls and exterior pixels unchanged; accessibility bounds are not a reliable visual measure for the filled image. | Regression compares confirmation button frame with default state and screenshot pixels inside/outside the default popup boundary. | Pass for targeted behavior and default aspect ratio: 2 UI tests, 0 failures, `docs/design-qa/assets/home-image-popup/2026-10-07/test-results.txt`. |
| Full Home against `3223:4773` | Figma 360×821 versus runtime 390×844; Figma photo versus red test fixture. Existing Home/nav and button proportions also differ in the side-by-side image. | No change; outside the image frame fix. | Blocked for strict full-frame Figma acceptance. |

## Final assembled-screen result

- Full-frame reference/capture comparison: Figma `docs/design-qa/assets/home-responsive-layout/2026-09-27/figma-home-image-dialog.png` versus runtime `docs/design-qa/assets/home-image-popup/2026-10-07/runtime-wide.png`; side-by-side `docs/design-qa/assets/home-image-popup/2026-10-07/figma-vs-runtime-wide.png`.
- Final runtime captures: `docs/design-qa/assets/home-image-popup/2026-10-07/runtime-{default,wide,tall}.png`.
- Result: **Blocked** for final assembled-screen Figma acceptance; targeted image frame regression passed on iPhone 17e iOS 26.4.
- Remaining differences: viewport 390×844 versus target 360×821; red test fixture versus target photo; underlying Home/nav and two equal-width popup action buttons differ from the Figma frame. These are recorded without changing unrelated UI in this task.

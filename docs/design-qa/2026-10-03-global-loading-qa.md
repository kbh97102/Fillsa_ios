# 전역 로딩 스피너 Figma UI QA

> 아래 14개 화면 기록은 2026-10-03 최초 적용 당시의 증거다. 이후 사용자 요청에 따라 Splash는 전역 스피너 적용 범위에서 제외되었다. 현재 범위와 검증 결과는 [Splash 제외 QA](2026-10-03-global-loading-splash-exclusion-qa.md)를 참고한다.

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%25E2%259C%2592%25EF%25B8%258F%25ED%2595%2584%25EC%2582%25AC?node-id=2929-5969&t=rysafF9DyBGoWDL9-11
- Target frames/nodes: `2929:5969` `loading` 360×720; `2929:5971` `progress_indicator_01` 120×120; `2929:5972` SVG layer.
- Full-frame reference image: [2026-10-03-global-loading-figma.png](2026-10-03-global-loading-figma.png), 360×720px, white root with status bar.
- Runtime target: iPhone 17 Pro simulator, iOS 26.5, 402×874pt (1206×2622px), light mode. All 14 routable screens use a launch-only fixture with global loading count 1; the Home comparison uses its existing Home fixture.
- Runtime full-frame capture: [2026-10-03-global-loading-runtime-iphone17pro.png](2026-10-03-global-loading-runtime-iphone17pro.png), full screen including status bar and bottom navigation.
- Runtime video: [2026-10-03-global-loading-home-720p.mp4](2026-10-03-global-loading-home-720p.mp4), 8-second H.264 simulator recording; [frame at 3 seconds](2026-10-03-global-loading-home-video-frame.png). This uses a fixed loading-count UI-test fixture, not a live API request.
- HTML comparison report: [2026-10-03-global-loading-video-report.html](2026-10-03-global-loading-video-report.html), with one PNG and MP4 per screen.
- Crop boundaries: both images full frame; spinner component centered in its own 120×120pt area. No crop used for acceptance.
- Comparison method: side-by-side visual inspection of the linked full frames; SVG source and downloaded Figma SVG SHA-256 comparison; XCUITest position and color-sample checks.
- User override: the white Figma root is replaced by a transparent overlay with `black` at alpha 0.2 over the active app screen, and all app touches are blocked.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Spinner ring | `2929:5971`, `2929:5972` | centered 120×120pt container, original 112×112pt SVG | Partial pass: original SVG SHA-256 matches, center verified on runtime |
| Full-screen dim | `2929:5969`, user override | black alpha 0.2 above Home, covers safe areas | Partial pass: sample at `(10,100)` changed from RGB `(255,239,204)` to `(204,191,163)` |
| Touch lock | user override | Home and popup do not receive touches | Partial pass: UI test tapping the covered quote card did not navigate |

## Screen coverage

`GlobalLoadingUITests.testSpinnerCoversEveryRoutableScreen` opens every row, checks a screen-specific accessibility marker, then checks that the spinner exists at the center of the app frame. Each row has an actual simulator PNG and MP4 in the [HTML report](2026-10-03-global-loading-video-report.html). The clips use a fixed loading count, not live network timing.

The inventory covers app-owned `AppScreen` destinations and the four main tabs. Native iOS permission alerts and the system Share Sheet are not Figma app screens and were not captured or certified for overlay touch blocking.

| Screen | Route | Runtime capture |
|---|---|---|
| Splash | `.splash` | [PNG](2026-10-03-global-loading-splash.png) · [MP4](2026-10-03-global-loading-splash.mp4) |
| Login | `.login` | [PNG](2026-10-03-global-loading-login.png) · [MP4](2026-10-03-global-loading-login.mp4) |
| Onboarding Guide | `.onboardingGuide` | [PNG](2026-10-03-global-loading-onboardingGuide.png) · [MP4](2026-10-03-global-loading-onboardingGuide.mp4) |
| Home | `.main` / `.home` | [PNG](2026-10-03-global-loading-runtime-iphone17pro.png) · [MP4](2026-10-03-global-loading-home-720p.mp4) |
| Quote List | `.main` / `.quoteList` | [PNG](2026-10-03-global-loading-quoteList.png) · [MP4](2026-10-03-global-loading-quoteList.mp4) |
| Calendar | `.main` / `.calendar` | [PNG](2026-10-03-global-loading-calendar.png) · [MP4](2026-10-03-global-loading-calendar.mp4) |
| My Page | `.main` / `.myPage` | [PNG](2026-10-03-global-loading-myPage.png) · [MP4](2026-10-03-global-loading-myPage.mp4) |
| Typing | `.typing` | [PNG](2026-10-03-global-loading-typing.png) · [MP4](2026-10-03-global-loading-typing.mp4) |
| Share | `.share` | [PNG](2026-10-03-global-loading-share.png) · [MP4](2026-10-03-global-loading-share.mp4) |
| Quote Detail | `.quoteDetail` | [PNG](2026-10-03-global-loading-quoteDetail.png) · [MP4](2026-10-03-global-loading-quoteDetail.mp4) |
| Memo Insert | `.memoInsert` | [PNG](2026-10-03-global-loading-memoInsert.png) · [MP4](2026-10-03-global-loading-memoInsert.mp4) |
| Notice | `.notice` | [PNG](2026-10-03-global-loading-notice.png) · [MP4](2026-10-03-global-loading-notice.mp4) |
| Notice Detail | `.noticeDetail` | [PNG](2026-10-03-global-loading-noticeDetail.png) · [MP4](2026-10-03-global-loading-noticeDetail.mp4) |
| Alert | `.alert` | [PNG](2026-10-03-global-loading-alert.png) · [MP4](2026-10-03-global-loading-alert.mp4) |

## Validation rounds

### Round 1

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Loading view | UI test could not find `globalLoading.spinner`: parent accessibility identifier replaced child identifier in the accessibility tree. | Removed the parent identifier. | Targeted UI test passed on rerun. |
| Spinner asset | Downloaded SVG and local asset both SHA-256 `cd427ee5076577901c248410fa01ccb2eb4dff0b9a714e67a6a4ad49590ccb6f`. | None. | Partial pass. |
| Dim, center, touch | Runtime spinner centered at app midpoint; RGB check matched black 20% over Home background; covered quote-card tap did not navigate. | None. | Partial pass. |
| Assembled full frame | Figma is a white 360×720 loading-only mock with old status bar; runtime is a 402×874 Home screen under the requested dim and a different system status bar. Pixel-for-pixel whole-screen acceptance is not possible from this reference. | Requires a Figma loading-over-Home frame at a matching viewport or explicit approval for component-level acceptance. | Blocked. |

### Round 2: all-screen evidence

| Scope | Difference | Fix | Result |
|---|---|---|---|
| 14 routes | Initial route test failed because only Home had a loading launch fixture; the other route names opened default startup without the spinner. | Added test-only route selection and a shared `activeLoadingCount = 1` state. | Route identity and centered-spinner test passed for all 14 on 2026-10-03. |
| Share | Its first-use description overlay added a second dim, obscuring the requested 20% comparison. | Disabled that description in the capture fixture through `settingsClient`; recaptured Share PNG/MP4. | Visual runtime evidence inspected. |
| Splash | Startup permission/push work could run during the fixed-loading capture. | Test-only dependencies skip the permission prompt and push synchronization. | Capture is stable; production flow unchanged. |
| Figma full frames | Only one common loading-only Figma frame exists for these 14 runtime compositions. | Kept the shared Figma component beside each runtime capture and labeled comparison scope. | `Blocked` for exact assembled-screen acceptance; no invented screen-specific Figma reference. |

### Round 3: typing keyboard touch boundary

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Typing | The system keyboard was visible above the app-root dim and could accept touches while the spinner was shown. The new targeted UI test failed at the keyboard-presence assertion before the fix. | Pass the shared loading state to the typing input; do not re-focus its `UITextView` while loading. | Loading-keyboard and normal no-loading keyboard tests passed; Typing PNG/MP4 were recaptured without the keyboard. |
| Home and other editors | SwiftUI `TextEditor` can keep a system keyboard above the root overlay when loading begins after focus. | At the shared `AppView` boundary, resign the current first responder when loading switches on. | Home focused-editor → loading → keyboard-dismissed UI test passed. Memo uses the same root handler but was not separately tapped in this round. |

## Verification

- Red: `HomeUITests.testGlobalLoadingDimsScreenAndBlocksHomeTouches` failed before implementation because the spinner was absent.
- Red: `GlobalLoadingUITests.testSpinnerCoversEveryRoutableScreen` failed for the missing screen fixture (2026-10-03); the first route test was a test-setup failure, not evidence of a production spinner failure.
- Green: same targeted UI test passed after the accessibility-ID correction (2026-10-03 20:42 KST).
- `AppFeatureTests.test_loadingCountControlsGlobalVisibility` passed (2026-10-03 20:41 KST).
- `HomeUITests.testHomeRendersTheFigmaQuestionAndAnswerState` passed with no loading overlay (2026-10-03 20:46 KST).
- Final targeted rerun after all-screen fixture refinement: route coverage, Home touch lock, and AppFeature loading-count tests all passed (`/tmp/fiilsa-global-loading-final.xcresult`, 3 passed, 0 failed, 2026-10-03 22:29 KST).
- Keyboard checks: Typing loading-keyboard test failed before the fix (`/tmp/fiilsa-typing-keyboard-red.xcresult`), then passed after the fix (`/tmp/fiilsa-typing-keyboard-green.xcresult`). Typing no-loading focus regression and loading-keyboard checks passed together (`/tmp/fiilsa-typing-keyboard-final.xcresult`); Home focused-editor dismissal passed (`/tmp/fiilsa-home-keyboard-final.xcresult`).
- Final combined targeted run on the last code revision: all 6 selected tests passed, 0 failed (`/tmp/fiilsa-global-loading-all-final.xcresult`, 2026-10-03 22:42 KST). This includes 14-route coverage, Home touch lock, Home keyboard dismissal, Typing keyboard-on/off behavior, and AppFeature loading count.
- All 14 MP4 files decoded to an image frame (13 route clips 2–3 seconds, Home clip 8 seconds). All 14 simulator screenshots were visually inspected for screen identity and centered spinner. The HTML has 14 video elements; every local `src`, `poster`, and file `href` resolves to a nonempty file.
- The Home MP4 decodes at 3 and 3.4 seconds; inspected frames show the ring in different orientations. The initial Home HTML/video/poster URLs returned HTTP 200 from a local server. In-app browser visual review was unavailable because no browser instance was connected; the expanded HTML was checked by file references, not visually rendered in a browser.
- Full test suite was not run, per request.

## Final assembled-screen result

- Full-frame reference/capture comparison: the shared Figma PNG and 14 runtime PNGs in the HTML report; spinner shape and center matched, but full-frame image contents intentionally differ under the requested overlay behavior.
- Final runtime captures: [14-screen HTML report](2026-10-03-global-loading-video-report.html).
- Result: Blocked for Figma full-frame acceptance after round 1; component and interaction checks are partial passes, not final UI acceptance.
- Remaining differences: Figma white background versus requested dim-over-current-screen; Figma 360×720 versus simulator 402×874; Figma mock status bar versus iPhone 17 Pro system status bar. Per-screen overlay composites are absent from Figma, so exact assembled-frame matching remains blocked for all 14.

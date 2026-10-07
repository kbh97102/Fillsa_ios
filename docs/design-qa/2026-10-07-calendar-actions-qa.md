# Calendar completed quote actions Figma UI QA

## Reference

- Figma: [Light `2987:22796`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796), action `2987:22949`–`2987:22975`; [Dark `3051:899`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3051-899), action `3051:1049`–`3051:1074`.
- Full-frame references: `assets/calendar-figma/2026-08-30-calendar-completed-2987-22796-reference.png` and `assets/calendar-figma/2026-09-20/calendar-handwriting-3051-899-reference.png`, 360×1101pt including background, status bar, safe area, navigation and home indicator.
- Runtime target: iPhone 17e, iOS 26.4, 390×844pt at 3×, Light/Dark `ui-testing-calendar-completed` fixture. The fixture supplies the quote/date; it is not a live server response.
- Full runtime captures: `assets/calendar-actions/2026-10-07/calendar-actions-light.png` and `assets/calendar-actions/2026-10-07/calendar-actions-dark.png`, 1170×2532px full display.
- Crop boundaries: Figma action row approximately `(20,617,320,43)` in its 360×1101pt frame; runtime approximately `(20,629,350,43)` in the 390×844pt display. The viewport width changes the assembled card width.
- Comparison method: side by side at native point size, Figma left and runtime right, top aligned with a 20pt gap: `assets/calendar-actions/2026-10-07/calendar-actions-light-comparison.png` and `assets/calendar-actions/2026-10-07/calendar-actions-dark-comparison.png`. The frames cannot be pixel overlaid as equal-size screens.
- Runtime video: `assets/calendar-actions/2026-10-07/calendar-actions-completed-light.mp4`, five seconds of the settled Light fixture. `file` reports ISO Media MP4 v2; sample entry `avc1` confirms H.264. This shows the implemented action row without a live server request.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Completed quote action row | Light `2987:22949`–`2987:22975`; Dark `3051:1049`–`3051:1074` | Selected completed day; copy/share/like/image | Partial visual comparison. Four buttons and Light/Dark text colors tested; exact-width comparison blocked by viewport. |
| Calendar assembled screen | `2987:22796`, `3051:899` | Light/Dark completed day | Blocked by viewport and preexisting calendar/full-screen differences below. |

## Validation rounds

### Round 1 — reproduction and action wiring

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Action row | The four Figma actions were inert image/text stacks without buttons or reducer actions. Red UI test recorded four missing buttons. | Added four buttons. Copy uses pasteboard, share uses the existing share route, and like/image use Home use cases and the existing image dialog. Async work captures the tapped `dailyQuoteSeq`. | UI tests find and tap all four buttons, navigate to share and open image dialog. Reducer tests cover like/image target stability. |

### Round 2 — component visual comparison

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Action row against Light/Dark reference | Initial runtime showed a filled action heart for the fixture's liked day; both Figma completed frames show an outline action heart while the date marker/count show a like. Dark camera was gray and divider was too light. | Kept the outline action heart; date marker/count carry the like state. Tinted camera Figma purple `#5C65FF` and used a darker divider in Dark mode. | Light/Dark action text pixel tests pass. Like success updates `likeYn`, month count and day marker after monthly refetch. |

### Round 3 — assembled capture

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Full Light/Dark screens | Figma is 360×1101pt; available runtime is 390×844pt. Figma shows the complete editor, CTA and advertisement; the shorter runtime clips lower content. Card widths and calendar weekday positions differ. Figma labels March 2025 but its date grid differs from the Gregorian March 2025 runtime grid. | Captured full Light/Dark displays and side-by-side images. These assembled differences are outside the requested action wiring. | Final full-screen visual result Blocked. |

## Behavior and tests

- Separate iPhone 17e iOS 26.4 simulator: `CalendarFeatureTests` 9/9 and `CalendarUITests` 6/6; `xcodebuild` reported `TEST SUCCEEDED`. Persistent summary: `assets/calendar-actions/2026-10-07/calendar-actions-tests.txt`; full local bundle: `.artifacts/calendar-actions-verified.xcresult`.
- The like reducer test switches selected day during the request, then verifies the original quote sequence/date, the refreshed count of 2, and heart marker on the originally tapped day. The image test checks its fixed upload target and temporary JPEG deletion.
- Reading the clipboard directly from the XCTest runner invoked the iOS cross-app paste permission sheet. The final UI suite taps Copy without reading from the runner; a separate `xcrun simctl pbpaste` returned the selected quote and author string (`영광은 먼지와 땀과 피로 얼굴이 얼룩진 채 경기장에 서 있는 사람의 것이다. - `), confirming the pasteboard effect on the fixture simulator.
- Live authentication, like API, image upload/delete API and photo picker were not exercised against a server. The dialog UI fixture uses a local signed-in response.

## Final assembled-screen result

- Full-frame comparison: `assets/calendar-actions/2026-10-07/calendar-actions-light-comparison.png` and `assets/calendar-actions/2026-10-07/calendar-actions-dark-comparison.png`.
- Final runtime captures: `assets/calendar-actions/2026-10-07/calendar-actions-light.png` and `assets/calendar-actions/2026-10-07/calendar-actions-dark.png`.
- Result: **Blocked for final Figma visual acceptance after round 3**; behavior tests pass. Exact whole-screen acceptance needs a matching 360×1101pt runtime or a target frame for the available device, plus resolution of the existing calendar grid/full-screen differences.

# Calendar Figma UI QA · 2026-10-11

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796
- Target frames/nodes: Light incomplete `2985:21952` (360×816), Light completed `2987:22796` (360×1101), Dark completed `3051:899` (360×1101); month grid, selected quote and action row inside each frame.
- Full-frame references: `assets/ios-qa-preplan-2026-10-09/figma-calendar-incomplete.png`, `assets/ios-qa-preplan-2026-10-09/figma-calendar-completed.png`, `assets/calendar-figma/2026-09-20/calendar-handwriting-3051-899-reference.png`.
- Runtime: iPhone 17e / iOS 26.5 Simulator, 390×844pt; March 2025 fixture, incomplete and completed dates, Light/Dark.
- Full-frame captures: `assets/ios-qa-2026-10-11/calendar-incomplete-light.png`, `assets/ios-qa-2026-10-11/calendar-completed-light.png`, `assets/ios-qa-2026-10-11/calendar-completed-dark.png` (1170×2532 pixels at 3×).
- Comparisons: same basename with `-side-by-side.png` in `assets/ios-qa-2026-10-11/`; left Figma, right runtime, both at 1 pixel per point with a 12pt gap. Crop bounds are the entire Figma frame `(0,0,360,816)` or `(0,0,360,1101)` and runtime frame `(0,0,390,844)`.

## Component inventory

| Component | Figma node | Target state | Result |
|---|---|---|---|
| `CalendarMonthSection` / `CalendarDayCell` | `2985:21952`, `2987:22796`, `3051:899` | 7 columns, month and selection | Partial: flexible columns and padding-based row heights render. March 2025 cells differ from Figma's enabled appearance because the app's June 2025 minimum date still applies. |
| `CalendarSelectedDaySection` | same frames | incomplete/completed card | Partial: Bold 14pt notice, purple incomplete outline, content-driven card height. |
| `CalendarQuoteActionRow` | `2987:22796`, `3051:899` | member/guest actions | Partial: one-line action labels, Light `#E7E2D8` and Dark gray divider. |
| Full Calendar | same frames | assembled screen | Blocked: frame sizes and supported historical-date state differ. |

## Validation rounds

| Round | Scope and evidence | Difference | Correction/result |
|---|---|---|---|
| 1 | Initial 390pt Light captures against both Figma frames | Fixed 320pt card/36pt cells did not use parent width; incomplete card too short; completed ‘이미지 등록’ wrapped. | Flexible grid, parent width and child padding; card vertical padding; no-wrap action labels. Partial. |
| 2 | Light incomplete/completed and Dark completed captures | Dark action divider appeared much brighter than Figma. | Dynamic divider: Light `#E7E2D8`, Dark `#616161`; recaptured Dark. Partial. |
| 3 | Final full-frame side-by-side images | Figma uses 360pt width and longer completed scroll frame; runtime is 390×844pt. Figma March 2025 dates are enabled, but `FillsaCalendarDateSupport.startDay/startMonth` restrict the app to June 2025 onward. Fixture quote/selected day also differs from illustrative Figma data. | Blocked. Kept the existing date boundary because changing selectable history affects product behavior beyond the requested padding/visual QA. |

## Action behavior evidence

- On iPhone 17e / iOS 26.5, `CalendarFeatureTests`, member completed action UI test, guest completed action UI test and theme/layout tests were included in a 17-test run with 17 passed, 0 failed (`/tmp/fiilsa-iosqa-dd/Logs/Test/Test-Fiilsa-2026.10.11_14-26-34-+0900.xcresult`).
- Member fixture: copy button tapped and share screen opened; separate image action UI test passed in the earlier run. Guest fixture: copy button tapped, image action showed login prompt, share screen opened.
- The test runner could not read the clipboard value in an earlier attempt. Real account/session and server-backed QA data were not reproduced, so the reported action failure's cause is still unknown. No product action logic was changed on fixture-only evidence.

## Final assembled-screen result

- Full-frame comparisons: `assets/ios-qa-2026-10-11/calendar-incomplete-light-side-by-side.png`, `assets/ios-qa-2026-10-11/calendar-completed-light-side-by-side.png`, `assets/ios-qa-2026-10-11/calendar-completed-dark-side-by-side.png`.
- Final runtime captures: the three source PNGs listed above.
- Result: **Blocked**. Same-size, same-data full-frame Figma comparison is unavailable.
- Remaining differences: historical-date enabled appearance, illustrative selected-day data, 360pt versus 390pt viewport, completed 1101pt Figma scroll canvas versus 844pt simulator viewport; real-session copy/share/image failure remains unconfirmed. The Figma ad strip is intentionally absent under the existing screen plan.

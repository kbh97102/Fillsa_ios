# Home weekly quote cache QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=2929-13556
- Target frames/nodes: assembled Home `2929:13556`, rolling date strip `3204:2435`, quote card in the same Home frame.
- Full-frame reference image: [saved Figma Home default](assets/home-figma-2929-17193/2026-09-07/fillsa-home-default.png), 360×821pt design. Current `get_design_context` for `3204:2435` returned “This app connection requires reauthentication”; no current MCP export was available.
- Runtime target: iPhone 17 Pro, iOS 26.4.1 simulator, 402×874pt, Light, local seven-day fixture (`-ui-testing-home -ui-testing-home-weekly-cache`).
- Runtime full-frame captures: [date 16](assets/home-weekly-cache-2026-10-07/runtime-initial.png), [date 15](assets/home-weekly-cache-2026-10-07/runtime-date-15.png), [date 14](assets/home-weekly-cache-2026-10-07/runtime-date-14.png). Each PNG is 1206×2622 pixels, including status bar and home indicator.
- Video: [five-second H.264 MP4](assets/home-weekly-cache-2026-10-07/date-navigation.mp4). It stitches three full-frame screenshots extracted from a passing simulator UI-test recording (16→15→14). It shows fixture UI states, not continuous taps or live API traffic, and supplies no latency measurements. `file` identifies the output as MP4 v2.
- Crop boundaries: full frame for all three runtime captures; no crop or overlay applied.
- Comparison method: runtime fixture frames inspected for selected-date/quote changes and absence of the loading spinner. Exact Figma overlay is unavailable because the active Figma connection needs reauthentication and target/runtime point sizes differ.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Rolling date strip | `3204:2435` | selected date stays at the right edge while moving 16→15→14 | Fixture UI test pass; exact Figma comparison Blocked |
| Quote card | `2929:13556` child | date-specific quote changes from cached day | Fixture UI test pass; exact Figma comparison Blocked |
| Global loading overlay | `2929:5969` | absent during cached date selection | Fixture UI test pass; full visual comparison Blocked |

## Validation rounds

### Round 1

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Home strip and quote with weekly fixture | UI test initially swiped the quote card and opened Typing. | Used the existing date-strip buttons in the test; no production UI code changed. | Date 16→15→14 and quote changes pass. |
| Assembled Home versus Figma | Figma MCP connection requires reauthentication; runtime 402×874pt differs from 360×821pt reference. | No visual changes made. | Blocked for exact Figma acceptance. |

## Request count and data validation

- Member first load: one `GET /api/v2/member-quotes/weekly` with no `endDate` query, plus the existing separate streak request. URLProtocol request-contract test checks the weekly path/query; reducer test checks first-load selection.
- Cached seven-day window: date movement starts zero feed requests. Boundary crossing starts one weekly request with server-anchored `endDate`; returning to an already cached window starts zero. These are local TestStore counts, not production network timing.
- Previously, each Home date selection called member v2 daily once. For six moves inside one received window the code-derived count changes from six daily requests to zero; no elapsed-time reduction is asserted.
- Guest path remains v1 daily. Member v2 daily remains a fallback if a weekly payload omits the selected date. Date-keyed daily results cannot overwrite a newer selection.
- Answer, like, image upload, and image deletion change the matching cached day. A save/upload completed after moving to another date does not replace the currently visible day. Quote `dailyQuoteSeq == 0` retains the existing action guards.
- Server request/processing latency and user-perceived wait time were not measured with an authenticated production account. The Debug `API timing` log can record request and decode phases in a real QA session; server-side timings must be supplied separately.

## Final assembled-screen result

- Full-frame reference/capture comparison: [saved Figma reference](assets/home-figma-2929-17193/2026-09-07/fillsa-home-default.png) and three runtime captures above. A strict same-size, same-data overlay was unavailable.
- Final runtime capture: [date 14](assets/home-weekly-cache-2026-10-07/runtime-date-14.png).
- Result: **Blocked** for Figma visual acceptance. Data/request-count tests and fixture UI test pass.
- Remaining differences: current Figma export unavailable; runtime viewport 402×874pt versus Figma 360×821pt; fixture copy is not the Figma sample content.

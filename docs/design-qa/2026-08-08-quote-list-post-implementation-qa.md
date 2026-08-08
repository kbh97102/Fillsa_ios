# Quote List Post-implementation Design QA

**Date:** 2026-08-08
**Scope:** Quote List only; ads and common streak/bottom-navigation implementation are excluded from change scope.
**Reference:** Figma `2438:7653` (light calendar-open), `2438:8913` (dark list), `2438:8482` / `2438:8457` (condition empty state).

## Evidence

- Built this worktree with isolated DerivedData: `xcodebuild build -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -derivedDataPath /private/tmp/quote-list-qa-derived` → `BUILD SUCCEEDED`.
- Installed that exact app build and launched deterministic states with `-uiTestingQuoteList`, `-uiTestingDark`, `-uiTestingQuoteListFilteredEmpty`, and `-uiTestingQuoteListGeneralEmpty`.
- Captures inspected locally:
  - `/private/tmp/quote-list-light.png`
  - `/private/tmp/quote-list-dark.png`
  - `/private/tmp/quote-list-filtered-empty.png`
  - `/private/tmp/quote-list-general-empty.png`
  - Figma references: `/private/tmp/figma-quote-list-light-overlay.png`, `/private/tmp/figma-quote-list-dark.png`, `/private/tmp/figma-quote-list-filtered-empty.png`.

## Result summary

| Severity | Count | Result |
|---|---:|---|
| P0 | 1 | Dark-mode card rendering is visually broken. |
| P1 | 4 | Figma parity defects in assets, empty-state color, fallback/photo treatment, and unverified overlay rendering. |
| P2 | 1 | Fixture data differs from the Figma sample state. |

## Verified matches

- Light background is `yellow01`-family and dark background is `gray700`-family, matching the supplied frames.
- Selector geometry is 320×40 with the expected 20pt side inset. Its light surface is `yellow01`; dark surface is `gray600`.
- The Figma `2438:8482` calendar-with-question-mark vector is present in `quote_list_empty_calendar.imageset`, and the filtered empty capture renders that calendar/question-mark composition.
- Filtered empty copy matches Figma exactly: `조회 결과가 없어요 :(` and `기간을 다시 선택해주세요.`
- No ad label, ad slot, or blank ad spacer is present in the iOS Quote List captures.
- Source layout fixes cards to 150×200 with a 38pt header, 162pt body, and 20pt grid gap. The focused UI test also asserts those values.

## Findings

### P0 — Dark card content collapses / is clipped

- **Figma:** `2438:8913` shows two complete 150×200 cards per row: date header, photo, dimmed quote body, pager indicators, and badges.
- **Observed:** In `/private/tmp/quote-list-dark.png`, both cards render as narrow vertical fragments; date and quote text are absent and the visual card width is not 150pt. This is a release-blocking dark-mode regression despite the fixed-frame source declarations.
- **Files to inspect/fix:** `Fiilsa/Presentation/QuoteList/QuoteListSection.swift`, `Fiilsa/Presentation/QuoteList/QuoteListItem.swift`, and the dark-mode layout path in `QuoteListView.swift`.
- **Acceptance:** Capture two full-width 150×200 cards at x=20 and x=190 on a 360pt reference canvas, with a 20pt gap, in both themes.

### P1 — Card fallback is not a Figma asset and does not model the Figma photo state

- **Figma:** Both `2438:7653` and `2438:8913` cards use a photographic fill beneath the quote body.
- **Observed:** Deterministic light capture renders the existing pink/yellow gradient fallback. It is visibly different from the Figma photo reference. The actual-photo branch now correctly applies a 30% dim, but the QA fixture cannot validate that branch and the fallback has no approved Figma source asset.
- **Files to inspect/fix:** `Fiilsa/Presentation/QuoteList/QuoteListItem.swift`; add a committed Figma-sourced fallback asset if a no-image state must be represented.
- **Acceptance:** Real image uses only a 30% `gray700` overlay; no-image state uses a designer-approved Figma asset/state rather than an invented gradient.

### P1 — General empty icon is custom, not the Figma `lucide:book-dashed` vector

- **Figma:** General empty node `2438:8428` is a 100×100 book-dashed + question-mark asset.
- **Observed:** `/private/tmp/quote-list-general-empty.png` uses a rounded dashed rectangle with a question mark. The copy is correct but the icon silhouette and dashed geometry differ materially.
- **Files to inspect/fix:** `Fiilsa/Presentation/QuoteList/QuoteListEmptySection.swift`; add a Figma export in the Asset Catalog and render it as `Image`.

### P1 — Filtered-empty title color differs from Figma

- **Figma:** `조회 결과가 없어요 :(` is purple (`#5C65FF`) in `2438:8457`.
- **Observed:** The same title is near-black in the light deterministic capture; only the vector is purple.
- **Files to inspect/fix:** `Fiilsa/Presentation/QuoteList/QuoteListEmptySection.swift` (`titleColor` for `.searchResult`).
- **Acceptance:** Use `FillsaColor.purple01` in light mode and the matching Figma dark-mode text token in dark mode.

### P1 — Overlay behavior has automated coverage but no visual capture in this QA pass

- **Figma:** `2438:7653` places the calendar immediately below the selector (top 150 on the 360pt frame), above the unchanged grid beginning at y=543.
- **Source/test evidence:** `QuoteListView` uses `.overlay(alignment: .top)` and `QuoteListUITests.testDateOverlayDoesNotMoveCardsAndClosesFromOutsideTap` covers open, unchanged card `minY`, and outside-tap closure.
- **Gap:** Simulator CLI cannot inject a touch into the running app, so this QA pass has no independently captured app image of the open overlay. It must be visually rechecked after the dark-card P0 fix.
- **Files to inspect if it fails:** `Fiilsa/Presentation/QuoteList/QuoteListView.swift`, `QuoteListDurationCalendarSection.swift`.

### P2 — Deterministic data does not equal the Figma sample selection

- **Figma:** Date text `2025.03.17 - 2025.03.23`, selected like checkbox, and photo-backed `2025.03.25` cards.
- **Observed:** Test fixture uses `2026.02.08 - 2026.08.08`, unselected like state, and 2026 sample cards. This is acceptable for deterministic automation but unsuitable for pixel-reference screenshots.
- **Files to inspect/fix:** test-only launch fixture in `Fiilsa/FiilsaApp.swift` and `QuoteListSampleData.swift`.
- **Acceptance:** Supply an explicit Figma-equivalent UI-test fixture when pixel comparison is required; do not change production copy/data merely to satisfy a test image.

## Follow-up priority

1. Resolve the P0 dark card layout and capture light/dark grids again.
2. Replace the general-empty custom icon and correct filtered-empty title color.
3. Establish a Figma-approved no-image fallback or test fixture for photo/dim visual QA.
4. Capture the open date overlay after the P0 fix and confirm its y-position and close behavior visually.

# Home Figma UI QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=2929-13556
- Target frames/nodes: `2929:13556` (`2.home`); metadata reports 360×821, although the implementation request listed 360×720.
- Dark target frame/node: `3039:26518` (`2.home`, 360×821); `2929:9603` is a parent section, not a render target.
- Light typing target: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%E2%9C%92%EF%B8%8F%ED%95%84%EC%82%AC?node-id=2929-17920 (`2929:17920`, 360×720).
- Full-frame reference image: `docs/design-qa/assets/home-figma/2026-08-29-home-figma-reference.png` (360×821; root background, status bar, safe area, bottom navigation, and ad area included).
- Light typing reference image: `docs/design-qa/assets/home-figma/2026-09-20-typing-light-2929-17920.png` (360×720).
- Runtime target: iOS Simulator, light state, deterministic Home quote state (pending).
- Runtime full-frame capture: unavailable — CoreSimulatorService could not be reached on 2026-08-29.
- Crop boundaries: reference full frame `0,0,360,821`; runtime capture pending.
- Comparison method: component and assembled full-frame side-by-side/overlay after a simulator becomes available.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Status/top surface | `2929:13557`, `2929:15476` | Light | Pending |
| Date controls | `2929:17013`, `2929:17161`, `2929:17154`, `2929:13653` | One completed date, current date selected | Pending |
| Locale prompt | `2929:15520` | Korean selected | Pending |
| Quote card | `2929:13642` | Light/default quote | Pending |
| Quote actions | `2929:15521` | Not liked | Pending |
| Question/answer | `2929:13630` | Empty answer | Pending |
| Light typing save button | `3087:28769` | white fill, `#212121` border/label, 8pt radius | 부분 통과 — UI pixel test 통과 |
| Bottom navigation/ad | `3087:29254`, `3087:29249` | Home selected; static ad | Blocked — Figma has 3 × 120pt items; existing app preserves 4 × 90pt items including QuoteList by approved scope |

## Validation rounds

### Round 1

| Scope | Difference | Fix | Result |
|---|---|---|---|
| RED runtime frame | The focused Home UI test could not launch on a simulator because CoreSimulatorService was unavailable; no runtime screenshot could be produced. | Retry from a host with an available iOS Simulator after implementation. | Blocked |
| Bottom navigation | Figma node `3087:29254` has Home/Calendar/My page only, while the existing shared navigation includes QuoteList as a fourth destination. | Not changed: removing or redesigning shared navigation is out of this Home-only task scope. | Blocked |
| Build | `xcodebuild` stopped before compiling the app because the existing Swift package checkout could not resolve `SwiftSyntax`/macro dependencies. | Re-resolve the package graph from a healthy Xcode/Simulator environment, then run the focused Home UI test. | Blocked |

### Round 2

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Home UI test fixture | `-ui-testing-home` reached `AppFeature.task`, which could reload persisted theme/session state after the deterministic launch state was installed. | Added the test argument to the startup-effect exclusion guard and added a UI test that verifies the post-startup light background. | Pending runtime verification |
| Home feedback | The Figma layout rewrite had removed rendering/dismissal of the existing `toastMessage` state. | Restored the prior toast presentation and 1.6-second `toastDismissed` lifecycle. | Pending runtime verification |
| Like action | The Figma action row always rendered the static outline-heart asset. | Reused the existing `HeartActionIcon` with `isLike` to render filled/outlined live state while retaining the same toggle action. | Pending runtime verification |

### Round 3

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Week strip completion | Earlier selected dates were displayed as completed without a completion source. | `HomeFeature` now receives only actual local `StreakInfo` records through `StreakClient.getAllLocal()` and exposes only records with `isDailyWritingCompleted == true`. | Pending runtime verification |
| Header streak | Header did not receive a streak value. | `HomeFeature` loads `StreakClient.getCurrentCount()` and passes a positive genuine count to `HomeHeader`; unavailable/zero values render no streak detail. | Pending runtime verification |
| Completion badge/date key | Completed dates lacked the Figma `2929:17161` badge and used a hard-coded KST date formatter. | `HomeWeekStrip` overlays the downloaded `home_completed_streak` 18×18 Figma asset only for genuine, non-selected completed dates. `HomeCompletionDateKey` uses injected `Calendar.current`, matching SQLiteLocalStore date semantics. | Pending runtime verification |
| Selected/completed priority | A selected date that was also complete used the completed purple background, creating a hybrid state. | `HomeWeekStripDayState` resolves selected before completed: white selected background, gray selected text, purple border, and no completion badge. | Pending runtime verification |
| Quote card/action row | Figma nodes `2929:13642` and `2929:15503` were not represented by explicitly named Home Figma components. | `HomeQuoteCard` uses the persisted texture/search assets, preserves author navigation and previous/next semantics (today blocks forward). `HomeQuoteActionRow` uses 16pt local action assets, 42pt row/dividers, and the existing live like/copy/share/image actions. | Pending runtime verification |
| Question/answer CTA | Figma node `2929:13630` needs a bounded answer input and explicit component ownership. | `HomeQuestionAnswerCard` keeps the durable `home_answer_record` asset, Figma 174pt box/17pt radius/border/count, 200 extended-grapheme limit, and accessibility. The CTA uses only the existing parameterless quote-typing route; entered text is not transferred or saved. | Pending runtime verification |
| Question data | No Home question endpoint/state exists. | Kept the already-established Figma prompt; no backend question source was fabricated. | Blocked — product/API contract required |

### Round 4

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Answer handoff/storage scope | `TypingFeature.korTyping` and the available memo storage are quote-specific, while Home has no generic prompt-answer model, repository, local schema, or API contract. | Removed the answer-to-typing handoff. The Figma input remains UI-only and CTA follows existing parameterless typing navigation. A future answer feature requires a stable question/date identifier, record lifecycle and persistence/API ownership, editor/save UX, and feedback rules as a separately approved scope. | Blocked — product/data contract required |
| Bottom navigation metrics/assets | The Figma 3-tab bar uses 120×60pt items, 32pt Home/Calendar/My page glyphs, #5C65FF selection, and #212121 unselected treatment. | Retained the four shared routes. The three common light-tab glyphs now reuse the already-durable Figma `home_nav_*` assets at 32pt as template images, so selection tint works without asset recreation. QuoteList remains the established fourth item. | Blocked — a product decision is required to change tab count/routes; runtime comparison pending |
| Ad surface | Figma `3087:29249` is a 35pt static “AD / 광고가 들어가는 영역입니다.” surface, not an ad-provider specification. | Kept existing `HomeAdSurface`; no provider, behavior, or asset was invented. | Blocked — ad product contract required for behavior beyond the static surface |

### Round 5 — Dark Home `3039:26518`

| Scope | Difference / contract | Fix | Result |
|---|---|---|---|
| Dark palette | Root `#212121`; quote card and answer field `#424242`; outlines/dividers `#616161`; primary text `#FFFFFF`; action text `#E0E0E0`; inactive weekday/placeholder/count `#9E9E9E`; main divider has 55% opacity. Selected weekday, completed weekday, white calendar, and purple CTA retain their Figma states. | Added the testable `HomeFigmaPalette`, then applied it to Home root/header/prompt/quote card/actions/question input/ad. A pure palette test locks the dark token mapping. | GREEN — focused Home test suite 7/7 |
| Dark Figma vectors | The dark frame uses visually different logo/profile/search/action/texture vectors; light SVG bytes would not match. | Downloaded Figma `3039:26518` SVG bytes and committed universal 1× `luminosity=dark` asset-catalog appearances for `home_logo`, `home_profile`, `home_quote_texture`, `home_author_search`, `home_action_copy`, `home_action_share`, `home_action_like`, and `home_action_camera`. | Asset catalog builds successfully |
| Runtime full frame | A deterministic dark fixture is required to inspect the full device frame without altering normal navigation. | `-ui-testing-home ui-testing-theme-dark` now selects only the existing isolated Home fixture's dark app theme; normal launch behavior is unchanged. Build succeeded, but `simctl install/launch/screenshot` failed before installation with `CoreSimulatorService connection refused` / `simdiskimaged ... not responding`. No service was killed or reconfigured. | Blocked — no dark runtime capture can be produced in this environment |

### Round 6 — Light typing `2929:17920`

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Save button `3087:28769` | 공통 버튼의 테두리가 흰색으로 고정되어 Light의 `#212121` 테두리와 다름 | Light/Dark appearance에 따라 기존 테두리 색상만 전환 | 부분 통과 — `testLightTypingSaveButtonUsesDarkBorder` 및 dark 회귀 테스트 통과, 전체 프레임 비교는 사용자 검증 대기 |

## Final assembled-screen result

- Full-frame reference/capture comparison: reference available at the recorded persistent path; runtime capture unavailable.
- Final runtime capture: unavailable; attempted dark capture target was `/private/tmp/fiilsa-home-dark-3039-26518-runtime.png`, but the simulator connection failed before that file could be created.
- Result: Blocked
- Remaining differences: the assembled dark runtime frame still needs a full 360×821-equivalent simulator/device capture after CoreSimulatorService recovery; the 3-item Figma bottom navigation differs intentionally from the existing 4-item shared app navigation (QuoteList retained). The UI-only question answer and unavailable Home-question data contract remain the existing product/data blockers.

# Home·Calendar 답변 저장 Figma UI QA

## Reference

- Figma URL: [Home 질문 흐름](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3110-33782), [Calendar Light](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796), [Calendar Dark](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3051-899)
- Target frames/nodes: Home `3110:33783`, `3110:34152`, `3110:34293`, `3110:34438` (360×821pt); Calendar `2987:22796`, `3051:899` (360×1101pt).
- Full-frame reference image: Figma MCP `get_design_context` for `3110:34293` and `3051:899`; existing durable reference assets in `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/` and `docs/design-qa/assets/calendar-figma/2026-09-20/`.
- Runtime target: iPhone 17e simulator, iOS 26.5, Light, 390×844pt, completed selected date with a saved-answer **fixture**. Dark and authenticated runtime states remain pending.
- Runtime full-frame capture: [`assets/calendar-answer-2026-10-07/calendar-answer-saved-fixture.png`](assets/calendar-answer-2026-10-07/calendar-answer-saved-fixture.png), 1170×2532px screenshot of the scrolled viewport. [Five-second H.264 MP4 fixture video](assets/calendar-answer-2026-10-07/calendar-answer-saved-fixture.mp4).
- Crop boundaries: runtime full 390×844pt viewport after scrolling to the completed card; Figma completed frames are 360×1101pt full scroll content. These boundaries do not support strict full-frame acceptance.
- Comparison method: visual inspection of the existing completed card and saved-answer state; no coordinate overlay because viewport sizes and scroll bounds differ.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Home question card | `3110:33783`, `3110:34152`, `3110:34438` | empty, editing, saved | Pending |
| Home success toast | `3110:34293` | server-confirmed save | Pending |
| Calendar completed question card | `2987:22796`, `3051:899` | empty, editing, saved | Data binding/reducer tests passed; runtime comparison pending |

## Validation rounds

### Round 1

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Components and assembled screens | Pending runtime capture | Pending | Pending |

The saved fixture capture shows the selected-date quote, question, recorded answer, 0/200 counter, and edit button inside the existing Calendar card. It uses no live server response. The full Figma frame cannot be overlaid on this 390×844pt scrolled viewport, so this is partial evidence only.

### Calendar answer implementation evidence

- The v2 monthly record now retains optional `questionKo` and `answer`; older monthly records without these keys still decode.
- Calendar's completed card uses the selected date's question and reducer-owned draft. Member save updates the monthly record only after the v2 answer response; failure retains the editable draft. A nonmember answer remains in the current app session, matching Home's session behavior.
- Home and Calendar invalidate each other's loaded member data after a successful answer save. Nonmember session answers synchronize across their selected dates.
- A nonmember Home reload restores the selected date's session answer after Home clears its draft for the date change. The app-level regression first failed on this omission, then passed after rehydration was added; member reloads still use the server response.
- The saved-answer simulator state is a **fixture**, not evidence of a live server round trip.
- TDD red: `CalendarFeatureTests` first failed to build on missing `questionKo`/`answer` and answer actions; `AppFeatureTests.test_answerSaveInvalidatesTheOtherTabsCachedData` then failed before AppFeature invalidation was added.
- Green: focused Calendar/App tests passed. `xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,id=CE56066E-B7A3-4A0D-8249-0095E5227289' -derivedDataPath /tmp/fiilsa-qa-calendar-answer-derived -only-testing:FiilsaTests -only-testing:FiilsaUITests/CalendarUITests/testSavedCalendarAnswerFixtureShowsEditState CODE_SIGNING_ALLOWED=NO` returned `TEST SUCCEEDED` (83 unit cases and the saved-state UI case). The UI case also passed alone after scrolling the card into view.
- Video verification: `file` identifies the final clip as MP4 v2, `avconvert` passthrough preserved the simulator H.264 stream, and AVFoundation reports a 5.0-second duration.

## Final assembled-screen result

- Full-frame reference/capture comparison: pending.
- Final runtime capture: pending.
- Result: Blocked until a same-size full-frame Figma/runtime comparison and an authenticated save/reload round trip are available.
- Remaining differences: to be determined by runtime comparison.

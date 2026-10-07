# Home·Calendar 답변 저장 Figma UI QA

## Reference

- Figma URL: [Home 질문 흐름](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3110-33782), [Calendar Light](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796), [Calendar Dark](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3051-899)
- Target frames/nodes: Home `3110:33783`, `3110:34152`, `3110:34293`, `3110:34438` (360×821pt); Calendar `2987:22796`, `3051:899` (360×1101pt).
- Full-frame reference image: Figma MCP `get_design_context` for `3110:34293` and `3051:899`; existing durable reference assets in `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/` and `docs/design-qa/assets/calendar-figma/2026-09-20/`.
- Runtime targets: Home iPhone 17 Pro iOS 26.5, Light, 402×874pt; Calendar iPhone 17e iOS 26.5, Light, 390×844pt scrolled to the completed selected date. Both use saved-answer UI fixtures; Dark and authenticated runtime states remain pending.
- Runtime full-frame captures: Home [`home-saved-iphone17pro.png`](assets/home-answer-2026-10-07/home-saved-iphone17pro.png) and [5-second MP4](assets/home-answer-2026-10-07/home-saved-iphone17pro.mp4); Calendar [`calendar-answer-saved-fixture.png`](assets/calendar-answer-2026-10-07/calendar-answer-saved-fixture.png) and [5-second MP4](assets/calendar-answer-2026-10-07/calendar-answer-saved-fixture.mp4).
- Crop boundaries: Home runtime full 402×874pt versus Figma 360×821pt; Calendar runtime full scrolled viewport 390×844pt versus Figma complete scroll content 360×1101pt.
- Comparison method: Home side by side against `fillsa-home-question-flow.png` and Figma `3110:34293` context screenshot, with toast inset/size inspection. Calendar visual inspection against the Figma completed card; unequal viewport and scroll bounds prevent a coordinate overlay.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Home question card | `3110:33783`, `3110:34152`, `3110:34438` | empty, editing, saved | Saved fixture captured; full-frame geometry blocked by viewport mismatch |
| Home success toast | `3110:34293` | server-confirmed save | Figma 20pt side insets, 50pt height, 24pt icon matched at runtime; full-frame geometry blocked by viewport mismatch |
| Calendar completed question card | `2987:22796`, `3051:899` | empty, editing, saved | Data binding/reducer tests and Light saved fixture passed; full-frame and Dark validation blocked |

## Validation rounds

### Round 1

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Home toast component and full frame | Runtime toast began at x=0pt, while Figma frame places it at x=20pt | Added 20pt leading inset to toast | Component horizontal placement corrected; 402×874pt runtime and 360×821pt Figma frames prevent strict full-frame pass |

### Round 2

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Home toast and saved card | After the inset fix, the success toast still used its text's intrinsic width, while Figma `3110:34427` spans 320pt within the 360pt frame | Expanded the success card to the available width, set 50pt height and 24pt icon; retained other toast style | Component width/height corrected; assembled Home still has unequal viewport dimensions |

### Round 3

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Saved answer interaction | Existing UI test showed that the keyboard stayed visible after server-confirmed save | Cleared `HomeQuestionAnswerCard` focus when editing ends; injected a deterministic server response in the Home UI fixture | Focused UI test passes; full-frame saved fixture image/video recaptured. Strict 360×821pt assembled comparison remains blocked by 402×874pt runtime |

The saved fixture capture shows the selected-date quote, question, recorded answer, 0/200 counter, and edit button inside the existing Calendar card. It uses no live server response. The full Figma frame cannot be overlaid on this 390×844pt scrolled viewport, so this is partial evidence only.

### Round 4

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Calendar completed question card | Original card kept a private draft and record button had an empty callback; monthly response dropped question and answer | Bound selected-date v2 monthly data to reducer-owned answer state and v2 save effect | Model/reducer tests and Light saved-state fixture passed; full 360×1101pt Figma comparison blocked by viewport/scroll bounds |

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

- Full-frame reference/capture comparison: Figma Home 360×821pt versus runtime 402×874pt; Figma Calendar 360×1101pt full scroll content versus runtime 390×844pt scrolled viewport. Exact overlay unavailable.
- Final runtime captures: Home and Calendar saved-state fixture images/videos above.
- Result: Home and Calendar **Blocked** for strict Figma assembled-screen sign-off; targeted functional/component tests passed.
- Remaining differences: viewport and Calendar scroll bounds; Calendar Dark runtime state; authenticated server save/reload round trip.

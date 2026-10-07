# Home·Calendar 답변 저장 Figma UI QA

## Reference

- Figma URL: [Home 질문 흐름](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3110-33782), [Calendar Light](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796), [Calendar Dark](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3051-899)
- Target frames/nodes: Home `3110:33783`, `3110:34152`, `3110:34293`, `3110:34438` (360×821pt); Calendar `2987:22796`, `3051:899` (360×1101pt).
- Full-frame reference image: Figma MCP `get_design_context` for `3110:34293` and `3051:899`; existing durable reference assets in `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/` and `docs/design-qa/assets/calendar-figma/2026-09-20/`.
- Runtime target: iPhone 17 Pro, iOS 26.5, 402×874pt, Light, saved-answer fixture and success toast. Calendar runtime target remains pending.
- Runtime full-frame capture: [`home-saved-iphone17pro.png`](assets/home-answer-2026-10-07/home-saved-iphone17pro.png); [5-second simulator recording](assets/home-answer-2026-10-07/home-saved-iphone17pro.mp4). This is a UI fixture for the saved state, not a live server transaction.
- Crop boundaries: full Home frame 402×874pt; Figma frame 360×821pt. Components inspected within their respective full frames.
- Comparison method: side by side against `fillsa-home-question-flow.png` and the Figma `3110:34293` context screenshot; inspect Figma and runtime left inset for the toast.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Home question card | `3110:33783`, `3110:34152`, `3110:34438` | empty, editing, saved | Saved fixture captured; full-frame geometry blocked by viewport mismatch |
| Home success toast | `3110:34293` | server-confirmed save | Figma 20pt side insets, 50pt height, 24pt icon matched at runtime; full-frame geometry blocked by viewport mismatch |
| Calendar completed question card | `2987:22796`, `3051:899` | empty, editing, saved | Pending |

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

## Final assembled-screen result

- Full-frame reference/capture comparison: Figma 360×821pt question-flow frame versus 402×874pt iPhone 17 Pro full-frame capture above; unequal viewports prevent exact overlay. Calendar pending.
- Final runtime capture: Home saved fixture image/video above; Calendar pending.
- Result: Home Blocked for strict Figma sign-off; Calendar pending.
- Remaining differences: viewport dimensions; Calendar component and full-frame comparison; authenticated server round trip has not been recorded.

# Home·Calendar 답변 저장 Figma UI QA

## Reference

- Figma URL: [Home 질문 흐름](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3110-33782), [Calendar Light](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796), [Calendar Dark](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3051-899)
- Target frames/nodes: Home `3110:33783`, `3110:34152`, `3110:34293`, `3110:34438` (360×821pt); Calendar `2987:22796`, `3051:899` (360×1101pt).
- Full-frame reference image: Figma MCP `get_design_context` for `3110:34293` and `3051:899`; existing durable reference assets in `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/` and `docs/design-qa/assets/calendar-figma/2026-09-20/`.
- Runtime target: iPhone simulator, Light/Dark, matching saved/unsaved states; exact model and point size to record after capture.
- Runtime full-frame capture: pending.
- Crop boundaries: full frame for assembled-screen comparison; component bounds to be recorded per capture.
- Comparison method: side by side and coordinate/size inspection.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Home question card | `3110:33783`, `3110:34152`, `3110:34438` | empty, editing, saved | Pending |
| Home success toast | `3110:34293` | server-confirmed save | Pending |
| Calendar completed question card | `2987:22796`, `3051:899` | empty, editing, saved | Pending |

## Validation rounds

### Round 1

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Components and assembled screens | Pending runtime capture | Pending | Pending |

## Final assembled-screen result

- Full-frame reference/capture comparison: pending.
- Final runtime capture: pending.
- Result: Pending.
- Remaining differences: to be determined by runtime comparison.

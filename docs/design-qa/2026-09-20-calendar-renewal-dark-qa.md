# Calendar Renewal Dark Figma UI QA

## Reference

- Figma URLs: `3039:24906` (필사하지 않은 경우), `3051:899` (필사를 한 경우) in file `VdFocqyqTgevMVCQxwAQ2X`
- Target frames/nodes: `3. calendar_리뉴얼[Dark]_HTML 승인본` 360×816pt; `3. calendar_리뉴얼[Dark]_답변 미작성` 360×1101pt
- Full-frame reference images:
  - `assets/calendar-figma/2026-09-20/calendar-no-handwriting-3039-24906-reference.png`
  - `assets/calendar-figma/2026-09-20/calendar-handwriting-3051-899-reference.png`
- Runtime target: iOS Simulator, 360pt-wide dark appearance, incomplete and completed selected-day states
- Runtime full-frame capture: pending
- Crop boundaries: full frame for both reference and runtime; completed state additionally uses full scroll content
- Comparison method: pending side-by-side and image overlay

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Header | `3039:25050`, `3051:1094` | dark, streak 100 | 미검증 |
| Month card/grid | `3039:24908`, `3051:902` | March 2025 | 미검증 |
| Monthly counts | `3039:25035`, `3051:1040` | heart/flame totals | 미검증 |
| Incomplete selected day | `3039:25073`, `3039:25079` | no writing | 미검증 |
| Completed selected day | `3051:1049`, `3051:1076` | writing complete, answer empty | 미검증 |
| Bottom navigation | `3039:25097`, `3051:1117` | Calendar selected | 미검증 |
| Ad surface | `3039:27545`, `3051:1088` | static placeholder | 미검증 |

## Validation rounds

### Round 1

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Pre-implementation baseline | Runtime capture pending | Pending | 미검증 |

## Final assembled-screen result

- Full-frame reference/capture comparison: pending
- Final runtime capture: pending
- Result: Blocked pending runtime validation
- Remaining differences: implementation and runtime comparison pending

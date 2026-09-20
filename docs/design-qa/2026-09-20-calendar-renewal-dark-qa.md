# Calendar Renewal Completed Figma UI QA

## Reference

- Figma URLs: `2987:22796` (필사를 한 경우 Light), `3051:899` (필사를 한 경우 Dark), `3039:24906` (필사하지 않은 경우 Dark) in file `VdFocqyqTgevMVCQxwAQ2X`
- Target frames/nodes: completed Light/Dark 360×1101pt; no-writing Dark 360×816pt
- Full-frame reference images:
  - `assets/calendar-figma/2026-08-30-calendar-completed-2987-22796-reference.png`
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
| Completed selected day actions | Light `2987:22949`–`2987:22975`, Dark `3051:1049`–`3051:1074` | labels Light `#565149`, Dark `#9E9E9E` | 자동 UI 테스트 통과, 육안 검증 대기 |
| Bottom navigation | `3039:25097`, `3051:1117` | Calendar selected | 미검증 |
| Ad surface | `3039:27545`, `3051:1088` | 이번 출시에서 제외 | 사용자 승인 |

## Validation rounds

### Round 1

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Pre-implementation baseline | Runtime capture pending | Pending | 미검증 |

### Round 2 — completed action label colors

| Scope | Difference | Fix | Result |
|---|---|---|---|
| 복사/공유/좋아요/이미지 등록 텍스트 | 기존 `#616161` 고정값이 Light `#565149`, Dark `#9E9E9E`와 모두 다름 | 색상 모드별 기존 Figma 토큰으로 분기 | Light/Dark UI 픽셀 테스트 통과 |

## Final assembled-screen result

- Full-frame reference/capture comparison: pending
- Final runtime capture: pending
- Result: Action-label color implementation and automated verification complete; user visual validation pending
- Remaining differences: full-frame runtime comparison pending

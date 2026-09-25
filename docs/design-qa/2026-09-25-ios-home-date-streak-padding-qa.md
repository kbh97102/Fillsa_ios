# Home Date/Streak Padding Figma UI QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%25E2%259C%2592%25EF%25B8%258F%25ED%2595%2584%25EC%2582%25AC?node-id=2929-13556&t=rysafF9DyBGoWDL9-11
- Target frames/nodes: `2929:13556` (`2.home`), `2929:15476` (header), `2929:15495` (streak), `2929:15493` (profile), `2929:15667` (month), `3204:2435` (week strip)
- Full-frame reference image: Figma MCP render for `2929:13556`; persistent baseline `docs/design-qa/assets/home-figma/2026-08-29-home-figma-reference.png`
- Runtime target: iPhone 17 Pro simulator, iOS 26.5, Light, deterministic `-ui-testing-home` state
- Runtime full-frame capture: pending
- Crop boundaries: full frame; component comparison uses header y=30...120 in the 360×821 reference and the corresponding runtime region
- Comparison method: Figma/runtime side-by-side plus UI geometry assertions

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Header streak/profile spacing | `2929:15495`, `2929:15493` | 100-day streak | Pending |
| Month selector leading inset | `2929:15667` | `2026.08`, x=20 | Pending |
| Week strip spacing | `3204:2435` | starts x=102; 9pt after month selector | Pending |

## Validation rounds

### Round 1

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Date controls | Pending pre-fix runtime geometry assertion. | Pending | Pending |
| Streak/profile | Pending pre-fix runtime geometry assertion. | Pending | Pending |

## Final assembled-screen result

- Full-frame reference/capture comparison: pending
- Final runtime capture: pending
- Result: Blocked
- Remaining differences: pre-fix runtime verification and correction are pending.

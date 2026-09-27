# Home Responsive Layout Figma UI QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%E2%9C%92%EF%B8%8F%ED%95%84%EC%82%AC?node-id=2929-13556
- Target frames/nodes: `2929:13556`, `3207:3059`, `2929:13630`, `2929:13642`, `3223:4773`, `3223:4966`, `3139:1501`, `2929:16221`, `2929:16227`, `2929:18871`, `2929:19016`
- Full-frame reference images: Figma MCP renders for `2929:13556`, `3139:1501`, `2929:18871`, `3223:4773`, and `2929:19326`, stored under `docs/design-qa/assets/home-responsive-layout/2026-09-27/`.
- Runtime target: iPhone 17 Pro simulator, iOS 26.5, Light, deterministic Home fixtures
- Runtime full-frame captures: default, long quote, calendar open, zero-streak tooltip, and image dialog under `docs/design-qa/assets/home-responsive-layout/2026-09-27/`.
- Side-by-side report: [2026-09-27-home-responsive-comparison.html](2026-09-27-home-responsive-comparison.html)
- Crop boundaries: full frame plus affected component crops
- Comparison method: side-by-side and geometry assertions; overlay where viewport dimensions match

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Quote actions | `3207:3059` | Default | Pending |
| Question answer box | `2929:13630` / `2929:13634` | Default and accessibility text size | Pending |
| Quote card | `2929:13642` | Default and long quote | Pending |
| Image dialog | `3223:4773` / `3223:4966` | Open | Pending |
| Calendar overlay | `3139:1501` / `2929:16221` | Open | Pending |
| Streak tooltip | `2929:18871` / `2929:19016` | Zero streak, open | Pending |

## Validation rounds

### Round 1

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Responsive Home implementation | Figma 360×821pt and iPhone 17 Pro 402×874pt differ in viewport size. Long-quote and image-dialog fixtures also have different copy/state from their Figma comparison frames. | Captured both sources at native resolution and presented each state side by side in the HTML report, with state differences labeled. | Awaiting user visual review; no final Figma pass claimed. |

## Final assembled-screen result

- Full-frame reference/capture comparison: available in the HTML report above.
- Current runtime captures: `2026-09-27` iPhone 17 Pro fixture PNGs.
- Result: awaiting user visual review and correction direction.
- Remaining differences: Figma 360×821pt versus runtime 402×874pt; Figma long-quote state unavailable; Figma gradient dialog has a registered image/delete action while the runtime fixture does not. Calendar anchor UI test passes; the streak tooltip's accessibility-frame assertion is still failing and has not been counted as a pass.

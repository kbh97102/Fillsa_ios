# iOS Home Dark Root Figma UI QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%E2%9C%92%EF%B8%8F%ED%95%84%EC%82%AC?node-id=2929-9603
- Root inventory: `2929:9603` (`2. home[Dark]`)
- Full-frame render targets: `3039:26518`, `3139:1753`, `3039:26778`, `3039:26996`, `3039:27295`, `3139:910`, `3136:1198`, `3139:1061`, `3139:1238`, `3223:5985`, `3223:6126`, `3223:6435`, `3223:6600`, `3223:6912`
- Linked route targets: `3087:28815`, `2929:9764`, `2929:9801`, `2929:9844`, `2929:9884`, `2929:9931`, `2929:10788`, `2929:10884`, `2929:10850`
- Reference images: `docs/design-qa/assets/home-figma-2929-9603/2026-09-07/figma-dark-*.png`
- Runtime target: iOS Simulator, dark appearance, Korean locale; Home frames target 360×821 and linked legacy frames target 360×720
- Runtime full-frame capture: not created; this change is documentation-only
- Comparison method: pending implementation; use component crops plus full-frame side-by-side/overlay

## Component inventory

| Component/state family | Figma node | Target state | Current result |
|---|---|---|---|
| Home shell | `3039:26518` | default dark | Not evaluated |
| Inline calendar | `3139:1753`, `3039:28098` | closed/open/select | Not evaluated |
| Week strip | `3039:28626` | none/today/done | Not evaluated |
| Streak tooltip | `3039:26778` | known zero | Not evaluated |
| Copy/liked/image actions | `3039:26996`, `3039:27295` | toast/selected/registered | Not evaluated |
| Question flow | `3136:863` | before/focus/toast/done | Not evaluated |
| Image flow | `3223:5589` | before/after/two previews/delete | Not evaluated |
| Typing results | `3087:28815`, `2929:9764`–`2929:9884` | input/save/outcomes | Not evaluated |
| Login | `2929:9931`, `2929:10788` | modal/full screen | Not evaluated |
| Share | `2929:10884`, `2929:10850` | first guide/carousel | Not evaluated |

## Validation rounds

No runtime validation round was performed. Implementation, tests, simulator launch, and comparison are outside the current documentation-only scope.

## Final assembled-screen result

- Result: Not evaluated
- Remaining work: execute `docs/superpowers/plans/2026-09-07-ios-home-dark-root.md`
- Acceptance caveat: a 402×874 simulator frame is not an exact 360×821 target. Without an exact full-frame runtime comparison, record the future result as `Blocked`, not `Pass`.

# Onboarding Guide Full-Frame Figma UI QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3088-30089
- Target frames/nodes: `0.onboarding_new_01` (`3088:30089`) / `app_visual` (`3110:31993`); `0.onboarding_new_02` (`3088:30215`) / `app_visual` (`3110:32702`); `0.onboarding_new_03` (`3088:30412`) / `app_visual` (`3110:33500`)
- Full-frame reference images: `2026-08-29-onboarding-guide-page-1-figma.png`, `2026-08-29-onboarding-guide-page-2-figma.png`, and `2026-08-29-onboarding-guide-page-3-figma.png` in this directory (each 360×720; full frame includes white root background, status bar, safe areas, and home indicator)
- Runtime target: iPhone 17 Pro simulator, iOS 26.5, light mode, guide pages 1–3, launched with `-ui-testing-onboarding-guide`
- Runtime full-frame captures: `onboarding-guide-runtime/88FAC304-E272-40D2-A9D8-A5E2CE278D7A.png` (page 1), `onboarding-guide-runtime/4BA35BD4-5378-4331-A116-15D554CA5C4A.png` (page 2), and `onboarding-guide-runtime/CA756CF9-043D-4199-AA23-F89118322CEB.png` (page 3); attachment mapping is retained in `onboarding-guide-runtime/manifest.json`
- Crop boundaries: full frame for all images. Figma is 360×720 pixels; the iPhone 17 Pro runtime captures are 1206×2622 pixels (402×874 points at 3×).
- Comparison method: full-frame visual side-by-side inspection. No overlay was generated because the device frames differ.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Home guide image | `3110:31993` | page 1, light | partial pass: bundled Figma PNG; asset compilation passed |
| List guide image | `3110:32702` | page 2, light | partial pass: bundled Figma PNG; asset compilation passed |
| Calendar guide image | `3110:33500` | page 3, light | partial pass: bundled Figma PNG; asset compilation passed |
| Full-frame root surface | `3088:30089`, `3088:30215`, `3088:30412` | pages 1–3, light | Round 1 RED: `#FFEFCC` runtime root differs from `#FFFFFF` Figma root |

## Validation rounds

### Round 1 — RED full-frame inspection

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Full assembled guide pages 1–3 | `OnboardingGuideView` applies `FillsaColor.background` (`#FFEFCC`) outside the content. Every Figma full frame has a `#FFFFFF` root, including the status-bar and home-indicator surface. The former asset-only result did not compare an assembled runtime frame and must not be treated as a screen pass. | Change only the guide root background to the existing exact white token. | RED |
| Guide illustration assets | Direct Figma `app_visual` PNG exports are bundled at their Figma display sizes (288×430, 288×430, 280×430 points). | None in this correction. | Partial pass only — not final screen acceptance |

### Round 2 — runtime verification

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Focused UI test launch and full-frame capture | `FiilsaUITests/OnboardingGuideUITests` passed on iPhone 17 Pro/iOS 26.5, using the isolated `-ui-testing-onboarding-guide` route and capturing all three pages. | No further launch change. | Pass |
| Root background / status-bar and bottom safe-area surface | Side-by-side inspection of all three runtime captures shows the guide root, status-bar region, outer margins, and bottom surface as white after the correction, matching the Figma root color `#FFFFFF`. | Replaced the guide-only `FillsaColor.background` surface with `FillsaColor.white`. | Partial pass — color evidence only |
| Full assembled frame | The runtime target is 402×874 points versus Figma 360×720. The captured screen also exposes pre-existing content/copy and layout differences (for example, page 1’s title and central image composition), which this tightly scoped correction must not change. These frames cannot support an exact full-frame overlay judgment. | No out-of-scope UI changes. | Blocked |

## Final assembled-screen result

- Full-frame reference/capture comparison: pages 1–3 captured and inspected side by side. Root-surface color is corrected to white; exact assembled-frame comparison is blocked by device-frame and pre-existing content/layout mismatches.
- Final runtime capture: `onboarding-guide-runtime/88FAC304-E272-40D2-A9D8-A5E2CE278D7A.png` (page 1); pages 2–3 are adjacent in the same directory.
- Result: Blocked.
- Remaining differences: the matching 360×720 runtime target is unavailable; the 402×874 runtime capture differs in assembled content/copy/layout outside the requested background correction. A Figma-exact final Pass must wait for a matching target and scope decision on those existing differences.

# Onboarding Guide Dark-Mode Figma UI QA

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3110-31987
- Target frames/nodes: `0.onboarding_guide01` (`3110:31987`) / `app_visual` (`3110:32587`); `0.onboarding_guide02` (`3110:32359`) / `app_visual` (`3088:30233`); `0.onboarding_guide03` (`3110:32112`) / `app_visual` (`3110:33268`).
- Full-frame reference images: `onboarding-guide-dark-figma/page-{1,2,3}-figma.png` (360×720 each; root, Figma status bar, safe area, and home indicator included).
- Runtime target: iPhone 17 Pro simulator, iOS 26.4.1, dark mode, pages 1–3, launched with `-ui-testing-onboarding-guide -ui-testing-onboarding-guide-dark`.
- Runtime full-frame captures: `onboarding-guide-dark-runtime/A3080B4C-B6C3-4962-B701-939605219CFA.png` (page 1), `onboarding-guide-dark-runtime/758ECF3E-92FC-4FC8-87BC-B3BAEBC496CA.png` (page 2), and `onboarding-guide-dark-runtime/2C4992C0-5221-406B-882C-BC88ABDF3FCF.png` (page 3); attachment mapping is retained in `onboarding-guide-dark-runtime/manifest.json`.
- Crop boundaries: full frame for every reference and capture.
- Comparison method: full-frame side-by-side inspection; the iPhone 17 Pro runtime is 402×874 points, so it cannot support an exact 360×720 overlay.

## Component inventory

| Component | Figma node | Target state | Final result |
|---|---|---|---|
| Dark home guide image | `3110:32587` | page 1 dark | partial pass: direct Figma PNG is bundled as the dark appearance |
| Dark list guide image | `3088:30233` | page 2 dark | partial pass: direct Figma PNG is bundled as the dark appearance |
| Dark calendar guide image | `3110:33268` | page 3 dark | partial pass: direct Figma PNG is bundled as the dark appearance |
| Root / primary-container surfaces | root `#212121`; primary-container `#424242` | pages 1–3 dark | partial pass: runtime uses `#212121` root and `#424242` button surface |

## Validation rounds

### Round 1 — RED

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Focused dark guide UI test | No test-only dark guide route, dark root identifier, or dark image appearances existed. `OnboardingGuideUITests/testDarkModeLaunchShowsDarkGuideSurfaceAndEveryDarkGuideAsset` failed with `XCTAssertTrue failed`. | Add the dark launch argument, dynamic surfaces, and Figma-exported dark image appearances. | RED |

### Round 2 — focused runtime verification

| Scope | Difference | Fix | Result |
|---|---|---|---|
| Test-only dark launch | The launch route must not change ordinary navigation. | The route still requires `-ui-testing-onboarding-guide`; the dark theme requires its additional `-ui-testing-onboarding-guide-dark` argument. | Pass — focused UI test passed. |
| Root, status/safe-area, and home-indicator surfaces | All three full-device captures show the `#212121` root behind the system status and home-indicator regions; the runtime button uses the requested `#424242` dark primary-container surface. | None. | Partial pass — color/surface evidence. |
| Dark image pages 1–3 | Each UI-test page exposes its dark image accessibility element and renders the direct export in the runtime capture. | None. | Partial pass — focused test and direct Figma bytes verified. |
| Full assembled frame | Figma is 360×720 while the runtime captures are 1206×2622 (402×874 points). In addition, the retained onboarding copy/layout intentionally differs from the supplied dark Figma frames (for example, the runtime headline remains `필사, 이렇게 사용하면 편리해요🖋️`, while Figma page 1 has a different headline). | No out-of-scope copy/layout change; preserve the approved flow/copy/pages/light behavior. | Blocked — no exact full-frame match. |

### Density validation — reviewer P1 correction

| Asset | Figma node | Dark @2x export | Dark @3x export | Result |
|---|---|---|---|---|
| Home | `3110:32587` | `onboarding_guide_home-dark@2x.png` (576×860) | `onboarding_guide_home-dark@3x.png` (864×1290) | direct Figma exports; registered as dark luminosity appearances |
| List | `3088:30233` | `onboarding_guide_list-dark@2x.png` (576×860) | `onboarding_guide_list-dark@3x.png` (864×1290) | direct Figma exports; registered as dark luminosity appearances |
| Calendar | `3110:33268` | `onboarding_guide_calendar-dark@2x.png` (560×860) | `onboarding_guide_calendar-dark@3x.png` (840×1290) | direct Figma exports; registered as dark luminosity appearances |

The focused UI test proves that each page reaches a dark-mode image element and captures the rendered pages. It does not inspect the asset catalog’s selected pixel density; `sips` dimension checks plus the successful asset-catalog compilation provide that density evidence without source-string testing.

## Final assembled-screen result

- Full-frame reference/capture comparison: page 1 `onboarding-guide-dark-figma/page-1-figma.png` ↔ `onboarding-guide-dark-runtime/A3080B4C-B6C3-4962-B701-939605219CFA.png`; page 2 `onboarding-guide-dark-figma/page-2-figma.png` ↔ `onboarding-guide-dark-runtime/758ECF3E-92FC-4FC8-87BC-B3BAEBC496CA.png`; page 3 `onboarding-guide-dark-figma/page-3-figma.png` ↔ `onboarding-guide-dark-runtime/2C4992C0-5221-406B-882C-BC88ABDF3FCF.png`. Inspected as full-frame pairs, including root/status/safe-area/home-indicator surfaces.
- Final runtime capture: `onboarding-guide-dark-runtime/A3080B4C-B6C3-4962-B701-939605219CFA.png` (page 1; pages 2–3 are adjacent in the same directory).
- Result: Blocked.
- Remaining differences: exact full-frame comparison is blocked by the 402×874 runtime target versus the 360×720 Figma frame, and by retained out-of-scope onboarding copy/layout differences on all three pages. Root/system surfaces and direct dark guide graphics are not remaining differences.

# [가이드 페이지] `0.onboarding_guide`

## Figma UI 기준

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3088-30089
- 대상 프레임/노드: `0.onboarding_new_01` (`3088:30089`), `0.onboarding_new_02` (`3088:30215`), `0.onboarding_new_03` (`3088:30412`)
- 대상 기기/프레임 크기: 360×720, light mode, guide pages 1–3
- 검증 상태: Round 1 full-frame RED — the runtime root used `#FFEFCC`, while all three Figma frames use `#FFFFFF`. Round 2 captured all three guide pages with a white runtime root, but final assembled-frame acceptance is Blocked because the available iPhone 17 Pro capture is 402×874 points (1206×2622 pixels), not the Figma 360×720 target, and existing content/copy geometry diverges outside this correction’s scope.
- 기준 이미지: full-frame Figma PNGs, including the white root surface, status bar, safe areas, and home indicator — `../design-qa/2026-08-29-onboarding-guide-page-{1,2,3}-figma.png` (360×720)
- QA 기록: [2026-08-29-onboarding-guide-assets-qa.md](../design-qa/2026-08-29-onboarding-guide-assets-qa.md)

### Dark mode extension (2026-08-29)

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3110-31987
- Target frames/nodes: `0.onboarding_guide01` (`3110:31987`), `0.onboarding_guide02` (`3110:32359`), `0.onboarding_guide03` (`3110:32112`); dark `app_visual` nodes `3110:32587`, `3088:30233`, `3110:33268`
- Target device/frame: 360×720, dark mode, guide pages 1–3; Figma root `#212121`, primary-container `#424242`.
- Reference images: [`page-1-figma.png`](../design-qa/onboarding-guide-dark-figma/page-1-figma.png), [`page-2-figma.png`](../design-qa/onboarding-guide-dark-figma/page-2-figma.png), [`page-3-figma.png`](../design-qa/onboarding-guide-dark-figma/page-3-figma.png) (each full frame, including Figma status/home chrome).
- Verification status: focused dark UI test and direct Figma exports are verified; assembled full-frame result is Blocked because the available 402×874 runtime target and retained copy/layout do not exactly match the 360×720 Figma frames.
- QA record: [2026-08-29-onboarding-guide-dark-mode-qa.md](../design-qa/2026-08-29-onboarding-guide-dark-mode-qa.md)

### 컴포넌트 분해

| 컴포넌트 | Figma 노드 | 책임 | 조립 위치 | 검증 상태 |
|---|---|---|---|---|
| GuidePhoneMock page 1 | `3110:31993` (`app_visual`) | Home guide screenshot asset | `OnboardingGuideImageSection` page 0 | asset compilation passed |
| GuidePhoneMock page 2 | `3110:32702` (`app_visual`) | List guide screenshot asset | `OnboardingGuideImageSection` page 1 | asset compilation passed |
| GuidePhoneMock page 3 | `3110:33500` (`app_visual`) | Calendar guide screenshot asset | `OnboardingGuideImageSection` page 2 | asset compilation passed |
| Guide full-frame surface | `3088:30089`, `3088:30215`, `3088:30412` | White root background behind all guide content and iOS chrome | `OnboardingGuideView` | root color partial pass; exact assembled-frame comparison Blocked |
| Dark GuidePhoneMock pages 1–3 | `3110:32587`, `3088:30233`, `3110:33268` | Figma-exported dark illustrations selected by asset-catalog luminosity appearance | `OnboardingGuideImageSection` pages 0–2 | partial pass: focused runtime captures |
| Dark guide root / primary-container | `3110:31987`, `3110:32359`, `3110:32112` | `#212121` root with `#424242` guide buttons | `OnboardingGuideView` | partial pass: focused runtime captures; assembled frame Blocked |

## 기능

- Home / List / Calendar 화면의 가이드 이미지가 순차적으로 노출된다.

## 버튼

| 버튼 | 동작 |
|------|------|
| 건너뛰기 | Home 화면으로 즉시 이동 |
| 다음 | 다음 가이드 화면으로 이동 |
| 필사 시작하기 | Home 화면으로 이동 (마지막 가이드에서 노출) |

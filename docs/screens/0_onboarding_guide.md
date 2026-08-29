# [가이드 페이지] `0.onboarding_guide`

## Figma UI 기준

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3088-30089
- 대상 프레임/노드: `0.onboarding_new_01` (`3088:30089`), `0.onboarding_new_02` (`3088:30215`), `0.onboarding_new_03` (`3088:30412`)
- 대상 기기/프레임 크기: 360×720, light mode, guide pages 1–3
- 검증 상태: Round 1 full-frame RED — the runtime root used `#FFEFCC`, while all three Figma frames use `#FFFFFF`. Round 2 captured all three guide pages with a white runtime root, but final assembled-frame acceptance is Blocked because the available iPhone 17 Pro capture is 402×874 points (1206×2622 pixels), not the Figma 360×720 target, and existing content/copy geometry diverges outside this correction’s scope.
- 기준 이미지: full-frame Figma PNGs, including the white root surface, status bar, safe areas, and home indicator — `../design-qa/2026-08-29-onboarding-guide-page-{1,2,3}-figma.png` (360×720)
- QA 기록: [2026-08-29-onboarding-guide-assets-qa.md](../design-qa/2026-08-29-onboarding-guide-assets-qa.md)

### 컴포넌트 분해

| 컴포넌트 | Figma 노드 | 책임 | 조립 위치 | 검증 상태 |
|---|---|---|---|---|
| GuidePhoneMock page 1 | `3110:31993` (`app_visual`) | Home guide screenshot asset | `OnboardingGuideImageSection` page 0 | asset compilation passed |
| GuidePhoneMock page 2 | `3110:32702` (`app_visual`) | List guide screenshot asset | `OnboardingGuideImageSection` page 1 | asset compilation passed |
| GuidePhoneMock page 3 | `3110:33500` (`app_visual`) | Calendar guide screenshot asset | `OnboardingGuideImageSection` page 2 | asset compilation passed |
| Guide full-frame surface | `3088:30089`, `3088:30215`, `3088:30412` | White root background behind all guide content and iOS chrome | `OnboardingGuideView` | root color partial pass; exact assembled-frame comparison Blocked |

## 기능

- Home / List / Calendar 화면의 가이드 이미지가 순차적으로 노출된다.

## 버튼

| 버튼 | 동작 |
|------|------|
| 건너뛰기 | Home 화면으로 즉시 이동 |
| 다음 | 다음 가이드 화면으로 이동 |
| 필사 시작하기 | Home 화면으로 이동 (마지막 가이드에서 노출) |

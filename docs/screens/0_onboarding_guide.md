# [가이드 페이지] `0.onboarding_guide`

## Figma UI 기준

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3088-30089
- 대상 프레임/노드: `0.onboarding_new_01` (`3088:30089`), `0.onboarding_new_02` (`3088:30215`), `0.onboarding_new_03` (`3088:30412`)
- 대상 기기/프레임 크기: 360×720, light mode, guide pages 1–3
- 검증 상태: Figma exports bundled and asset catalog compilation passed; assembled runtime capture blocked by unavailable CoreSimulator service
- 기준 이미지: Figma `app_visual` exports — `3110:31993`, `3110:32702`, `3110:33500`
- QA 기록: [2026-08-29-onboarding-guide-assets-qa.md](../design-qa/2026-08-29-onboarding-guide-assets-qa.md)

### 컴포넌트 분해

| 컴포넌트 | Figma 노드 | 책임 | 조립 위치 | 검증 상태 |
|---|---|---|---|---|
| GuidePhoneMock page 1 | `3110:31993` (`app_visual`) | Home guide screenshot asset | `OnboardingGuideImageSection` page 0 | asset compilation passed |
| GuidePhoneMock page 2 | `3110:32702` (`app_visual`) | List guide screenshot asset | `OnboardingGuideImageSection` page 1 | asset compilation passed |
| GuidePhoneMock page 3 | `3110:33500` (`app_visual`) | Calendar guide screenshot asset | `OnboardingGuideImageSection` page 2 | asset compilation passed |

## 기능

- Home / List / Calendar 화면의 가이드 이미지가 순차적으로 노출된다.

## 버튼

| 버튼 | 동작 |
|------|------|
| 건너뛰기 | Home 화면으로 즉시 이동 |
| 다음 | 다음 가이드 화면으로 이동 |
| 필사 시작하기 | Home 화면으로 이동 (마지막 가이드에서 노출) |

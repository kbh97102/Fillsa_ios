# 캘린더 재진입 데이터 갱신 QA · 2026-10-12

## 기준

- Figma: [미필사 Light `2985:21952`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2985-21952), [미필사 Dark `3039:24906`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3039-24906), [완료 Light `2987:22796`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796), [완료 Dark `3051:899`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3051-899).
- 전체 프레임 기준 이미지: `docs/design-qa/assets/ios-qa-preplan-2026-10-09/figma-calendar-incomplete.png`, `docs/design-qa/assets/calendar-figma/2026-09-20/calendar-no-handwriting-3039-24906-reference.png`, `docs/design-qa/assets/ios-qa-preplan-2026-10-09/figma-calendar-completed.png`, `docs/design-qa/assets/calendar-figma/2026-09-20/calendar-handwriting-3051-899-reference.png`.
- 범위: 기존 화면 구성 변경 없이, 캘린더에 다시 들어올 때 현재 월 서버 데이터를 갱신한다.

## 재현 및 검증

- 재현: 미필사 상태로 캘린더 진입 → 홈에서 오늘 필사 저장 → 캘린더 재진입. 기존 `hasLoaded`가 `onAppear`의 월간 조회를 막는다.
- 회귀 검증: 이미 로드된 미필사 상태에서 다시 진입했을 때 새 완료 응답이 선택 날짜와 월간 통계에 반영되는지 확인한다.
- 수정: `CalendarFeature.onAppear`는 이전 조회 완료 여부와 관계없이 현재 월을 다시 조회한다. 로딩 중에는 `AppView`가 화면 입력을 막으므로 진행 중인 요청은 중복 실행하지 않는다.
- 원인 확인: Xcode가 당시 루트 프로젝트를 열고 있어 처음 `stage`에만 반영한 수정은 실행 앱에 들어가지 않았다. 루트 브랜치에도 같은 수정과 회귀 테스트를 적용했다.
- 테스트: 캐시된 미필사 상태 회귀 테스트는 수정 전에 실패했다. 수정 후 `stage`의 `CalendarFeatureTests` 14건·`FiilsaTests` 81건, 루트 브랜치의 `FiilsaTests` 80건이 iPhone 17e / iOS 26.5 시뮬레이터에서 통과했다.
- 시각 QA: 레이아웃·문구·자산 변경 없음. 동일 크기·상태의 전체 프레임 비교는 수행하지 않아 Figma 최종 시각 수용은 `Blocked`로 유지한다. 실서버 계정으로 저장 직후 재진입하는 수동 경로도 미검증이다.

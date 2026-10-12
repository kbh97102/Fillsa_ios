# 캘린더 재진입 데이터 갱신 QA · 2026-10-12

## 기준

- Figma: [미필사 `3039:24906`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3039-24906), [완료 Light `2987:22796`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796), [완료 Dark `3051:899`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3051-899).
- 전체 프레임 기준 이미지: `docs/design-qa/assets/calendar-figma/2026-09-20/calendar-no-handwriting-3039-24906-reference.png`, `docs/design-qa/assets/calendar-figma/2026-08-30-calendar-completed-2987-22796-reference.png`, `docs/design-qa/assets/calendar-figma/2026-09-20/calendar-handwriting-3051-899-reference.png`.
- 범위: 화면 구성 변경 없이 캘린더 재진입 시 현재 월 서버 데이터를 갱신한다.

## 재현 및 검증

- 재현: 미필사 상태로 캘린더 진입 → 홈에서 오늘 필사 저장 → 캘린더 재진입. 기존 `hasLoaded`가 `onAppear`의 월간 조회를 막는다.
- 회귀 검증: 이미 로드된 미필사 상태에서 다시 진입했을 때 새 완료 응답이 선택 날짜와 월간 통계에 반영되는지 확인한다.
- 원인 확인: Xcode가 실제로 연 루트 프로젝트는 `fix/비회원_로직_제거` 브랜치였고, 이전 수정은 별도 `stage` 워크트리에만 있었다. 이 브랜치의 테스트는 수정 전 미필사 상태·통계 0이 남아 실패했다.
- 수정: 루트 브랜치의 `CalendarFeature.onAppear`가 기존 로드 여부와 무관하게 월간 데이터를 다시 조회한다. 진행 중인 중복 요청만 건너뛴다.
- 검증: iPhone 17e / iOS 26.5 시뮬레이터에서 `FiilsaTests` 80건 통과. 재진입 회귀 테스트는 수정 전 실패·수정 후 통과했다.
- 시각 QA: 레이아웃·문구·자산 변경 없음. 동일 크기·상태의 전체 프레임 비교를 수행하지 않아 Figma 최종 시각 수용은 `Blocked`다.
- 남은 확인: 실서버 계정으로 필사 저장 직후 캘린더 재진입하는 수동 경로는 아직 확인하지 못했다.

# [공통] 공통 UI 요소

## 전역 로딩 API 작업 묶음 (2026-09-29 계획)

- 단일 API는 공통 wrapper로 감싸고, 여러 API가 필요한 화면은 Feature에서 로딩 시작 → 실행 → 모두 await → 종료를 직접 선언한다.
- 한 묶음의 모든 작업이 종료된 뒤 그 묶음을 종료한다. 다른 묶음이 남아 있으면 전역 로딩을 유지한다.
- TCA Feature는 결과/오류 Action을 소유하고, AppFeature는 활성 묶음 수에 따른 전역 표시 상태를 소유한다.
- 설계: [전역 로딩 scope 계약](../superpowers/specs/2026-09-29-global-loading-scopes.md)
- 구현 계획: [Global Loading Scopes](../superpowers/plans/2026-09-29-global-loading-scopes.md)
- 스피너 외형의 Figma URL/node-id는 요청 중이다. 시각 구현 및 UI QA는 디자인 기준 확보 후 진행한다.

## 광고 정책

- 이번 출시에는 광고 및 광고 자리 표시 UI를 노출하지 않는다.

## 하단 내비게이션 바

- 노출 항목: Home / Calendar / My page
- 노출 화면: Home, Calendar, My page
- QuoteList는 하단 내비게이션 목적지에서 제외하며, 기존 기능 내부 이동 경로만 유지한다.

## 상단 헤더

| 화면 | 구성 | 동작 |
|------|------|------|
| Home / Calendar | 로고 + 사용자 아이콘 | 사용자 아이콘 클릭 → My page 이동 / 로고 클릭 → 액션 없음 |
| My page | 로고만 | 로고 클릭 → 액션 없음 |

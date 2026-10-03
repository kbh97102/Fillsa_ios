# [공통] 공통 UI 요소

## 전역 로딩 API 작업 묶음 및 스피너

- 단일 API는 공통 wrapper로 감싸고, 여러 API가 필요한 화면은 Feature에서 로딩 시작 → 실행 → 모두 await → 종료를 직접 선언한다.
- 한 묶음의 모든 작업이 종료된 뒤 그 묶음을 종료한다. 다른 묶음이 남아 있으면 전역 로딩을 유지한다.
- TCA Feature는 결과/오류 Action을 소유하고, AppFeature는 활성 묶음 수에 따른 전역 표시 상태를 소유한다.
- 설계: [전역 로딩 scope 계약](../superpowers/specs/2026-09-29-global-loading-scopes.md)
- 구현 계획: [Global Loading Scopes](../superpowers/plans/2026-09-29-global-loading-scopes.md)
- 검증 실패 및 재검증: [전역 로딩 실패 기록](../verification/2026-09-29-global-loading-failures.md)
- 로딩 카운트가 1 이상일 때 앱 전체 위에 로딩 오버레이를 표시한다. 종료 시 제거한다.

### Figma UI 기준

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%25E2%259C%2592%25EF%25B8%258F%25ED%2595%2584%25EC%2582%25AC?node-id=2929-5969&t=rysafF9DyBGoWDL9-11
- 대상 프레임/노드: `2929:5969` `loading`, 360×720, 밝은 상태. 중앙 자식 `2929:5971` `progress_indicator_01` 120×120, 원형 SVG 표시 영역 112×112.
- 대상 기기/프레임 크기: Figma 360×720; 검증 기기는 iPhone 17 Pro iOS 26.5, 402×874pt (해당 Figma 크기의 시뮬레이터 없음).
- 표시 상태: 로딩 중. Figma의 흰 배경 대신 사용자 지정 검정 20% 딤을 기존 화면 위에 적용하며 모든 터치를 차단한다.
- 시각적 예외: iOS 시스템 키보드는 앱 루트 오버레이보다 위에 표시된다. Home 답변·메모·필사 입력 중 로딩이 시작되면 앱 루트에서 현재 입력 포커스를 해제해 키보드 터치를 막고, 필사 화면의 자동 포커스는 로딩 중 재활성화하지 않는다. 이는 사용자가 지정한 전체 터치 차단을 위한 동작이며 Figma 단독 로딩 프레임에는 키보드 조합 상태가 없다.
- 기준 이미지: [Figma 전체 프레임](../design-qa/2026-10-03-global-loading-figma.png) (status bar와 전체 루트 배경 포함).
- 검증 상태: 컴포넌트·상호작용 부분 통과, Figma 전체 조립 화면 비교는 기준 프레임과 사용자 지정 딤 동작의 차이로 `Blocked`.
- QA 기록: [전역 로딩 UI QA](../design-qa/2026-10-03-global-loading-qa.md).
- 실행 영상·화면별 비교: [전역 로딩 HTML 보고서](../design-qa/2026-10-03-global-loading-video-report.html) (14개 라우팅 화면별 PNG·MP4).

### 전역 로딩 적용 화면 범위

- `AppScreen`: Splash, Login, Onboarding Guide, Typing, Share, Quote Detail, Memo Insert, Notice List, Notice Detail, Alert.
- `AppScreen.main`의 네 탭: Home, Quote List, Calendar, My Page.
- 총 14개 표시 상태. 같은 `AppView` 최상단 오버레이를 사용하며 화면별 스피너 구현은 추가하지 않는다.

### 컴포넌트 분해

| 컴포넌트 | Figma 노드 | 책임 | 조립 위치 | 검증 상태 |
|---|---|---|---|---|
| 원형 스피너 | `2929:5971`, SVG 자식 `2929:5972` | 중앙 원형 인디케이터 표시 | 전역 오버레이 | 부분 통과 |
| 전역 오버레이 | `2929:5969` | 화면 전체 검정 20% 딤 및 터치 차단 | `AppView` 최상단 | 부분 통과, 전체 프레임 Blocked |

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

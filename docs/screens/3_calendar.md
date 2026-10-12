# [Calendar] `3.calendar`

## 재진입 시 월간 데이터 갱신 (2026-10-12)

- Figma 기준: [미필사 `3039:24906`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3039-24906), [필사 완료 Light `2987:22796`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796), [필사 완료 Dark `3051:899`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3051-899). 전체 프레임 기준 이미지는 아래 `Figma UI 기준`의 경로를 사용한다.
- 대상 상태: 오늘 미필사 상태로 캘린더 방문 → 홈에서 오늘 필사 저장 → 캘린더 재진입 시 오늘 완료 상태와 월간 통계를 새 서버 응답으로 표시한다.
- 구성: `CalendarView` 진입 이벤트 → `CalendarFeature` 월간 조회 → 월 카드, 선택일 카드, 통계 표시. 기존 레이아웃·문구·액션은 그대로 사용한다.
- QA 기록: [캘린더 재진입 갱신](../design-qa/2026-10-12-calendar-entry-refresh-qa.md).

## 회원 전용 데이터 경로 — 구현 (2026-10-11)

[회원 화면 진입 계획](1_login_member_only_followup_implementation_plan.md)과 [비회원 분기 정리 계획](1_login_guest_cleanup_implementation_plan.md)에 따라 비회원 월간 API·로컬 병합·세션 답변을 제거했다. 인증 소실을 확인하면 로그인 화면으로 이동한다. 회원 월간 응답, 날짜 선택, 완료 카드 UI는 유지한다. 아래 비회원 API 설명은 이전 구현 당시 기록이다. [검증 기록](../design-qa/2026-10-11-member-only-qa.md).

## Figma UI 기준 (2026-09-20 변경 디자인)

- Figma URL:
  - 필사하지 않은 경우: `https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%25E2%259C%2592%25EF%25B8%258F%25ED%2595%2584%25EC%2582%25AC?node-id=3039-24906&t=pxxJ6i8fGGEVuuMH-11`
  - 필사를 한 경우 Light: `https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%25E2%259C%2592%25EF%25B8%258F%25ED%2595%2584%25EC%2582%25AC?node-id=2987-22796&t=pxxJ6i8fGGEVuuMH-11`
  - 필사를 한 경우 Dark: `https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%25E2%259C%2592%25EF%25B8%258F%25ED%2595%2584%25EC%2582%25AC?node-id=3051-899&t=pxxJ6i8fGGEVuuMH-11`
- 대상 프레임/노드:
  - `3039:24906` — `3. calendar_리뉴얼[Dark]_HTML 승인본`, 필사하지 않은 선택 날짜, 360×816pt
  - `2987:22796` — `3. calendar`, 필사를 완료한 선택 날짜, Light, 360×1101pt
  - `3051:899` — `3. calendar_리뉴얼[Dark]_답변 미작성`, 필사를 완료한 선택 날짜, 360×1101pt
- 대상 기기/프레임 크기: iOS, Figma 360pt 폭, Light/Dark. 짧은 상태는 360×816pt 전체 프레임, 완료 상태는 360×1101pt 전체 스크롤 콘텐츠.
- 표시 데이터/상호작용: 2025년 3월, 헤더 스트릭 100일, 날짜 선택, 이전·다음 달 이동, 월 통계 선택, 미필사 명언 카드 선택 시 Home 이동, 완료 카드 액션 및 질문 입력 UI.
- 검증 상태: 구현 전 기준 확보
- 기준 이미지:
  - `docs/design-qa/assets/calendar-figma/2026-08-30-calendar-completed-2987-22796-reference.png`
  - `docs/design-qa/assets/calendar-figma/2026-09-20/calendar-no-handwriting-3039-24906-reference.png`
  - `docs/design-qa/assets/calendar-figma/2026-09-20/calendar-handwriting-3051-899-reference.png`
- QA 기록: `docs/design-qa/2026-09-20-calendar-renewal-dark-qa.md`
- 2026-10-07 답변 저장 QA: `docs/design-qa/2026-10-07-ios-home-calendar-answer-qa.md`
- 2026-10-07 QA 조사: [완료 카드 명언 작업](3_calendar_qa_2026-10-07_actions.md), [질문 답변 저장](2_home_qa_2026-10-07_answer.md), [공통 응답 지연](common_qa_2026-10-07_latency.md)
- 2026-10-07 완료 카드 액션 구현 QA: [Figma 대조 기록](../design-qa/2026-10-07-calendar-actions-qa.md)

### 2026-10-07 완료 카드 명언 액션 대상

- Figma URL/전체 프레임: [Light `2987:22796`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796) 360×1101pt, [Dark `3051:899`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3051-899) 360×1101pt. 상태바, 배경, safe area, 하단 탐색/indicator 포함 기준 이미지는 위 `calendar-figma` 경로다.
- 액션 컴포넌트: 완료 날짜 카드 Light `2987:22949`–`2987:22975` (해당 하위 ID는 2026-10-07 Figma MCP에서 직접 조회되지 않아 전체 프레임 이미지로 확인), Dark `3051:1049`–`3051:1074`. `CalendarSelectedDaySection` 아래 `CalendarSelectedQuoteSection`의 복사/공유/좋아요/이미지 행이 담당한다.
- 표시 데이터: 선택 날짜의 `dailyQuoteSeq`, 명언/저자, 좋아요 상태, 이미지 경로. 날짜를 전환해도 각 액션은 현재 선택한 완료 레코드만 대상으로 한다.
- 대상 상태와 동작: Light/Dark 완료 날짜, 좋아요 비선택/선택, 이미지 미등록/등록 후 보기/변경/삭제. 복사는 선택 명언, 공유는 기존 공유 화면, 좋아요와 이미지는 기존 Home use case 계약을 사용한다. 미완료 날짜의 기존 Home 이동은 유지한다.
- 검증 상태: 네 액션 연결과 단위/UI 테스트 통과. 390×844pt 런타임과 360×1101pt Figma 전체 프레임이 달라 최종 화면 시각 수용은 `Blocked`; 컴포넌트와 조립 화면의 부분 비교·남은 차이는 [QA 기록](../design-qa/2026-10-07-calendar-actions-qa.md)에 남긴다.

### 2026-10-07 완료 카드 답변 저장 대상

- Figma URL/노드: [Light `2987:22796`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796), [Dark `3051:899`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3051-899).
- 컴포넌트: `CalendarSelectedDaySection` 완료 상태의 질문 카드. 월간 응답의 날짜별 질문·답변을 사용하고 기존 `HomeQuestionAnswerCard`의 입력·기록·수정 상태를 연결한다.
- 데이터/상호작용: 날짜 선택 시 해당 일자의 답변을 표시한다. 회원 저장 성공 후 월간 레코드를 갱신하고 Home 재조회 경계를 둔다. 미필사 카드에는 질문 카드를 추가하지 않는다.
- 대상 상태/예외: Light/Dark 완료 카드, 답변 없음·입력·저장 후·수정, 긴 질문·답변, 날짜·월 전환. 전체 360×1101pt 기준을 QA 기록에 남긴다.
- QA 기록: [2026-10-07 Home·Calendar 답변](../design-qa/2026-10-07-ios-home-calendar-answer-qa.md).

### 컴포넌트 분해

| 컴포넌트 | Figma 노드 | 책임 | 조립 위치 | 검증 상태 |
|---|---|---|---|---|
| `HomeHeader` | `3039:25050`, `3051:1094` | 로고, 100일 스트릭, My page 진입 | `CalendarView` 상단 | 미검증 |
| `CalendarMonthSection` | `3039:24908`, `3051:902` | 월 이동, 요일/날짜 그리드, 선택 및 기록 아이콘 | `CalendarView` 스크롤 콘텐츠 | 미검증 |
| `CalendarCountSection` | `3039:25035`, `3051:1040` | 월 좋아요/필사 횟수 | 월 카드 아래 | 미검증 |
| `CalendarSelectedDaySection` 미필사 | `3039:25073`, `3039:25079` | 100pt 캐릭터/안내와 80pt 명언 카드 | 통계 아래 | 미검증 |
| `CalendarSelectedDaySection` 완료 | Light `2987:22949`–`2987:22975`, Dark `3051:1049`–`3051:1074` | 133pt 명언/액션 카드. 액션 텍스트는 Light `#565149`, Dark `#9E9E9E` | 통계 아래 | 자동 UI 테스트 통과, 육안 검증 대기 |
| 캘린더 하단 내비게이션 | `3039:25097`, `3051:1117` | Home/Calendar/My page 3개 목적지 | 캘린더 콘텐츠 아래 | 미검증 |
| 광고 surface | `3039:27545`, `3051:1088` | 이번 출시에서 제외 | 렌더링하지 않음 | 사용자 승인 |

### 변경 디자인에서 고정된 배치

- 월 카드: x=20, y=90, 320×396pt.
- 월 통계: 월 카드 아래 10pt, 우측 정렬.
- 미필사 상태: 안내 영역은 통계 직후 시작하며 명언 카드가 안내 영역과 16pt 겹친다.
- 완료 상태: 명언 카드는 통계 아래 10pt, 질문 영역은 명언 카드 아래 10pt에 배치한다.
- 캘린더 화면의 하단 내비게이션은 `Home / Calendar / My page` 3개이며 광고 surface는 렌더링하지 않는다.

## Figma composition (2026-08-30 rework)

- Render targets: light section `2929:13366`; actual states `2985:21952` (basic, 360×816), `2985:22510` (expanded selection, 360×1101), and `2987:22796` (completed selection, 360×1101) in Figma file `VdFocqyqTgevMVCQxwAQ2X`. Sections are orientation only; implementation is based on the three actual frames.
- Header: `HomeHeader` supplies the Figma logo at x20, the genuine `MonthlySummaryData.streakCount` surfaced as `CalendarFeature.State.displayStreakCount`, and the existing profile action only. It deliberately replaces Calendar's previous screen-specific top-bar variant.
- Calendar shell: `CalendarMonthSection` is 320×396 at 360pt (20pt inset), radius 12, fixed seven 36pt columns with six 11pt gutters, 40pt weekday row, and six 50pt date rows. Existing reducer-backed month limits and date selection remain unchanged.
- Component map: `CalendarDayCell` owns the 36×50/radius-10 selected day and 12pt record icons; `CalendarCountSection` keeps the genuine 16pt monthly heart/fire totals and quote-list action; `CalendarSelectedDaySection` selects incomplete/completed composition and retains the existing selected-quote → Home navigation.
- Data map: `MemberQuotesData.likeYn == "Y"` renders the Figma heart. `completed || todayCompleted` renders the fire and selects completed detail; no quote-text heuristic, Calendar store, API, or persistence was added.
- Detail states: incomplete shows the durable 100pt Figma handwriting character/message followed by the 80pt tappable quote card. Completed shows the 133pt quote/action card and then the scrollable 200-grapheme question UI. Copy/share/like/image affordances remain outside this answer task. The answer CTA uses the v2 answer API for members; nonmembers keep the answer in the current app session. The selected date's `questionKo` and `answer` come from the v2 monthly response when present.
- The shared bottom navigation follows the Figma reference with Home/Calendar/My page only. QuoteList remains an internal route for the existing monthly-count action, and all ad UI is excluded from this release by user approval.

## 기본 동작

- 디폴트: 현재 날짜가 달력에서 선택된 상태로 진입
- 월 이동 시 해당 월 1일이 자동 선택됨
- 2025년 6월 16일 이전 날짜 disable 처리
- 오늘 날짜 이후 월로 이동 불가
- 오늘 날짜 이후 일자 disable 처리

## 달력 영역

- 월별 달력 표시
- 날짜별로 필사(또는 사진) 여부 및 좋아요 여부 아이콘 표시
- 특정 날짜 클릭 시 하단에 해당일 명언 노출
- 캘린더 화면의 좌우 여백은 360pt Figma 기준 20pt이며, 월 카드 자체는 정확히 320pt다.
- 날짜 열은 같은 비율로 확장하지 않는다. Figma의 고정 36pt 폭과 11pt 간격을 보존한다.

## 하단 명언 영역

- 선택 날짜의 명언 노출
- 클릭 시 해당 날짜의 Home 화면으로 이동

## 하단 통계 영역 (해당 월 필사/좋아요 개수)

### V1

- 클릭 시 List 화면으로 이동
- 백엔드에서 최근 1년 데이터만 조회 (V2 배포 대응)

### V2

- 클릭 시 List 화면으로 이동
- List 화면의 조회 기간이 해당 월(1일 ~ 마지막일)로 자동 셋팅됨
- 조회 기간은 최대 1년 단위만 지정 가능

---

## API

### 월간 명언 조회 (비회원)

```
GET /api/v1/quotes/monthly?yearMonth={yearMonth}
```

**Query Parameter**

| 파라미터 | 형식 | 예시 |
|----------|------|------|
| yearMonth | String | `2025-06` |

**Response: `List<MonthlyQuoteResponse>`**

### 월간 명언 조회 (회원)

```
GET /api/v2/member-quotes/monthly?yearMonth={yearMonth}
```

**Query Parameter**

| 파라미터 | 형식 | 예시 |
|----------|------|------|
| yearMonth | String | `2025-06` |

**Response: `MemberMonthlyQuoteResponse`**

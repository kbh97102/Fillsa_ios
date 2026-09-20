# [Calendar] `3.calendar`

## Figma UI 기준 (2026-09-20 변경 디자인)

- Figma URL:
  - 필사하지 않은 경우: `https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%25E2%259C%2592%25EF%25B8%258F%25ED%2595%2584%25EC%2582%25AC?node-id=3039-24906&t=pxxJ6i8fGGEVuuMH-11`
  - 필사를 한 경우: `https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%25E2%259C%2592%25EF%25B8%258F%25ED%2595%2584%25EC%2582%25AC?node-id=3051-899&t=pxxJ6i8fGGEVuuMH-11`
- 대상 프레임/노드:
  - `3039:24906` — `3. calendar_리뉴얼[Dark]_HTML 승인본`, 필사하지 않은 선택 날짜, 360×816pt
  - `3051:899` — `3. calendar_리뉴얼[Dark]_답변 미작성`, 필사를 완료한 선택 날짜, 360×1101pt
- 대상 기기/프레임 크기: iOS, Figma 360pt 폭, 다크 모드. 짧은 상태는 360×816pt 전체 프레임, 완료 상태는 360×1101pt 전체 스크롤 콘텐츠.
- 표시 데이터/상호작용: 2025년 3월, 헤더 스트릭 100일, 날짜 선택, 이전·다음 달 이동, 월 통계 선택, 미필사 명언 카드 선택 시 Home 이동, 완료 카드 액션 및 질문 입력 UI.
- 검증 상태: 구현 전 기준 확보
- 기준 이미지:
  - `docs/design-qa/assets/calendar-figma/2026-09-20/calendar-no-handwriting-3039-24906-reference.png`
  - `docs/design-qa/assets/calendar-figma/2026-09-20/calendar-handwriting-3051-899-reference.png`
- QA 기록: `docs/design-qa/2026-09-20-calendar-renewal-dark-qa.md`

### 컴포넌트 분해

| 컴포넌트 | Figma 노드 | 책임 | 조립 위치 | 검증 상태 |
|---|---|---|---|---|
| `HomeHeader` | `3039:25050`, `3051:1094` | 로고, 100일 스트릭, My page 진입 | `CalendarView` 상단 | 미검증 |
| `CalendarMonthSection` | `3039:24908`, `3051:902` | 월 이동, 요일/날짜 그리드, 선택 및 기록 아이콘 | `CalendarView` 스크롤 콘텐츠 | 미검증 |
| `CalendarCountSection` | `3039:25035`, `3051:1040` | 월 좋아요/필사 횟수 | 월 카드 아래 | 미검증 |
| `CalendarSelectedDaySection` 미필사 | `3039:25073`, `3039:25079` | 100pt 캐릭터/안내와 80pt 명언 카드 | 통계 아래 | 미검증 |
| `CalendarSelectedDaySection` 완료 | `3051:1049`, `3051:1076` | 133pt 명언/액션 카드와 298pt 질문 입력 | 통계 아래 | 미검증 |
| 캘린더 하단 내비게이션 | `3039:25097`, `3051:1117` | Home/Calendar/My page 3개 목적지 | 캘린더 콘텐츠 아래 | 미검증 |
| 광고 surface | `3039:27545`, `3051:1088` | 35pt 광고 자리 표시 | 전체 프레임 하단 | 미검증 |

### 변경 디자인에서 고정된 배치

- 월 카드: x=20, y=90, 320×396pt.
- 월 통계: 월 카드 아래 10pt, 우측 정렬.
- 미필사 상태: 안내 영역은 통계 직후 시작하며 명언 카드가 안내 영역과 16pt 겹친다.
- 완료 상태: 명언 카드는 통계 아래 10pt, 질문 영역은 명언 카드 아래 10pt에 배치한다.
- 캘린더 화면의 하단 내비게이션은 `Home / Calendar / My page` 3개이며 그 아래 35pt 광고 surface가 온다.

## Figma composition (2026-08-30 rework)

- Render targets: light section `2929:13366`; actual states `2985:21952` (basic, 360×816), `2985:22510` (expanded selection, 360×1101), and `2987:22796` (completed selection, 360×1101) in Figma file `VdFocqyqTgevMVCQxwAQ2X`. Sections are orientation only; implementation is based on the three actual frames.
- Header: `HomeHeader` supplies the Figma logo at x20, the genuine `MonthlySummaryData.streakCount` surfaced as `CalendarFeature.State.displayStreakCount`, and the existing profile action only. It deliberately replaces Calendar's previous screen-specific top-bar variant.
- Calendar shell: `CalendarMonthSection` is 320×396 at 360pt (20pt inset), radius 12, fixed seven 36pt columns with six 11pt gutters, 40pt weekday row, and six 50pt date rows. Existing reducer-backed month limits and date selection remain unchanged.
- Component map: `CalendarDayCell` owns the 36×50/radius-10 selected day and 12pt record icons; `CalendarCountSection` keeps the genuine 16pt monthly heart/fire totals and quote-list action; `CalendarSelectedDaySection` selects incomplete/completed composition and retains the existing selected-quote → Home navigation.
- Data map: `MemberQuotesData.likeYn == "Y"` renders the Figma heart. `completed || todayCompleted` renders the fire and selects completed detail; no quote-text heuristic, Calendar store, API, or persistence was added.
- Detail states: incomplete shows the durable 100pt Figma handwriting character/message followed by the 80pt tappable quote card. Completed shows the 133pt quote/action card and then the scrollable 200-grapheme question UI. Calendar has no copy/share/like/image or prompt-answer persistence/navigation contract: those Figma affordances are intentionally non-mutating, and the answer CTA has no side effect until a separately owned data/routing contract is approved.
- The shared bottom navigation follows the Figma reference with Home/Calendar/My page only. QuoteList remains an internal route for the existing monthly-count action, and the static ad surface remains intact.

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

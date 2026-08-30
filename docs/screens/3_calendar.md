# [Calendar] `3.calendar`

## Figma composition (2026-08-30 rework)

- Render targets: light section `2929:13366`; actual states `2985:21952` (basic, 360×816), `2985:22510` (expanded selection, 360×1101), and `2987:22796` (completed selection, 360×1101) in Figma file `VdFocqyqTgevMVCQxwAQ2X`. Sections are orientation only; implementation is based on the three actual frames.
- Header: `HomeHeader` supplies the Figma logo at x20, the genuine `MonthlySummaryData.streakCount` surfaced as `CalendarFeature.State.displayStreakCount`, and the existing profile action only. It deliberately replaces Calendar's previous screen-specific top-bar variant.
- Calendar shell: `CalendarMonthSection` is 320×396 at 360pt (20pt inset), radius 12, fixed seven 36pt columns with six 11pt gutters, 40pt weekday row, and six 50pt date rows. Existing reducer-backed month limits and date selection remain unchanged.
- Component map: `CalendarDayCell` owns the 36×50/radius-10 selected day and 12pt record icons; `CalendarCountSection` keeps the genuine 16pt monthly heart/fire totals and quote-list action; `CalendarSelectedDaySection` selects incomplete/completed composition and retains the existing selected-quote → Home navigation.
- Data map: `MemberQuotesData.likeYn == "Y"` renders the Figma heart. `completed || todayCompleted` renders the fire and selects completed detail; no quote-text heuristic, Calendar store, API, or persistence was added.
- Detail states: incomplete shows the durable 100pt Figma handwriting character/message followed by the 80pt tappable quote card. Completed shows the 133pt quote/action card and then the scrollable 200-grapheme question UI. Calendar has no copy/share/like/image or prompt-answer persistence/navigation contract: those Figma affordances are intentionally non-mutating, and the answer CTA has no side effect until a separately owned data/routing contract is approved.
- Existing shared 4-tab navigation and static ad surface remain intact. The Figma reference has 3 tabs, so whole-frame parity remains product-scope blocked until navigation ownership approves a 3/4-tab decision.

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

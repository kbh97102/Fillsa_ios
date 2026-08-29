# [Calendar] `3.calendar`

## Figma light/dark composition (2026-08-30)

- Render targets: light `2985:21952`, dark `3039:28370` in Figma file `VdFocqyqTgevMVCQxwAQ2X`. Parent sections `2929:13366` and `2929:6874` are orientation only, not render targets.
- Root surfaces: light `#FFEFCC`, dark `#212121`. The responsive 320pt-at-360pt month card is inset 20pt, has a 12pt radius, and uses 50%-white / `#FFCB5C` light treatment or `#424242` / `#616161` dark treatment.
- Component map: `CalendarMonthSection` owns month movement, weekday/grid geometry and cell selection; `CalendarDayCell` owns the 12pt record indicators; `CalendarCountSection` owns the 16pt heart/flame legend and existing quote-list action; `CalendarSelectedDaySection` owns the selected quote and uncompleted-writing companion while preserving the existing Home action.
- Data map: `MemberQuotesData.likeYn == "Y"` renders the Figma heart. A local writing completion (`completed`, with `todayCompleted` retained as the historical mirror) renders the Figma flame. No Calendar data/store/API contract was added.
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
- 캘린더 화면의 좌우 여백은 화면 루트에서 20pt 한 번만 적용하고, 공용 탑바는 Android `HomeTopSection`과 동일하게 세로 10pt 패딩을 가진다.
- Figma 360pt 캔버스의 320pt 월/통계/명언 카드는 고정 폭이 아니라 좌우 20pt 여백의 결과다. 기기 폭이 달라져도 세 카드는 남은 화면폭을 채우며, 달력 열은 11pt 간격을 유지한 채 같은 비율로 확장한다.

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

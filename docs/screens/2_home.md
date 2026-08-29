# [Home] `2.home`

## Figma UI 기준

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=2929-13556
- 대상 프레임/노드: `2929:13556` (`2.home`)
- 대상 기기/프레임 크기: light state. Request supplied 360×720, but Figma MCP metadata/export inspected on 2026-08-29 resolves the authoritative node to 360×821; implementation/QA use the actual exported 360×821 frame.
- 검증 상태: 구현 전 Figma 기준 이미지 확보. Runtime full-frame capture is pending because CoreSimulatorService is unavailable in the current environment.
- 기준 이미지: `docs/design-qa/assets/home-figma/2026-08-29-home-figma-reference.png`
- QA 기록: `docs/design-qa/2026-08-29-home-figma-ui-qa.md`

### 컴포넌트 분해

| 컴포넌트 | Figma 노드 | 책임 | 조립 위치 | 검증 상태 |
|---|---|---|---|---|
| Status/top surface | `2929:13557`, `2929:15476` | `HomeHeader`: safe-area background, 60×26.666 logo, optional real streak, My Page action | `HomeView` top | 미검증 |
| Date controls | `2929:17013`, `2929:15661`, `2929:17161`, `2929:17154`, `2929:13653` | `HomeMonthSelector` (73×30) + `HomeWeekStrip`; completed dates come only from `StreakClient.getAllLocal()` records with `isDailyWritingCompleted == true`; selected day has priority (white/gray text, no completion badge) | `HomeDateControls` below top surface | 미검증 |
| Locale prompt | `2929:15520` | Typing prompt and Korean/English switch | `HomeView` | 미검증 |
| Quote card | `2929:13642` | `HomeQuoteCard`: local Figma texture, quote/author search action, and date swipe; on today's latest quote the forward swipe emits no next action | `HomeView` | 미검증 |
| Quote actions | `2929:15503` | `HomeQuoteActionRow`: 16pt local assets, 42pt row/dividers; existing copy, share, live like toggle, and image registration actions | `HomeView` | 미검증 |
| Question/answer | `2929:13630` | `HomeQuestionAnswerCard`: 200-grapheme-capped local answer input, Figma placeholder/count/CTA asset; existing `openTyping` destination action retained | `HomeView` | QA Blocked — Home question data source and typed-answer handoff contract are absent |
| Bottom navigation/ad | `3087:29254`, `3087:29249` | Existing app tab navigation and static ad surface | `AppView` / `FillsaBottomNavigationBar` | 미검증 |

## 기본 동작

- 디폴트: 현재 날짜 기준 명언 조회, 언어 기본값 한글
- 오늘 날짜 이후는 조회 불가

## 상단 영역

- 날짜(년월일, 요일) 노출
- 명언 노출
- 이전/다음 버튼으로 날짜별 명언 조회
- 한글/영어 전환 버튼으로 언어별 명언 조회
- 저자명 클릭 시 위키백과 URL로 이동
- 명언 영역 클릭 시 타이핑 화면(`2-3.write`)으로 전환

## 사진 영역

| 상태 | 동작 |
|------|------|
| 사진 미업로드 | 기본 이미지 노출 |
| 사진 업로드 | 업로드한 이미지 노출 |
| 비회원 | 잠금 표시 + 클릭 시 `modal_login` 팝업 노출 |
| 회원 + 클릭 | 이미지 팝업(`2-2.img_check/upload`) 노출 |

## 하단 버튼

| 버튼 | 동작 |
|------|------|
| 복사하기 | "{명언} - {저자}" 형식으로 클립보드 복사 → '복사되었습니다.' 토스트 (`2-5.toast_copy`) |
| 좋아요 | 좋아요 토글 저장 |
| 공유 | 공유 화면(`2-4.img_share`)으로 이동 |

---

## 타이핑 화면 `2-3.write`

### 상단

- 명언 노출, 타이핑 시 글자별 색상 변경
  - 올바른 입력: 검정
  - 틀린 입력: 빨강 (틀린 경우 한 글자까지만 입력 가능, 계속 타이핑 시 마지막 글자만 교체)
- 한글/영어 모두 타이핑 가능

### 하단

- 하단 내비게이션 바 및 광고 영역 숨김
- OS 자판 표시

| 버튼 | 동작 |
|------|------|
| 나가기 | 이전 화면으로 이동 (타이핑 내역 저장) |
| 복사 | "{명언} - {저자}" 형식으로 클립보드 복사 |
| 공유 | 바텀시트로 공유 (텍스트 형식: "{명언} - {저자}") |
| 좋아요 | 좋아요 토글 저장 |

- 뒤로가기 버튼 클릭 시에도 타이핑 내역 저장

---

## 이미지 팝업 `2-2.img_check/upload`

- 이미지 상세 화면 노출, 배경 딤 처리

| 버튼 | 동작 |
|------|------|
| 변경 | OS 팝업 → 사진 촬영 or 갤러리 업로드 → 성공 시 '이미지가 변경되었습니다.' 토스트 |
| 삭제 | 삭제 확인 팝업 → 확인 시 '이미지가 삭제되었습니다.' 토스트 |
| 확인 | 직전 Home 화면으로 이동 |

### 삭제 팝업

> "삭제하시겠습니까?"

| 버튼 | 동작 |
|------|------|
| 삭제 | 이미지 삭제 후 토스트 노출 |
| 취소 | 팝업 닫기 |

---

## 공유 화면 `2-4.img_share`

### V1

- 공유 이미지 배경에 명언 노출
- X 버튼으로 화면 닫기

| 버튼 | 동작 |
|------|------|
| 저장 | 이미지를 핸드폰에 저장 → '사진첩에 이미지가 저장되었습니다.' 토스트 |
| 공유 | 바텀시트로 공유할 앱 선택 |
| 복사 | OS 클립보드에 `"{명언} - {저자}"` 텍스트 저장 → '복사되었습니다.' 토스트 |

### V2 (V1 포함)

- 앱 설치 후 첫 진입 시에만 가이드 화면 노출
- 좌우 슬라이드로 공유 이미지 변경 가능
- 카카오톡 공유하기 지원 (템플릿: 이미지 + 명언 문구)
- 저장 / 공유 / 복사 버튼 및 하단 광고 영역 노출

---

## API

### 일일 명언 조회 (비회원)

```
GET /api/v1/quotes/daily?quoteDate={quoteDate}
```

**Response: `DailyQuotaNoToken`**

### 일일 명언 조회 (회원)

```
GET /api/v1/member-quotes/daily?quoteDate={quoteDate}
```

**Response: `DailyQuoteDto`**

- 회원 일일 명언 응답에는 `quoteDate` 필드가 포함되지 않는다.
- iOS는 응답 디코딩 시 `quoteDate`를 빈 기본값으로 처리한다. 화면의 현재 날짜와 필사 화면 전달 날짜는 선택한 날짜 상태에서 별도로 계산한다.

### 좋아요

```
POST /api/v1/member-quotes/{dailyQuoteSeq}/like
```

**Request Body: `LikeRequest`**  
**Response: `Int`**

### 이미지 업로드

```
POST /api/v1/member-quotes/{dailyQuoteSeq}/images
Content-Type: multipart/form-data
```

**Request: `MultipartBody.Part` (image 파트)**  
**Response: `MemberQuoteImageResponse`**

### 이미지 삭제

```
DELETE /api/v1/member-quotes/{dailyQuoteSeq}/images
```

**Response: `Int`**

### 타이핑 저장

```
POST /api/v1/member-quotes/{dailyQuoteSeq}/typing
```

**Request Body: `TypingQuoteRequest`**  
**Response: `Int`**

### 타이핑 조회

```
GET /api/v1/member-quotes/{dailyQuoteSeq}/typing
```

**Response: `MemberTypingQuoteResponse`**

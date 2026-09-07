# [Home] `2.home`

## Figma UI 기준

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=2929-13556
- 대상 프레임/노드: `2929:13556` (`2.home`)
- Dark render frame/node: `3039:26518` (`2.home`, 360×821). The section parent `2929:9603` is not a render target.
- 대상 기기/프레임 크기: light state. Request supplied 360×720, but Figma MCP metadata/export inspected on 2026-08-29 resolves the authoritative node to 360×821; implementation/QA use the actual exported 360×821 frame.
- 검증 상태: Blocked — seven current-build iPhone 17 Pro captures are retained, but their 402×874 runtime frame does not match the 360×821 Figma target, so strict full-frame acceptance remains unavailable.
- 기준 이미지: `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/` (default, calendar-open, question-flow, streak-tooltip, image-flow)
- QA 기록: `docs/design-qa/2026-09-07-ios-home-interactions-qa.md`

### 2026-09-07 Home 상호작용 구현 계약

- 상위 범위: `2929:17193` (`2. home`, SECTION)
- 기본 Home: `2929:13556`; Dark Home: `3039:26518`
- 월 선택 기본/열림 컴포넌트: `2929:15667` / `2929:16221`
- 달력 열림 화면: `3139:1501`; 팝업 본체 `2929:16227`; 이전 월 `2929:16229`; 연도 `2929:16232`; 월 `2929:16236`; 다음 월 `2929:16240`; 요일 `2929:16243`; 날짜 그리드 `2929:16258`
- 주간 날짜: `3204:2435`. 현재/선택 날짜가 오른쪽 끝에 오도록 7일을 노출하고 과거 방향 탐색을 지원한다.
- 질문 컴포넌트 세트: `3087:29377`; 기본 `3087:29376`; 입력 포커스 `3139:1399`; 기록 완료 `3087:29378`
- 질문 흐름: `3110:33782`; 기록 전 `3110:33783`; 기록 중 `3110:34152`; 저장 토스트 `3110:34293`; 기록 후 `3110:34438`
- 연속 필사 안내 화면: `2929:18871`; 툴팁 그룹 `2929:19015`; 툴팁 `2929:19016`; Calendar 링크 `2929:19017`
- 이미지 흐름: `3223:5107`; 등록 전 `3223:4982`; 등록 후 `3223:4647`; 보기 `3223:4773`; 대체 보기 `2929:19326`; 삭제 확인 `2929:19488`
- 복사 토스트: 화면 `2929:19645`, 토스트 `2929:19773`; 좋아요 선택 상태 `2929:19784`
- 구현 범위 밖의 연결 화면: 필사 `2929:17920`, 공유 `2929:18239`/`2929:18543`, 로그인 모달 `2929:19027`. 기존 route만 유지한다.
- 기준 캡처: `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/`

#### 상태와 동작

1. 월 영역 탭은 전체 Calendar 탭으로 즉시 이동하지 않고 Home 위에 `248×335pt` 달력 팝업을 토글한다. 외부 탭은 닫기, 날짜 선택은 Home 날짜 갱신·명언 재조회·팝업 닫기를 수행한다.
2. 연속 필사 수가 0일 때 상태 아이콘 탭은 안내 툴팁을 표시한다. 외부 탭은 닫고, `나의 필사현황 보기`는 기존 Calendar 탭으로 이동한다.
3. 질문 CTA는 명언 필사 화면으로 이동하지 않는다. 200 grapheme 이내의 답변을 Home 세션 상태에 기록하고 `답변을 기록했어요.` 토스트와 완료/수정 상태를 표시한다. 서버·DB 영구 저장은 별도 data contract가 없어 이번 UI 범위에서 제외한다.
4. 이미지 등록/보기/변경/삭제, 복사 토스트, 좋아요 선택은 기존 domain/API 연결을 보존하며 위 노드의 시각 상태로 검증한다.
5. Figma의 3-tab 하단 바와 현재 앱의 4-route 하단 바 차이는 앱 전역 제품 결정이므로 이번 Home 범위에서 변경하지 않는다.

### 컴포넌트 분해

| 컴포넌트 | Figma 노드 | 책임 | 조립 위치 | 검증 상태 |
|---|---|---|---|---|
| Status/top surface | `2929:13557`, `2929:15476` | `HomeHeader`: safe-area background, 60×26.666 logo, loaded zero-streak warning, optional real streak, My Page action | `HomeView` top | Partial current-build runtime evidence; strict acceptance blocked by viewport only |
| Date controls | `2929:15667`, `2929:16221`, `3139:1501`, `3204:2435` | 월 선택 toggle, bounded inline month calendar, selected day at right edge of the strip; completed dates only use genuine completed writing records | `HomeDateControls` below top surface | Partial current-build runtime evidence; strict acceptance blocked by viewport only |
| Locale prompt | `2929:15520` | Typing prompt and Korean/English switch | `HomeView` | Partial current-build runtime evidence; strict acceptance blocked by viewport only |
| Quote card | `2929:13642` | `HomeQuoteCard`: local Figma texture, quote/author search action, and date swipe; on today's latest quote the forward swipe emits no next action | `HomeView` | Partial current-build runtime evidence; strict acceptance blocked by viewport only |
| Quote actions | `2929:15503` | `HomeQuoteActionRow`: 16pt local assets, 42pt row/dividers; existing copy, share, live like toggle, and image registration actions | `HomeView` | Partial current-build runtime evidence; strict acceptance blocked by viewport only |
| Question/answer | `3087:29376`, `3139:1399`, `3087:29378`, `3110:34293` | 200-grapheme 입력, 세션 기록, 저장 토스트, 완료/수정 상태. 명언 필사 route와 분리한다. | `HomeView` / `HomeFeature` | Partial current-build runtime evidence; strict acceptance blocked by viewport only; 영구 저장은 별도 범위 |
| Bottom navigation/ad | `3087:29254`, `3087:29249` | Figma-common Home/Calendar/My page 32pt light assets, existing 4-tab shared navigation, and static 35pt ad surface | `AppView` / `FillsaBottomNavigationBar` / `HomeAdSurface` | Partial current-build runtime evidence; strict acceptance blocked by viewport only |
| Dark Home appearance | `3039:26518` | `HomeFigmaPalette` resolves dark root `#212121`, card/input `#424242`, outlines/dividers `#616161`, white primary text, `#E0E0E0` action text, and `#9E9E9E` inactive weekday/input metadata. Local Figma SVG dark appearances cover logo, profile, quote texture, author search, and quote action icons. | `HomeView` / Home Figma components | Partial current-build runtime evidence; strict acceptance blocked by viewport only |

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

## 오늘의 질문 답변

- Figma 입력 박스, 200 grapheme 제한, 글자 수, 기록/수정 CTA 및 접근성 라벨을 구현한다.
- 기록 CTA는 Home 세션 상태에 답변을 저장하고 `답변을 기록했어요.` 토스트를 표시한다. 수정 CTA는 동일 카드에서 편집 상태로 돌아간다.
- 질문 답변은 명언 필사 이동과 분리하며 `TypingFeature.korTyping`/`engTyping`이나 회원 명언 API에 전달하지 않는다.
- 현재 프로젝트에서 발견된 `memo`, `korTyping`, `engTyping` 저장 계약은 모두 `memberQuoteSeq`/명언 필사 전용이며 일반 질문 답변 계약이 아니다.
- 영구 저장 후속 기능은 (1) 질문 식별자와 날짜를 제공하는 Home 질문 data contract, (2) 답변 레코드의 저장·조회·수정/삭제 정책을 별도 범위에서 정한 뒤 구현한다.

## 하단 내비게이션 및 광고

- Figma `3087:29254`는 3개(Home/Calendar/My page) 120×60pt 항목이며, 공통 세 탭은 durable `home_nav_*` Figma SVG를 32pt template icon으로 사용한다. 선택 색은 `#5C65FF`, 비선택 텍스트/아이콘은 `#212121`이다.
- iOS 앱은 QuoteList를 포함한 4개 shared route를 보존한다. 이는 이번 Home 범위 밖의 전역 제품 결정이며, 현재 strict acceptance `Blocked` 사유는 402×874pt 대 360×821의 runtime viewport 차이만이다.
- Figma `3087:29249`의 35pt 정적 AD 표면(AD badge, “광고가 들어가는 영역입니다.”)은 기존 `HomeAdSurface`가 담당한다. 광고 제공/탭 구성 변경은 제품 결정이 필요한 별도 범위다.

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

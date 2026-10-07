# [Home] `2.home`

## Figma UI 기준

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=2929-13556
- 대상 프레임/노드: `2929:13556` (`2.home`)
- Dark render frame/node: `3039:26518` (`2.home`, 360×821). The section parent `2929:9603` is not a render target.
- 대상 기기/프레임 크기: light state. Request supplied 360×720, but Figma MCP metadata/export inspected on 2026-08-29 resolves the authoritative node to 360×821; implementation/QA use the actual exported 360×821 frame.
- 검증 상태: Blocked — seven current-build iPhone 17 Pro captures are retained, but their 402×874 runtime frame does not match the 360×821 Figma target, so strict full-frame acceptance remains unavailable.
- 기준 이미지: `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/` (default, calendar-open, question-flow, streak-tooltip, image-flow)
- QA 기록: `docs/design-qa/2026-09-07-ios-home-interactions-qa.md`
- 답변 키보드 회귀 QA: `docs/design-qa/2026-09-23-ios-home-answer-keyboard-qa.md`
- 2026-10-07 답변 저장 QA: `docs/design-qa/2026-10-07-ios-home-calendar-answer-qa.md`
- 2026-10-07 주간 조회 캐시 QA: [Home weekly cache QA](../design-qa/2026-10-07-ios-home-weekly-cache-qa.md)
- 날짜/연속필사 패딩 QA: `docs/design-qa/2026-09-25-ios-home-date-streak-padding-qa.md`
- 반응형 레이아웃 QA: `docs/design-qa/2026-09-25-ios-home-responsive-layout-qa.md`
- Dark root 상세 명세: `docs/screens/2_home_dark.md` (root `2929:9603`, 상태별 render node와 기준 이미지)
- 2026-10-07 QA 조사: [답변 저장](2_home_qa_2026-10-07_answer.md), [이미지 크기 제한](2_home_qa_2026-10-07_image_size.md), [이미지 팝업 크기](2_home_qa_2026-10-07_image_popup.md), [공통 응답 지연](common_qa_2026-10-07_latency.md)
- 이미지 업로드 바이트 처리 QA: [2026-10-07 Home image size](../design-qa/2026-10-07-ios-home-image-size-qa.md). Figma 이미지 흐름 `3223:5107`, 보기 팝업 `3223:4773`; 표시 상태와 컴포넌트는 위 Home 이미지 흐름 그대로다. 이번 변경은 사진 선택 후 업로드 전 바이트 변환과 임시 파일 수명에 한정된다.
- 2026-10-07 이미지 팝업 수정 QA: [Figma 대조 기록](../design-qa/2026-10-07-home-image-popup-qa.md)

- API 계약 갱신 메모: 아래의 “답변 서버 계약 없음/세션 기록” 설명은 해당 UI 구현 당시 범위다. 2026-09-03 운영 배포된 [v2 답변·주간 조회 계약](../superpowers/specs/2026-09-08-home-calendar-api-contract.md)에 맞춰 iOS 회원 답변 저장과 주간 조회를 연결했다. 실서버 왕복 검증은 위 QA 기록의 남은 작업이다.

### 2026-10-07 답변 저장 대상

- Figma: 질문 흐름 `3110:33782`, 기록 전 `3110:33783`, 입력 `3110:34152`, 성공 토스트 `3110:34293`, 기록 후 `3110:34438` (동일 파일 URL은 위 QA 조사 문서 참조).
- 컴포넌트: `HomeQuestionAnswerCard`가 v2 `questionKo`와 `answer`를 표시한다. `HomeView`는 기존 입력·기록·수정 UI를 유지하고 `HomeFeature`가 서버 저장 성공 후에만 완료 상태와 토스트를 바꾼다.
- 데이터/상호작용: 회원 조회의 날짜별 `dailyQuoteSeq`, 질문, 답변을 사용한다. 비회원 답변은 기존 앱 동작대로 세션 안에서 날짜별로 복원하며 서버에는 저장하지 않는다. 성공·실패·재진입·날짜 전환을 검증한다.
- 시각적 예외: 긴 서버 질문/답변, 키보드 포커스, 토스트 위치를 컴포넌트와 전체 360×821pt 프레임에서 확인한다.
- QA 기록: [2026-10-07 Home·Calendar 답변](../design-qa/2026-10-07-ios-home-calendar-answer-qa.md).

### 2026-10-07 회원 주간 조회 캐시

- Figma 기준: Home 전체 `2929:13556`, 주간 날짜 스트립 `3204:2435`의 현재 선택 날짜 우측 끝 배치와 명언 카드/질문 영역. 화면 구성과 날짜 선택 동작은 변경하지 않는다.
- 회원 첫 진입은 `GET /api/v2/member-quotes/weekly`에 `endDate` 없이 요청하고 서버 응답의 `endDate`를 7일 창 기준 날짜로 보관한다. 창 안 날짜 선택에는 HTTP 요청을 하지 않는다. 경계를 넘으면 서버 기준 7일 단위 `endDate`로 한 번 요청하고 기존 창 재진입은 캐시에서 읽는다.
- 같은 날짜의 답변·좋아요·이미지 변경은 메모리의 주간 캐시에 반영한다. 명언 ID가 없는 날짜는 날짜 셀은 유지하고 쓰기 액션의 기존 ID guard를 적용한다. 게스트는 기존 v1 일간 조회, 주간 응답에 선택 날짜가 누락된 회원은 v2 일간 조회를 사용한다.
- `HomeWeekStrip`과 명언 카드의 레이아웃·문구·자산은 수정하지 않았다. 새 데이터 경로의 요청 수와 날짜별 상태를 reducer 테스트 및 fixture UI 테스트로 확인했다. Figma 연결 재인증 필요와 런타임/Figma 프레임 크기 차이로 전체 시각 검증은 `Blocked`다.
- QA 기록: [주간 조회 캐시 QA](../design-qa/2026-10-07-ios-home-weekly-cache-qa.md).

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
5. 하단 바는 Figma와 사용자 확인에 따라 Home/Calendar/My page 3개 탭만 노출한다. QuoteList는 기존 기능 내부 이동 경로만 유지한다.
6. 답변 편집 포커스(`3139:1399`, 조립 화면 `3110:34152`)에서는 Home 헤더를 고정하고 본문을 스크롤해 기록 CTA를 키보드 바로 위에 유지한다. Home 하단 바는 키보드 위로 올라오지 않으며, 본문 드래그로 키보드를 내릴 수 있다.

### 컴포넌트 분해

| 컴포넌트 | Figma 노드 | 책임 | 조립 위치 | 검증 상태 |
|---|---|---|---|---|
| Status/top surface | `2929:13557`, `2929:15476` | `HomeHeader`: safe-area background, 60×26.666 logo, loaded zero-streak warning, optional real streak, My Page action | `HomeView` top | Partial current-build runtime evidence; strict acceptance blocked by viewport only |
| Date controls | `2929:15667`, `2929:16221`, `3139:1501`, `3204:2435` | 월 선택 toggle, bounded inline month calendar, selected day at right edge of the strip; completed dates only use genuine completed writing records | `HomeDateControls` below top surface | Partial current-build runtime evidence; strict acceptance blocked by viewport only |
| Locale prompt | `2929:15520` | Typing prompt and Korean/English switch | `HomeView` | Partial current-build runtime evidence; strict acceptance blocked by viewport only |
| Quote card | `2929:13642` | `HomeQuoteCard`: local Figma texture, quote/author search action, and date swipe; on today's latest quote the forward swipe emits no next action | `HomeView` | Partial current-build runtime evidence; strict acceptance blocked by viewport only |
| Quote actions | `2929:15503` | `HomeQuoteActionRow`: 16pt local assets, 42pt row/dividers; existing copy, share, live like toggle, and image registration actions | `HomeView` | Partial current-build runtime evidence; strict acceptance blocked by viewport only |
| Image upload and popup | image flow `3223:5107`, popup `3223:4773` | Selected image is prepared as a bounded JPEG before upload; the existing 320:373 popup displays the uploaded image, including the test fixture's local preview URL. No new controls or copy. | `HomeView` / `HomeImageDialog` | [Image size QA](../design-qa/2026-10-07-ios-home-image-size-qa.md); fixture runtime only, live server and strict Figma full-frame acceptance blocked |
| Question/answer | `3087:29376`, `3139:1399`, `3087:29378`, `3110:34152`, `3110:34293` | 200-grapheme 입력, 키보드 포커스 시 CTA 노출·대화형 키보드 닫기, 세션 기록, 저장 토스트, 완료/수정 상태. 명언 필사 route와 분리한다. | `HomeView` / `HomeFeature` | Focused interaction pass on iPhone 17 Pro; strict acceptance blocked by viewport only; 영구 저장은 별도 범위 |
| Bottom navigation | `3087:29254` | Figma-common Home/Calendar/My page 32pt light assets and shared 3-tab navigation | `AppView` / `FillsaBottomNavigationBar` | Partial current-build runtime evidence; strict acceptance blocked by viewport only |
| Dark Home appearance | `3039:26518` | `HomeFigmaPalette` resolves dark root `#212121`, card/input `#424242`, outlines/dividers `#616161`, white primary text, `#E0E0E0` action text, and `#9E9E9E` inactive weekday/input metadata. Local Figma SVG dark appearances cover logo, profile, quote texture, author search, and quote action icons. | `HomeView` / Home Figma components | Partial current-build runtime evidence; strict acceptance blocked by viewport only |

### 2026-09-25 날짜/연속필사 패딩 QA 범위

- 기준 프레임: `2929:13556` (`2.home`, Light, 360×821)
- 연속필사: 헤더 `2929:15476`, 연속필사 `2929:15495`, 프로필 `2929:15493`
- 날짜: 월 선택 `2929:15667` (x=20), 주간 스트립 `3204:2435` (x=102), 두 컴포넌트 간 9pt
- 대상 상태: 연속필사 100일, 완료 날짜 2개, 오늘 선택 상태
- 검증 상태: 수정 전 회귀 테스트 및 런타임 캡처 대기

### 2026-09-25 반응형 레이아웃 QA 범위

- 기준 프레임: `2929:13556` (`2.home`, Light, 360×821)
- 액션 행: `3207:3059` (`Frame 1000007716`, 버튼 비율 `70:70:70:107`)
- 질문 입력창: `2929:13630`, answer box `2929:13634` (174pt는 최소 높이)
- 명언 카드: `2929:13642` (150pt는 기본/최소 높이)
- 이미지 팝업: 화면 `3223:4773`, popup `3223:4966` (320:373 비율)
- 달력: 열림 화면 `3139:1501`, open component `2929:16221`, popup `2929:16227` (월 버튼 아래 6pt)
- 연속필사 안내: 화면 `2929:18871`, tooltip `2929:19016` (화살표 중심을 상태 버튼 중심에 정렬)
- 대상 상태: 기본 Home, 긴 명언+접근성 글자 크기, 달력 열림, zero-streak tooltip, 이미지 팝업
- 검증 상태: 구현 전

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
- iOS 앱의 공용 하단 바는 Home/Calendar/My page 3개 탭만 노출한다. QuoteList 구현은 기존 기능 내부 이동을 위해 유지한다.
- Figma `3087:29249`의 광고 자리 표시 영역은 이번 출시에서 제외한다. Home을 포함한 모든 화면에 광고 UI를 렌더링하지 않는다.

---

## 타이핑 화면 `2-3.write`

- Light target: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%E2%9C%92%EF%B8%8F%ED%95%84%EC%82%AC?node-id=2929-17920 (`2929:17920`)
- Dark target: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%E2%9C%92%EF%B8%8F%ED%95%84%EC%82%AC?node-id=3087-28815 (`3087:28815`)
- QA 기록: `docs/design-qa/2026-08-29-home-figma-ui-qa.md`, `docs/design-qa/2026-09-07-ios-home-dark-root-qa.md`

### 상단

- 명언 노출, 타이핑 시 글자별 색상 변경
  - 올바른 입력: 검정
  - 틀린 입력: 빨강 (틀린 경우 한 글자까지만 입력 가능, 계속 타이핑 시 마지막 글자만 교체)
- 한글/영어 모두 타이핑 가능

### 하단

- 하단 내비게이션 바 숨김
- OS 자판 표시

| 버튼 | 동작 |
|------|------|
| 나가기 | 이전 화면으로 이동 (타이핑 내역 저장) |
| 복사 | "{명언} - {저자}" 형식으로 클립보드 복사 |
| 공유 | 바텀시트로 공유 (텍스트 형식: "{명언} - {저자}") |
| 좋아요 | 좋아요 토글 저장 |
| 저장하기 | 흰색 채움과 `#212121` 텍스트. Light `3087:28769`는 `#212121` 테두리, Dark `3087:28973`은 흰색 테두리. 타이핑 내역 저장 후 이전 화면으로 이동 |

- 뒤로가기 버튼 클릭 시에도 타이핑 내역 저장

---

## 이미지 팝업 `2-2.img_check/upload`

- 이미지 상세 화면 노출, 배경 딤 처리
- Figma 기준: [전체 Home 이미지 보기 `3223:4773`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=3223-4773), 팝업 `3223:4966` (`notice_popup`). Light 360×821 전체 프레임, 중앙 팝업 320×373. 기준 이미지 `docs/design-qa/assets/home-responsive-layout/2026-09-27/figma-home-image-dialog.png` (전체 프레임) 및 2026-10-07 Figma MCP screenshot. 루트 배경, 상태바, safe area, 하단 navigation/home indicator를 포함한다.
- 대상 상태: 이미지 등록 후 보기. 가로/세로 사진 모두 같은 팝업 외곽과 중심을 유지하고 사진만 팝업 경계 안에서 `fill` crop한다. 다크 상태는 별도 디자인 `docs/screens/2_home_dark.md` 참조.
- 컴포넌트 분해 및 조립: `3223:4967` 사진 배경은 `HomeImageDialog`의 320×373 컨테이너 안에 배치한다. `3223:7071` 삭제 영역, `3223:4974` 명언/작가, `3223:4968` 하단 버튼 행을 같은 컨테이너 위에 조립한다. 전체 조립 화면은 `3223:4773`이다.
- 검증 상태: 가로/세로 이미지 팝업 외곽 고정과 crop은 iPhone 17e iOS 26.4 UI 테스트 및 전체 화면 캡처로 부분 통과. Figma 360×821과 런타임 390×844 불일치, 테스트 사진과 Figma 사진 차이 때문에 전체 조립 화면 최종 수용은 `Blocked`. [2026-10-07 QA 기록](../design-qa/2026-10-07-home-image-popup-qa.md)에 컴포넌트 및 전체 화면 증거를 기록한다.

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
- 저장 / 공유 / 복사 버튼 노출

---

## API

### 일일 명언 조회 (비회원)

```
GET /api/v1/quotes/daily?quoteDate={quoteDate}
```

**Response: `DailyQuotaNoToken`**

### 일일 명언 조회 (회원)

```
GET /api/v2/member-quotes/daily?quoteDate={quoteDate}
```

**Response: `DailyQuoteDto`**

- v2 일일 명언 응답의 `date`를 `quoteDate`로 해석한다. 오래된 응답처럼 날짜 필드가 없을 때는 빈 기본값을 사용하며 화면의 선택 날짜는 Home state에서 별도로 관리한다.
- 선택 날짜가 주간 응답에 없을 때만 위 일간 조회를 보조 경로로 사용한다. 최초 회원 Home 조회는 `GET /api/v2/member-quotes/weekly`이며 `endDate`를 생략한다.

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

# 홈·캘린더: 오늘의 질문 답변 저장안됨

- QA: [Notion 원문](https://app.notion.com/p/3f2e639fc7a4803daac1dbe5a396f443) — 높음, Not started, Device 미지정
- 화면 계획: [Home](2_home.md), [Calendar](3_calendar.md)
- Figma: [Home 질문 흐름 `3110:33782`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/2.home?node-id=3110-33782), 저장 토스트 `3110:34293`; [Calendar 완료 Light `2987:22796`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796), Dark `3051:899`
- API 계약: [홈·캘린더 리뉴얼 가이드](https://app.notion.com/p/Fillsa-3d0e639fc7a480589e90d3245234ee3a) — `POST /api/v2/member-quotes/{dailyQuoteSeq}/answer`, weekly/daily/monthly 응답의 `answer`
- 판단 범위: 정적 코드 경로는 확인. 실제 제보 기기 재현, 운영 API 호출, 토스트의 현재 빌드 대 Figma 정렬 검증은 미실시.

## 증상

Home의 `내 답변 기록하기`는 성공 토스트를 띄우지만 앱 재실행 후 기록이 없다. Calendar의 같은 버튼은 반응하지 않는다. Home 토스트 정렬도 별도 지적되었다.

## 확인된 원인

1. `HomeFeature.answerRecordTapped`는 `answerDraft`를 메모리의 `recordedAnswer`로 복사하고 즉시 성공 토스트를 설정한 뒤 `.none`을 반환한다. 저장 요청이 전혀 없다 (`Fiilsa/Presentation/Home/HomeFeature.swift:297-306`). `HomeFeature.State`는 앱 시작과 일부 화면 전환에서 재생성된다 (`Fiilsa/App/AppFeature.swift:196-201,256-261`). 따라서 영구 기록은 남지 않는다.
2. Calendar 질문 카드의 `recordAnswer` 콜백은 빈 클로저이며, 입력도 로컬 `@State`뿐이다 (`Fiilsa/Presentation/Calendar/CalendarSelectedQuoteSection.swift:213-223`). `CalendarFeature.Action`에는 답변 저장 액션이 없다.
3. 서버는 2026-09-03부터 답변 API와 응답 필드를 제공하지만, Home은 v1 daily 모델을 사용하고 Calendar 월간 모델은 추가 답변 필드를 받지 않는다 (`Fiilsa/Data/API/APIEndpoint.swift:3-6`, `Fiilsa/Domain/Responses/CalendarResponses.swift:6-16`). Home 질문 문구도 고정 문자열이다 (`Fiilsa/Presentation/Home/HomeFigmaComponents.swift:401-412`). 과거 Home 계획의 “data contract 없음”은 현재 서버 가이드와 맞지 않는 **당시 구현 범위 기록**이다.
4. 토스트는 `HomeView.toast`에서 화면 하단 `Spacer`와 28pt padding으로 배치한다 (`Fiilsa/Presentation/Home/HomeView.swift:158-175`). 제보된 정렬 차이의 정확한 좌표 원인은 같은 크기·상태의 Figma/현재 런타임 캡처가 없어 미확정이다.

## 해결 방안

1. 회원용 v2 weekly/daily/monthly 응답 모델에 `dailyQuoteSeq`, 질문, 답변과 상태를 반영하고, answer 요청·응답을 Domain → Repository → APIClient에 추가한다. 기존 v1 비회원 경로 및 필사·메모 API는 분리한다.
2. Home의 기록·수정 액션을 TCA 비동기 effect로 연결한다. 서버 성공 응답을 받은 뒤에만 완료 상태와 Figma 토스트를 표시한다. 실패 시 입력을 유지하고, 표시 방식은 Figma에 정의된 상태 또는 사용자 결정으로 확정한다.
3. Calendar는 선택한 날짜의 월간 데이터로 질문·기존 답변을 채우고 같은 answer use case를 호출한다. 저장 후 Home/Calendar가 다시 같은 답변을 보도록 캐시 갱신 또는 무효화 경계를 `AppFeature`에 둔다. 답변 저장으로 필사 완료·연속 일수를 변경하지 않는다.
4. Home 토스트 `3110:34293`와 현재 빌드의 전체 화면 캡처를 같은 상태에서 비교한 후 정렬 차이만 수정한다. 기록 전·입력 중·성공·기록 후 상태를 각각 검증한다.

비회원 저장 정책과 서버의 200자 계산 단위는 현재 가이드에 확정되지 않았다. 구현 전에 각각 확인한다. 임의의 로그인 유도 UI나 오류 문구를 추가하지 않는다.

## 검증 기준

- 저장 성공 응답 전에는 성공 토스트가 없고, 재실행·날짜 재선택·Home↔Calendar 이동 후 동일 답변이 조회된다.
- 실패 응답에서는 성공 상태가 되지 않으며 입력 내용이 남는다. 200자/공백 입력/미래 날짜 서버 검증을 확인한다.
- Calendar 기록 버튼도 서버 요청을 보내고 저장·수정 결과를 월간 상세에 반영한다.
- 토스트 및 두 화면 질문 컴포넌트와 전체 화면을 대상 Figma와 비교해 QA 기록에 남긴다.

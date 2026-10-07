# 캘린더: 명언기능 미작동

- QA: [Notion 원문](https://app.notion.com/p/3f2e639fc7a480d8918bfb1aeb67f88c) — 높음, Not started, Device 미지정
- 화면 계획: [Calendar](3_calendar.md)
- Figma: [필사 완료 Light `2987:22796`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796), 완료 명언/액션 카드 `2987:22949`–`2987:22975`; [완료 Dark `3051:899`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3051-899), 카드 `3051:1049`–`3051:1074`
- 판단 범위: 수정 전 코드에서 작업 행의 입력 동작 부재를 확인하고, 수정 전 UI 테스트에서 네 버튼이 없는 상태를 재현했다. 제보 기기·라이브 서버에서의 재현은 미실시.

## 증상과 원인

필사 완료 날짜의 복사·공유·좋아요·이미지 등록이 작동하지 않는다. `CalendarSelectedQuoteSection`은 완료 상태에서 `CalendarUnavailableQuoteActionRow`를 표시한다 (`Fiilsa/Presentation/Calendar/CalendarSelectedQuoteSection.swift:95-98`). 이 행의 네 항목은 `HStack`과 `Text`/`Image`일 뿐 `Button`·콜백이 없다 (`:147-211`). `CalendarFeature.Action`에도 해당 액션이 없다 (`Fiilsa/Presentation/Calendar/CalendarFeature.swift:17-29`). 즉 비활성화 조건의 오류가 아니라, 현재 iOS 화면에 동작 자체가 연결되지 않았다. 같은 행의 소스 주석과 접근성 문구도 이를 명시한다.

Home에는 복사, 공유, 좋아요, 이미지 등록의 실제 연결이 있다 (`Fiilsa/Presentation/Home/HomeView.swift:62`, `Fiilsa/Presentation/Home/HomeFeature.swift:108-155,202-228`). Calendar의 월간 모델은 이미지 경로 등 확장 상세 필드를 아직 버리고 있으므로 같은 작업을 직접 처리할 데이터도 부족하다 (`Fiilsa/Domain/Responses/CalendarResponses.swift:6-16`).

## 해결 방안

1. 완료 카드 액션의 Figma 상태 및 누른 뒤 이동·팝업 상태를 대상 노드에서 확인한다. 디자인에 없는 Home 이동이나 새 팝업을 임의로 만들지 않는다.
2. 월간 응답의 추가 상세 필드(`imagePath`, 영문 문장/저자, URL 등)를 모델에 수용하고, 선택 날짜와 `dailyQuoteSeq`를 액션에 전달한다.
3. 표시 전용 행을 실제 버튼으로 연결한다. 복사는 선택 문장을 클립보드에, 좋아요는 기존 like use case에, 이미지 등록/보기는 기존 이미지 use case와 Figma 팝업에, 공유는 Figma의 공유 흐름에 연결한다. 기존 Home 기능을 공통 Domain 경계에서 재사용하고 화면 전용 상태는 Calendar reducer가 소유한다.
4. 서버 성공/실패 후 Calendar의 선택 날짜·월 집계·Home 표시가 일치하도록 필요한 조회 또는 상태 무효화를 연결한다.

## 구현 및 확인

- `CalendarQuoteActionRow`의 표시 전용 항목을 Figma의 네 버튼으로 교체했다. 복사는 선택 명언을 클립보드에 쓰고, 공유는 기존 공유 화면으로 전달한다.
- 좋아요와 이미지는 선택 날짜의 `dailyQuoteSeq`를 확인한 뒤 기존 Home use case를 호출한다. 요청 중 다른 날짜를 선택해도 완료 결과는 요청 당시 명언에만 반영한다. 좋아요/이미지 변경 뒤 월 데이터를 다시 읽는다.
- 이미지 버튼은 기존 `HomeImageDialog`를 재사용한다. 선택한 사진은 `HomeUploadImagePreparer`로 백그라운드에서 JPEG 준비 후 업로드하고, 임시 파일은 성공·실패·취소 후 삭제한다. 준비 실패는 Calendar 상태에 기록한다. Figma에 없는 오류 화면이나 문구는 추가하지 않았다.
- 단위 테스트는 선택 날짜 변경 중 좋아요·이미지 대상 유지, 응답 상세 필드 디코딩, 임시 파일 삭제, 이미지 준비 실패를 검증한다. UI 테스트는 네 버튼, 공유 화면, 기존 이미지 다이얼로그를 검증한다. 실제 서버 인증/업로드 왕복은 검증하지 않았다.
- Figma 비교와 런타임 캡처: [QA 기록](../design-qa/2026-10-07-calendar-actions-qa.md). Figma 완료 상태는 좋아요 표시 날짜에서도 액션 행에 윤곽 하트를 사용하므로 해당 아이콘을 유지했다.

## 검증 기준

- 완료 날짜에서 네 액션이 각각 실제 효과를 내고, 날짜를 바꿔도 다른 날짜의 명언을 변경하지 않는다.
- 좋아요·이미지 작업 후 재조회 결과와 월 집계가 일치한다. 미필사 카드의 기존 Home 이동은 유지된다.
- Light/Dark 액션 컴포넌트와 전체 Calendar 화면을 Figma 기준으로 검증한다.

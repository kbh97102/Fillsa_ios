# 캘린더: 명언기능 미작동

- QA: [Notion 원문](https://app.notion.com/p/3f2e639fc7a480d8918bfb1aeb67f88c) — 높음, Not started, Device 미지정
- 화면 계획: [Calendar](3_calendar.md)
- Figma: [필사 완료 Light `2987:22796`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2987-22796), 완료 명언/액션 카드 `2987:22949`–`2987:22975`; [완료 Dark `3051:899`](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3051-899), 카드 `3051:1049`–`3051:1074`
- 판단 범위: 캘린더 작업 행에 입력 동작이 없는 것은 코드로 확인. 제보 기기에서의 재현은 미실시.

## 증상과 원인

필사 완료 날짜의 복사·공유·좋아요·이미지 등록이 작동하지 않는다. `CalendarSelectedQuoteSection`은 완료 상태에서 `CalendarUnavailableQuoteActionRow`를 표시한다 (`Fiilsa/Presentation/Calendar/CalendarSelectedQuoteSection.swift:95-98`). 이 행의 네 항목은 `HStack`과 `Text`/`Image`일 뿐 `Button`·콜백이 없다 (`:147-211`). `CalendarFeature.Action`에도 해당 액션이 없다 (`Fiilsa/Presentation/Calendar/CalendarFeature.swift:17-29`). 즉 비활성화 조건의 오류가 아니라, 현재 iOS 화면에 동작 자체가 연결되지 않았다. 같은 행의 소스 주석과 접근성 문구도 이를 명시한다.

Home에는 복사, 공유, 좋아요, 이미지 등록의 실제 연결이 있다 (`Fiilsa/Presentation/Home/HomeView.swift:62`, `Fiilsa/Presentation/Home/HomeFeature.swift:108-155,202-228`). Calendar의 월간 모델은 이미지 경로 등 확장 상세 필드를 아직 버리고 있으므로 같은 작업을 직접 처리할 데이터도 부족하다 (`Fiilsa/Domain/Responses/CalendarResponses.swift:6-16`).

## 해결 방안

1. 완료 카드 액션의 Figma 상태 및 누른 뒤 이동·팝업 상태를 대상 노드에서 확인한다. 디자인에 없는 Home 이동이나 새 팝업을 임의로 만들지 않는다.
2. 월간 응답의 추가 상세 필드(`imagePath`, 영문 문장/저자, URL 등)를 모델에 수용하고, 선택 날짜와 `dailyQuoteSeq`를 액션에 전달한다.
3. 표시 전용 행을 실제 버튼으로 연결한다. 복사는 선택 문장을 클립보드에, 좋아요는 기존 like use case에, 이미지 등록/보기는 기존 이미지 use case와 Figma 팝업에, 공유는 Figma의 공유 흐름에 연결한다. 기존 Home 기능을 공통 Domain 경계에서 재사용하고 화면 전용 상태는 Calendar reducer가 소유한다.
4. 서버 성공/실패 후 Calendar의 선택 날짜·월 집계·Home 표시가 일치하도록 필요한 조회 또는 상태 무효화를 연결한다.

## 검증 기준

- 완료 날짜에서 네 액션이 각각 실제 효과를 내고, 날짜를 바꿔도 다른 날짜의 명언을 변경하지 않는다.
- 좋아요·이미지 작업 후 재조회 결과와 월 집계가 일치한다. 미필사 카드의 기존 Home 이동은 유지된다.
- Light/Dark 액션 컴포넌트와 전체 Calendar 화면을 Figma 기준으로 검증한다.

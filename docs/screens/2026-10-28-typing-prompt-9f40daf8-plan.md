# QA 1 · 필사 작성 화면 캐릭터 미적용 · 독립 설계 v1

## 선택·승인·범위

- Notion: [필사 작성 화면 > 캐릭터 미적용](https://www.notion.so/3ffe639fc7a480269f40daf8cf01f20c), page ID `3ffe639f-c7a4-8026-9f40-daf8cf01f20c`. 이슈 키 `typing-prompt-9f40daf8`.
- 선택: `1,2,3,4`. 재개 요청: “좋아 이제 그스킬을 토대로 다시 해보자”. 이는 독립 진행 요청이며 이 설계의 구현 승인은 아니다.
- 상태: **이슈1 구현 반영 / 본문 스크롤 반영·관련 회귀15건 통과 / 최종 UI 수용 보류**. 승인 발언: “1번으로 해봐”. 승인 범위: 이슈 1과 A 공통 글꼴 등록/회귀 검증. 후속 지시 “사이즈를 하드코딩하지말고 패딩으로 조절…compose개발하듯이”에 따라 B의 앱 레이아웃은 부모 공간·패딩·시스템 안전 영역을 사용하는 방식으로 확정했다. 사용자 작업이 있는 현재 checkout에서 이슈 1 변경만 적용한다.
- iOS 입력 화면의 안내 영역과 그 배치·글꼴을 수용 가능한 상태로 만드는 작업이다. 저장 팝업의 상태별 배경/결과 카드는 이슈 2, 온보딩은 3, 로그인은 4에서 별도 설계·승인·검증한다.
- [진행 색인](../design-qa/2026-10-28-selected-ios-qa-index.md), [이슈 1 QA](../design-qa/2026-10-28-typing-prompt-9f40daf8-qa.md), [기존 Home 기획](2_home.md), [Dark 기획](2_home_dark.md).

## 원본 요구와 확인 결과

원문 요구는 필사 입력 화면 위에 캐릭터와 **“오늘의 문장을 따라 써주세요.”**를 표시하는 것이다. 원문에는 최초 제보와 이후 iOS/Android 진행 기록이 함께 있다. 이번 범위는 iOS이며 Android 화면·자산·분석은 UI 판단에 사용하지 않는다.

- 원문 마지막 수정: 2026-10-25 04:25 UTC. 이번 재조회에서도 동일하다. 상태 In progress, 우선순위 낮음, 플랫폼 Android/iOS.
- [원문 전문](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/notion-source.md), [속성·조회 시각](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/source.json), [댓글 조회 기록](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments.json), [첨부 목록](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/attachments.json).
- 조회 가능한 페이지와 하위 42개 블록의 댓글은 0건. API에 노출되지 않는 해결된 댓글 등까지 없다고 단정하지 않는다.
- 원문에 2026-10-25 iOS 안내 추가 기록이 있다. 현재 코드·기존 실행 캡처에도 안내가 있다. **최초 누락은 현재 재현되지 않으며, 남은 작업은 시각 차이 보정과 재검증이다.**

재현 경로: QA Home fixture 실행 → 오늘 문장 카드 탭 → 필사 화면 진입 → 한글 키보드 표시 상태에서 캐릭터·안내·본문·저장 버튼 확인. 기존 `HomeUITests.testCopyAndTypingPrompt`가 이 경로를 실행했다. fixture는 실제 View에 고정 데이터를 넣는 방식이며 실서버 검증과는 구분한다.

## AS-IS와 원인 분석

- 코드 기준 HEAD `1b7335156ebe5b6a54a4002089a9dcfe993ef47c`는 이전 조사와 동일하다. 관련 앱 코드의 미커밋 변경은 없으며 [현재 파일 해시](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/code-baseline.json)를 기록했다. 사용자 문서·Xcode 상태·기존 테스트 작업은 보존한다.
- `TypingQuoteView`는 이미 60×60 캐릭터, 고정 24pt 안내 줄, 안내 다음 본문 20pt 간격을 가진다. `selectedLocale`과 기존 TCA 입력 상태로 언어별 본문을 연결한다.
- `FillsaTypography.subtitle1`은 Pretendard-Bold 16을 요청하지만 앱 폴더의 폰트 파일과 Info.plist의 `UIAppFonts`가 없다. 안내가 Figma의 Bold보다 가늘게 보이는 차이와 일치하는 원인이다. 실제 폰트 로드 확인은 구현 단계의 번들 검사로 확정한다.
- 상단은 44pt 버튼+위아래7pt로 58pt다. Figma의 50pt와 달라 안내의 상대 시작 위치도 달라진다. 본문은 20pt 서체를 지정하지만 Figma의 30pt 줄 높이 계약이 명시되지 않았다.
- [실제 수정 전 화면](../design-qa/assets/qa-selected-2026-10-28/prompt-attachments/typing-prompt-full-frame.png)은 이전 단계에서 확보한 동일 코드의 캡처다. 이번 재개에서 새 테스트·캡처를 실행한 것으로 표기하지 않는다. fixture 문장·입력 상태·키보드가 Figma와 달라 현재 캡처로 줄바꿈의 정확 일치를 판단하지 않는다.

## Figma 기준과 컴포넌트 설계

- 파일: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X
- 입력 Light [2929:17920](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=2929-17920), Dark [3087:28815](https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X?node-id=3087-28815).
- 기준 전체 이미지: [Light](../design-qa/assets/qa-selected-2026-10-28/figma-2929-17920.png), [Dark](../design-qa/assets/qa-selected-2026-10-28/figma-3087-28815.png). 같은 세션에서 Figma로 직접 확보한 360×720 원본을 재사용한다.
- 런타임 기준: iPhone 17e / iOS 26.4.1 / 390×844pt, 전체 PNG 1170×2532px. 기준 크기 차이는 아래 B의 결정 대상이다.

| 컴포넌트 | Figma 노드/영역 | TO-BE 책임·수치 | 상태·검증 |
|---|---|---|---|
| 캐릭터 | Light `3087:28737`, Dark `3087:28985` | 원본 이미지 60×60, 원본 비율 유지 | Light/Dark 원본 대응 검사 |
| 안내 문구 | Light `3087:28753`, Dark `3087:29001` | 원문 그대로, Pretendard Bold16/24, #5C65FF | 동일 문구·무게·줄 높이 |
| 안내 그룹 | Light `3087:28754`, Dark `3087:28984` | 캐릭터→문구, 그룹84높이, 중앙 정렬, 본문까지20 | 입력 상태, 키보드 열림/닫힘 |
| 상단·본문·하단 조립 | 전체 입력 프레임 하위 레이어 | 헤더50, 좌우20, 본문 Regular20/30; 원본 아이콘·액션 배치 대조 | 언어 전환, 입력·저장 접근 유지 |

안내·글꼴·부모 패딩·아이콘을 반영하고 실제 두 기기로 검증했다. 큰 글자·긴 문장에서는 본문 잘림이 남아 최종 통과가 아니다. 상세 차수·컴포넌트 결과는 이슈1 QA에 기록한다.

## 해결 설계

### 표시 흐름과 책임

현재: Home 카드 → 기존 TypingFeature → TypingQuoteView → 상단58 / 안내84 / 본문 / 하단 액션. 글꼴은 이름만 요청하고 번들 등록이 빠져 있다.

변경 후: 같은 진입·TCA 상태·입력 이벤트를 유지하면서 **등록된 Figma 서체 → 상단50 / 안내84 / 본문까지20 / 본문20·30 / 하단 액션**으로 배치한다. 기기 안전 영역은 B에서 승인한 기준을 따른다.

안내는 정적 표시다. 새 State·Action·Reducer나 API·Repository를 추가하지 않는다. 필요하면 같은 파일의 private View로 안내 그룹을 분리한다. 이는 Compose에서 정적인 안내 Composable을 추출하는 정도이며 독립 ViewModel을 만드는 작업이 아니다.

### 입력·실패·상태 계약

- 한/영 선택은 기존 `selectedLocale`을 사용한다. 안내 문구는 Figma에 정해진 한국어로 유지하고, 본문·작성 내용만 기존 언어 선택을 따른다.
- 입력은 기존 `korTypingChanged`/`engTypingChanged`에 전달한다. UITextView의 한글 조합(markedTextRange), 포커스, 커서를 보존한다.
- 저장 중 입력 차단, 저장 실패 시 작성 내용 유지, 뒤로가기 저장, 결과 팝업 표시는 기존 reducer 계약을 유지한다. 팝업 뒤 안내 숨김 변경은 2번 설계로 넘긴다.
- 작은 화면·긴 문장·큰 글씨에서 안내나 저장 버튼이 가려지면 기록한다. Figma에 없는 스크롤·축소·안내 생략 정책을 임의로 넣지 않는다.

### 대안과 선택 근거

권장안은 기존 안내를 유지하고 원본 서체·상대 배치를 보정하는 것이다. 안내 전체 재구현은 이미 해결된 누락을 중복 작업하고 입력 회귀 위험을 늘린다. 글꼴을 그대로 두고 간격만 맞추는 대안은 작지만 안내의 Bold 차이를 해결하지 못한다.

## 승인받을 A/B 결정

**A — 공통 글꼴 등록 포함(권장).** Pretendard Regular/Bold 원본과 라이선스를 번들에 등록한다. Android의 `res/font` 등록에 해당한다. 공통 작업의 담당은 이슈 1이며 이슈 2~4는 이후 등록 결과를 재사용한다. 실제 기존 Pretendard 호출 화면 전체를 목록화해 회귀를 확인한다. 다른 이슈의 고유 UI 수정까지 승인되는 것은 아니다. 추가 레이아웃 수정이 필요하면 영향과 범위를 별도 검토한다.

**B — 부모 공간·패딩 기반 기기 대응(사용자 후속 지시로 확정).** Figma의 앱 컴포넌트 크기·자산·글꼴·색·상대 간격은 유지하되 실제 기기 폭·높이·safe area·OS 상태 바·키보드를 따른다. 390pt 기기에서 좌우20pt이면 본문 폭350pt이며, Figma의 320pt 본문 폭을 늘여 캡처한 것으로 처리하지 않는다. 화면 전체 확대·왜곡, 가짜 상태 바·키보드는 사용하지 않는다. 보고서는 승인 예외를 명시하며 360×720 전체 픽셀 일치라고 표기하지 않는다.

A는 이슈 1에서 구현한다. B는 화면/본문의 고정 폭·고정 높이·절대 좌표를 쓰지 않고 패딩과 콘텐츠 고유 크기, Spacer로 배치한다. 운영체제 키보드·상태 바는 직접 그리지 않는다. 이 승인이 앱 소유 컴포넌트의 임의 변경이나 다른 이슈 완료를 허용하지는 않는다. 프레임 크기 차이와 검증하지 못한 상태는 최종 보고서에 별도로 남긴다.

## 파일별 구현 순서

1. 승인 발언·A/B 범위를 이 문서에 기록하고 원문·관련 소스 변화를 확인한다.
2. `Fiilsa/Resources/Fonts/`, `Fiilsa/Info.plist`, 필요한 Xcode 리소스 설정: 원본 폰트·라이선스를 등록한다. PostScript 이름을 확인하고 번들에서 두 폰트를 실제 로드하는 테스트를 추가한다. 공통 토큰 이름은 유지한다.
3. `TypingQuoteView.swift`: 기존 원본 캐릭터와 안내를 유지하고 안내/상단/본문 조립 수치를 맞춘다. 입력 화면 하단 아이콘이 원본과 다르면 해당 화면의 조립부에서 수정하고 공유 컴포넌트 영향은 기록한다.
4. `TypingQuoteBodySection.swift`: Figma 20/30 본문을 적용하되 입력 조합 처리에 영향을 주지 않게 한다. 의미 있는 입력 회귀를 검증한다.
5. `HomeUITests.swift` 및 필요한 번들 검사: Light/Dark 안내·언어 전환·키보드 상태와 전체 캡처를 보완한다. 기존 통과 테스트를 새 실패 테스트인 것처럼 취급하지 않는다.
6. 아래 기능·시각 검증 후 이 이슈 QA와 화면 기획을 갱신하고 개별 HTML을 만든다.

## 검증·완료 조건·복구

- 기존 근거: 이전 단계 45개 통과 중 이슈 1 관련 `HomeUITests.testCopyAndTypingPrompt`, `testDarkTypingSaveButtonUsesVisibleWhiteFill`와 `TypingFeatureTests` 8개를 재사용해 현황을 파악했다. 수정 후에는 반드시 재실행한다.
- 실행: `xcodebuild -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,id=6C263489-FBEE-4DC7-9904-55D99393D4EC' -derivedDataPath /tmp/FiilsaDerivedData -skipMacroValidation -parallel-testing-enabled NO -only-testing:FiilsaTests -only-testing:FiilsaUITests/HomeUITests -only-testing:FiilsaUITests/TypingResultUITests test`. 공통 폰트 영향에 따라 추가 시각 캡처 대상을 정한다.
- 수동/화면 검증: Light/Dark, 한·영 전환, 한글 조합/지우기, 키보드 열림/닫힘, 긴 문장, 저장 접근. 시각 fixture는 Figma와 같은 문장·작성 상태를 사용한다.
- 컴포넌트와 전체 입력 화면의 실제 캡처를 함께 대조한다. 최초 구현 후 비교부터 최대 5차. 원래 누락 미재현, 구현, 기능 결과, 시각 결과를 각각 기록한다. 다른 이슈의 결과 카드는 회귀 확인 대상이지 이번 이슈의 수정 완료 대상이 아니다.
- 폰트 전역 영향·입력 조합·하단 가림이 주요 위험이다. 이번 변경만 파일별로 되돌리고 기존 사용자 작업은 restore/reset하지 않는다.
- 최종 보고서 예정: `docs/design-qa/2026-10-28-typing-prompt-9f40daf8-report.html`. 상단에 원본 이슈·원인·해결방법·AS-IS→TO-BE 요약, 아래 원문·첨부·댓글(현재 조회 범위 0건)과 실제 비교/검증을 제공한다. 보고 직전에 원문·댓글을 다시 조회한다.
- 최종 시각 조건까지 만족해야 이슈 1을 완료로 기록한다. 보고서 작성만으로 완료 처리하지 않는다. Notion 게시/상태 변경은 별도 요청 없이는 수행하지 않는다.


## 구현 후 경계 조건 검토 · 2026-10-28

- 반영: 공통 Pretendard 등록, 안내 고유 크기·줄 높이 기준 패딩, 화면/본문의 부모 공간 채움, 좌우20pt, Spacer, 원본 액션 아이콘. TCA·API·입력 조합 계약 유지.
- 기본 글자 크기의 iPhone17e(390×844)와 SE3(375×667)에서 Light/Dark·한/영·긴 문장·키보드 위 저장 접근 확인.
- SE3에서 글자 크기 extra-extra-extra-large + 긴 문장을 쓰면 본문 끝이 `…`로 잘린다. [실제 캡처](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/large-text/typing-layout-light-long.png).
- 추가 설계안: (권장) 안내/하단 액션은 유지하고 본문만 세로 ScrollView에 배치한다. Compose의 본문 Column에 verticalScroll을 붙이는 개념이다. 본문 자체는 전체 높이를 측정하고 부모가 제공한 영역 안에서 이동하므로 화면 고정 높이는 불필요하다. 대안은 안내와 본문을 함께 스크롤해 더 넓은 본문 영역을 확보하는 방식이다. 안내가 화면 밖으로 이동하는 차이가 있다.
- 입력/저장/언어 전환 상태는 그대로 유지한다. 새 API나 reducer 이벤트는 필요하지 않다. 선택 후 기본/큰 글자·긴 문장·한/영·키보드·끝 문장 접근을 재검증하고 시각2차를 기록한다.
- **후속 승인: “본문만 스크롤하도록 허용”.** 안내와 하단 액션을 유지하고 본문만 스크롤하는 안으로 구현·재검증했다. 이 승인으로 Figma에 없는 해당 스크롤 동작이 허용되었다.
- [HTML 보고서](../design-qa/2026-10-28-typing-prompt-9f40daf8-report.html)에 원본 이슈 전문·첨부·댓글 조회 결과·원인·현재 수정·실제 AS-IS/TO-BE 및 미해결 상태를 기록했다.

- 본문 스크롤 구현 후 SE3 기본/큰 글자 검사가 통과했고, 실제 캡처에서 마지막 문장까지 접근함을 확인했다. 안내·저장 위치와 키보드는 유지됐다. 이번 경계 조건은 해결했으며 상세2차 결과는 QA에 연결한다.

- 최종 관련 회귀13건 + SE3 기본/큰 글자 각1건 =15건 통과. 공통 폰트 화면 회귀8건/100화면 확인. 기존 홈 툴팁 실패와 토글·커서 시각 차이는 남아 전체 UI 수용과 구분한다.


## 후속 계획

- Notion 페이지에 2026-10-29 댓글이 추가됐다. [후속 조사·수정 계획 v2](2026-10-29-typing-prompt-9f40daf8-plan-v2.md)는 최신 로컬 코드와 댓글 첨부를 대조한다. 기능 재현과 필요한 수정은 v2 계획 승인 후 진행한다.

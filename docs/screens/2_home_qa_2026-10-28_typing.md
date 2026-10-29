# 필사 안내·저장 결과 QA 1·2 상세 계획 · v1

> 이전 통합 조사 문서. 1번의 현재 설계는 [독립 계획](2026-10-28-typing-prompt-9f40daf8-plan.md)으로 분리했다. 2번은 별도 설계·승인 예정이며 이 문서로 두 이슈를 묶어 승인하지 않는다.

- 상태: 계획 검토 대기. 이번 선택 `1,2,3,4`는 구현 승인이 아니다.
- 상위 계획·공통 결정: [선택 QA 계획](../design-qa/2026-10-28-selected-ios-qa-plan.md).
- 기존 정책: [Home 기획](2_home.md#사용자-확정-정책--2026-10-25-위-미확정-표보다-우선), [Dark 기획](2_home_dark.md).
- QA 1: [캐릭터 누락](https://www.notion.so/3ffe639fc7a480269f40daf8cf01f20c). QA 2: [저장 결과 팝업](https://www.notion.so/3ffe639fc7a48056b876d1ab3e28f520).

## Figma UI 기준

- URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X
- 입력 전체 Light `2929:17920`, Dark `3087:28815`.
- 결과 전체 Light `2988:23906`, `2988:23962`, `2988:24015`; Dark `2929:9801`, `2929:9844`, `2929:9884`.
- 원본은 각 360×720. 전체 기준 이미지: `../design-qa/assets/qa-selected-2026-10-28/figma-<node-id-with-hyphen>.png`. [입력 기준](../design-qa/assets/qa-selected-2026-10-28/figma-2929-17920.png), [팝업 기준](../design-qa/assets/qa-selected-2026-10-28/figma-2988-23906.png).
- QA 기록: [선택 QA](../design-qa/2026-10-28-selected-ios-qa.md). 전체 시각 판정 미통과.

| 컴포넌트 | Figma 범위 | 책임·상태 | 조립 위치 / 결과 |
|---|---|---|---|
| 캐릭터·안내 | Light `3087:28754`, Dark `3087:28984` | 60×60 캐릭터, Bold 16/24 안내, Light/Dark | TypingQuoteView / 표시 확인, 서체 불일치 |
| 입력 본문·상단·액션 | `2929:17920`, `3087:28815` 하위 레이어 | 언어, 입력, 키보드, 저장, 뒤로가기 | TypingQuoteView/BodySection / 상세 시각 재검증 필요 |
| 결과 카드 | Light `3039:28654` 및 3 결과 프레임, Dark 대응 프레임 | 320폭, 120캐릭터, 제목20/30, 버튼49, radius8 | TypingResultPopup / 기능 통과, 서체·배경 불일치 |
| dim과 배경 입력 화면 | Light `2988:23933`와 각 전체 결과 프레임 | #212121 80%, 입력 안내 없는 배경, 키보드 없음 | TypingQuoteView overlay / 안내 영역이 남아 있음 |

## AS-IS와 원인

1. `TypingQuoteView.swift`에 60pt 캐릭터·안내문·본문까지 이미 구현돼 있다. 실제 [수정 전 입력 화면](../design-qa/assets/qa-selected-2026-10-28/prompt-attachments/typing-prompt-full-frame.png)에도 표시된다. 신규 누락을 재현하지 못했다. 서체 미등록, 본문 30pt 줄 높이 미지정, 상단 헤더 58pt와 Figma 50pt 차이를 확인했다. OS 키보드/화면 크기 차이는 별도다.
2. `TypingFeature.State.saveResult`와 `.saveTapped`, `.typingSaved`, `.resultConfirmed`, `.resultCancelled`가 존재한다. 네 결과와 확인·취소 동작은 이번 테스트에서 통과했다. [수정 전 팝업](../design-qa/assets/qa-selected-2026-10-28/baseline-attachments/typing-encouragement-light-full-frame.png)은 뒤쪽에 안내 그룹을 유지한다. Figma 결과 프레임은 안내가 없고 본문이 y=100에서 시작한다. 입력 프레임의 안내 이후 본문과는 별도 상태다.
3. 카드 그림자는 코드 radius 7.1이고 Figma 효과는 blur 12.2/spread 2다. 두 엔진의 숫자를 단순 대입하지 않고 컴포넌트 렌더로 대조한다. 색·굵기·카드 위치는 동일 상태에서 측정한다.
4. 저장 후 월간 기록에서 해당 문장을 찾지 못하면 현재 코드는 `completed=false`로 해석한다. 실서버 계약상 누락 가능성은 확인되지 않았다. 이는 조사할 가설이며 이번에 버그로 확정하지 않는다. 저장 성공 후 조회 실패 시 팝업 없이 입력을 유지하는 경로는 현재 테스트로 확인했다.

## 해결안과 변경 순서

**권장:** 기존 입력·저장 상태를 유지한 채 표시 구조를 보정한다. 입력 전체 재작성은 한글 조합·커서·저장 회귀 위험이 커서 제외한다. 카드만 수정하는 대안은 뒤 배경 차이가 남으므로 최종 수용 조건을 만족하지 않는다.

- [ ] 공통 글꼴 승인 후 적용 결과부터 확인한다. 정적 안내 그룹을 작은 `TypingPromptSection`으로 분리하는 경우 같은 파일의 private View로 충분하다. 공개 API나 새 feature는 만들지 않는다.
- [ ] `TypingQuoteView.swift`: 입력 상태에서는 안내 60×60 + 24pt 문구, 본문까지 20pt 간격. 결과 표시 상태에서는 Figma 결과 프레임처럼 안내 영역을 제거하고 본문 시작 여백을 적용한다. 별도 Boolean을 중복 저장하지 않고 `saveResult != nil`에서 도출한다.
- [ ] `TypingQuoteBodySection.swift`: 실제 Pretendard와 20/30 본문을 맞춘다. UITextView의 markedTextRange/한글 조합, 입력색/커서, 기존 isInputEnabled 계약을 보존한다.
- [ ] 상단 Figma 화살표·언어 토글과 하단 24pt 원본 아이콘/간격을 확인하고 선택 화면에만 적용한다. 공유 HomeInteractionButtonSection을 바꾸면 영향 화면을 별도로 기록한다. 상단 50pt, 좌우20pt는 Figma 기준이며 safe area는 상위 계획 B에 따른다.
- [ ] `TypingResultPopup.swift`: 기존 원본 캐릭터·320pt 카드·120pt 이미지·49pt 버튼을 유지하며 제목/버튼 서체, Light 그림자, Dark 테두리를 실제 렌더로 맞춘다. 일반 완료 제목 치환은 2026-10-25 승인 예외를 유지한다.
- [ ] `TypingFeature.swift`, `TypingClient.swift`, `DefaultTypingRepository.swift`: 현재 기능 재검증을 우선한다. 실서버 상태 누락/응답 지연을 실제로 확인하면 실패 재현 테스트와 근거를 계획에 추가하고 필요한 경계만 수정한다. `completedChanged`를 현재 완료 상태로 해석하는 변경은 하지 않는다.

## 유지할 동작과 검증

| 입력 조건 | 기대 결과 |
|---|---|
| 오늘 문장 완료, 첫날 포함 | 연속 필사 완료! |
| 과거 문장 완료 + 오늘 완료 | 필사 완료! (승인된 리뉴얼 카드 재사용) |
| 과거 문장 완료 + 오늘 미완료 | 오늘도 이어서 필사를 해주세요! |
| 선택 문장 미완료 | 필사가 완료되지 않았어요. |
| 완료 문장 재저장, 변경 플래그 false | 현재 완료 상태에 따른 결과 재표시 |
| 완료/안내 확인 | Home 이동 |
| 미완료 취소·필사하기 | 팝업 닫고 입력 유지 |
| 뒤로가기 | 저장 후 복귀, 결과 팝업 없음 |
| 저장·후속 조회 실패 | 입력 보존, 성공 팝업 없음 |

- 기존 `TypingFeatureTests` 8개와 `TypingResultUITests` Light/Dark 테스트를 유지한다. 중복 저장·실패·늦은 응답도 포함한다.
- 승인 후 UI 검사에 `testResultBackgroundMatchesFigmaState`를 추가: 입력 중 안내가 있고, 저장 결과 중에는 안내가 없으며, 미완료 닫기 후 안내·작성 내용이 복원됨을 확인한다. 이 테스트는 현재 배경 상태에서 실패해야 한다.
- `HomeUITests.testCopyAndTypingPrompt`, `testDarkTypingSaveButtonUsesVisibleWhiteFill`로 안내·저장 접근을 재확인한다. 한국어 조합/지우기, 한·영 전환, 긴 문장과 키보드 노출을 직접 캡처한다. 입력 fixture 문장은 시각 비교 시 Figma 문장으로 맞추되 앱 동작용 일반 데이터를 바꾸지 않는다.
- POST v2 → 월간 현재 완료 → 필요 시 streak 조회 순서를 실제 테스트 계정에서 확인한다. 서버 요청 실패·누락·중복 요청은 로그에서 민감값을 제거한다. 계정 없으면 이 부분은 미검증으로 남긴다.
- 최종: 안내 컴포넌트, 본문/액션, 팝업 카드, Light/Dark 각 4종 결과와 조립 화면을 같은 라운드에서 검증한다. 시각 최대 5차, 승인된 예외 밖의 차이는 Pass 불가.

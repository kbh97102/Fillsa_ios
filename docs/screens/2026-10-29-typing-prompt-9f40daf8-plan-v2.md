# QA 1 · 댓글 후속 조사와 수정 계획 v2

## 선택 이슈 및 진행 상태

- Notion: [필사 작성 화면 > 캐릭터 미적용](https://www.notion.so/3ffe639fc7a480269f40daf8cf01f20c), page ID `3ffe639f-c7a4-8026-9f40-daf8cf01f20c`.
- 이전 승인 및 구현: [계획 v1](2026-10-28-typing-prompt-9f40daf8-plan.md), [기존 QA](../design-qa/2026-10-28-typing-prompt-9f40daf8-qa.md), [기존 보고서](../design-qa/2026-10-28-typing-prompt-9f40daf8-report.html).
- 새로운 댓글을 반영한 계획 버전: **v2**. 상태: 로컬 작업본 재현·검증 완료 / 제보자가 확인한 배포 빌드 식별 대기. 승인 발언: “좋아 진행하자”. 승인 범위는 아래 v2 권장 조치와 승인 범위 제안에 한정한다.
- 페이지 마지막 수정: 2026-10-29 06:32 UTC. 댓글 2026-10-29T06:43:00.000Z. 보고 전 페이지와 댓글 다시 확인: 2026-10-29T09:53:16.601Z UTC.
- 페이지 댓글 1건, 중첩42개 블록 댓글 0건, 조회 실패0건. API에서 노출되지 않는 해결된 댓글은 확인 범위 밖. [댓글 원본과 첨부](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments-2026-10-29/comments.json).
- 댓글 작성자 SooJi가 `@보훈 강`을 태그했다. 원문: “@보훈 강 보훈님, 캐릭터 이제 잘 나옵니당. 다만, 아래의 내용들이 적용되어 있지 않아 확인 부탁드립니다!

  1. iOS에서 ‘오늘의 문장을 따라 써주세요.’ 텍스트 부분 bold 로 수정이 필요합니당(현재 폰트 regular 적용되어 있음)

  2. iOS에서 필사 작성 화면 > 복사하기 버튼이 작동하지 않으며, 복사하기 버튼에 노란 컬가 들어간 부분이 있어서 디자인과 같이 수정 부탁드립니다.”
- 첨부는 [원본 HEIC](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments-2026-10-29/comment-408e639f-original.heic)와 [열람용 PNG 변환](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments-2026-10-29/comment-408e639f-preview.png)으로 보존했다. 사용자 첨부 이미지는 디자인 판단의 근거로 읽되 Android와 비교하지 않았다.

## 댓글에서 추가된 항목

| 항목 | 댓글의 증상 | 현재 iOS 작업본에서 확인한 사실 | 판단 |
|---|---|---|---|
| 안내 굵기 | Regular로 보여 Bold가 필요 | `TypingPromptSection`이 `FillsaTypography.subtitle1`을 사용. 해당 토큰은 `Pretendard-Bold` 16pt이며 `Info.plist`가 Regular/Bold 폰트를 등록함. 10/28 전체 화면 캡처에서는 굵게 보임. | 코드 수정은 이미 포함. 제보자는 이전 화면을 봤을 가능성이 있으나 앱/커밋 동일성은 확인되지 않아 추정으로만 기록. |
| 복사 아이콘 | 노란색 부분 제거 | 현재 `typing_copy-light.svg`는 검은 선으로 된 Figma 원본 19.2pt이며 노란색 채움 없음. 댓글 첨부는 겹친 종이 안쪽이 노란색으로 보이나, 10/28 현재 작업본 화면의 아이콘에는 노란 채움이 없음. | 현재 작업본 시각 수정은 이미 포함. 제보 화면과 작업본이 다른 빌드인지 확인 필요. |
| 복사 동작 | 눌러도 작동하지 않음 | 버튼 action에서 `UIPasteboard.general.string = “선택된 문장\\n저자”`를 실행함. 다만 Typing 화면에서 버튼 탭 후 pasteboard 값을 확인하는 테스트는 없음. | 구현은 있으나 기능 동작은 검증되지 않음. 실패 원인을 확정하지 않음. |

### 재현·수정 전 흐름

필사 화면의 복사 버튼 → iOS 일반 클립보드에 현재 선택 언어의 문장, 줄바꿈, 저자를 기록한다. 화면은 완료 안내를 표시하지 않는다. 버튼이 기록하는지 기존 테스트나 실제 붙여넣기로 확인하지 않아, “작동하지 않음”이 코드 결함인지 제보자가 받은 빌드 문제인지 판별되지 않았다.

댓글 첨부 화면은 2026-10-29에 올라왔고, 10/28 로컬 작업본의 화면과 비교하면 안내 무게·언어 토글 색상·복사 아이콘 색이 다르다. 관련 소스 변경은 현재 로컬 git 작업본에 미커밋/미추적 상태가 있다. 따라서 댓글 이미지가 최신 로컬 소스를 포함한 빌드인지 확인되지 않았다. 이미지 차이만으로 현재 코드가 잘못됐다고 단정하지 않는다.

## Figma 기준

- 파일: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X
- Light 입력 전체 프레임 `2929:17920`; Dark `3087:28815`.
- 안내 문구: Light/Dark 대응 노드 `3087:28753`, `3087:29001`; Pretendard Bold16 / line-height24 / #5C65FF.
- 복사 아이콘: `3087:28758` 내부 `3087:28759`, 복사 SVG 원래 19.2×19.2pt를24pt hit area 중앙에 배치. Figma copy source asset: [Light](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/asset-verification.json).
- [Figma Light](../design-qa/assets/qa-selected-2026-10-28/figma-2929-17920.png), [Figma Dark](../design-qa/assets/qa-selected-2026-10-28/figma-3087-28815.png).

## 권장 조치 (승인 전 계획)

1. 먼저 QA에서 확인할 앱 빌드/커밋을 기록한다. 이슈1의 10/28 로컬 수정은 작업본에 남아 있다. 그 수정이 포함된 화면에서 안내 굵기와 복사 아이콘 색을 확인한다. 동일 빌드가 아니라면 최신 이슈1 작업본을 빌드해 같은 기기/화면 크기에서 다시 확인한다.
2. 실제 필사 화면에서 복사 버튼을 누르고 다른 입력란에 붙여넣어 `선택 언어 문장 + 줄바꿈 + 저자`가 들어오는지 확인한다. 실패하면 화면 전환, 포커스, locale, 버튼 hit area 순서로 원인을 분리한다. 현재 static code에 이미 클립보드 기록이 있으므로 검증 전에 같은 기능을 중복 구현하지 않는다.
3. 승인 후, 회귀를 막기 위해 버튼 액션을 호출하는 UI 검사에서 클립보드 예상 문자열을 확인한다. 현재 Typing 화면에는 복사 전용 accessibility identifier와 copy-completion action/toast가 없다. 검사가 필요한 최소 표시 ID를 추가하고, 통과 피드백은 Figma에 정의되지 않았으므로 별도 요구 없이 새 toast를 만들지 않는다.
4. 실제 빌드에서 색/무게 문제가 재현되면 수정한다. 아이콘에는 이미 Figma SVG가 적용되어 있다. 폰트도 Bold 토큰과 파일 등록이 있어 누락 원인이 아니므로, 런타임에서 등록된 폰트/asset variant 선택을 확인한 뒤 원인에 맞춰 고친다.
5. 같은 fixture 문장·locale·기기 크기에서 UI 캡처, 클립보드 동작, Light/Dark 색상을 검증하고 Notion 댓글 첨부와 Figma 원본을 함께 대조한다. 검증 후 이 HTML 보고서와 QA 기록을 갱신한다. Notion 상태/댓글은 별도 요청 없이 수정하지 않는다.

## 승인 후 실행 결과 · 2026-10-29

- 승인 시점: 2026-10-29. 발언 “좋아 진행하자”. 승인 범위: 현 작업본에서 두 시각 항목과 복사 동작을 재현하고, 원인 확인 시 최소 수정/회귀 검사를 진행한다. 새 토스트·팝업·클립보드 정책은 제외.
- 실행 기준: HEAD `1b7335156ebe5b6a54a4002089a9dcfe993ef47c` + v1에서 남아 있던 로컬 수정. 앱의 공유 파일 변경 여부는 별도 기록과 구분한다. iPhone 17e Simulator / iOS 26.4.1 / 한국어 / Light·Dark.
- 안내 문구: 현재 런타임 캡처에서 Bold로 표시. Pretendard-Bold 등록 단위 검사도 통과. Figma의 `3087:28753`/`3087:29001`는 Bold16/24 기준이다.
- 아이콘: Figma 전체 프레임과 `3087:28758` 단독 노드 캡처는 노란 채움 없이 단색 윤곽이다. 로컬 `typing_copy-light.svg` SHA-256은 `d895ad311b5f46d21ff42bebac81d765264e7aa5da7fc1f3f9c7c300cf38fc41`로 Figma 임시 원본 다운로드와 일치한다. 현재 앱 캡처도 단색이며 Figma와 일치한다. 댓글 첨부의 노란 채움과는 다르지만 제보자가 사용한 빌드/리비전은 확인되지 않아 배포본 원인을 확정하지 않는다.
- 복사: iOS Simulator UI 테스트가 필사 화면의 복사 버튼을 누른 후, `simctl pbpaste`가 fixture의 `한국어 문장 + 줄바꿈 + 존우든`을 반환했다. 반복 가능한 실행 스크립트는 [`scripts/test-typing-copy.sh`](../scripts/test-typing-copy.sh)다. XCUITest 프로세스에서 클립보드를 직접 읽으면 iOS의 앱 간 붙여넣기 권한 확인이 발생해 읽기 검사가 대기했다. 앱을 수정하지 않고 Simulator CLI로 검증했다.
- 관련 회귀: `TypingLayoutUITests.testPromptAndSaveRemainAccessibleWithKeyboard` 1건(테스트 안에서 Light/Dark, 한/영, 기본/긴 문장 및 본문 스크롤 상태 확인) 통과; `TypographyResourceTests` 2건 통과. 모두 iPhone17e/iOS26.4.1, 0 실패/0 skip.
- UI evidence: [복사 버튼 실행 전체 캡처](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments-2026-10-29/current-run/typing-copy-button-tapped-full-frame.png), [현재 Light](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments-2026-10-29/current-run/typing-layout-light-normal.png), [현재 Dark](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments-2026-10-29/current-run/typing-layout-dark-normal.png), [Figma 복사 노드](../design-qa/assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments-2026-10-29/current-run/figma-copy-node.png).
- 결론: 현재 로컬 작업본에서는 세 증상 중 어느 것도 재현되지 않아 앱 UI/복사 동작의 추가 production 수정은 하지 않았다. 필요한 테스트와 실행 스크립트만 추가했다. 댓글 첨부와 현재 작업본이 다른 빌드처럼 보이지만 이를 확인할 QA 설치본의 버전/커밋이 없다. 따라서 이슈를 Notion에서 완료 처리하지 않으며, QA 확인 앱의 빌드/커밋을 식별해야 최종 해결 여부를 판정할 수 있다. 전체 화면 픽셀 비교는 Figma 360×720과 실제 17e 390×844의 프레임 차이로 수용 완료 처리하지 않는다. HTML의 정적 링크·토큰 검사는 통과했으나 현재 환경에서 사용 가능한 브라우저가 없어 넓은/좁은 화면 브라우저 미리보기는 수행하지 못했다.

### 승인 범위 제안

- 포함: 댓글 두 표시 항목의 최신 작업본 확인, 복사 액션 실제 재현, 필요한 최소 회귀 검사와 원인 발견 시 수정.
- 보류: 새로운 toast/팝업, pasteboard 동작을 바꾸는 정책, 공용 화면 수정.
- 2026-10-29 사용자가 v2 계획에 “좋아 진행하자”고 승인했다. 새 댓글의 실패 증상을 UI 테스트와 현재 시뮬레이터에서 재현하고, 실제 원인이 확인될 때만 같은 iOS 이슈1 범위에서 수정한다. 새 toast/팝업이나 pasteboard 정책 변경은 범위에 포함하지 않는다.


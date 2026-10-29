# QA 1 · 필사 안내 · 독립 검증 기록

- 상태: **구현 반영 / 최종 UI 수용 보류**. [독립 계획](../screens/2026-10-28-typing-prompt-9f40daf8-plan.md), [HTML 보고서](2026-10-28-typing-prompt-9f40daf8-report.html).
- 승인: “1번으로 해봐” → 이슈1 및 공통 Pretendard 등록. “사이즈를 하드코딩하지말고 패딩으로…” → 부모 공간·패딩·기기 안전 영역 방식.
- Notion ID `3ffe639f-c7a4-8026-9f40-daf8cf01f20c`. 보고 전 본문과 페이지/하위42블록 댓글 재조회, 원본 수정 시각 동일, 댓글0·실패0. [원문 기록](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/source.json), [댓글 범위](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments.json).

## Reference

- Figma URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X
- 전체 프레임 Light `2929:17920`, Dark `3087:28815`; 안내 `3087:28754`, `3087:28984`.
- 전체 기준: [Light](assets/qa-selected-2026-10-28/figma-2929-17920.png), [Dark](assets/qa-selected-2026-10-28/figma-3087-28815.png), 각360×720.
- Runtime: iPhone17e / iOS26.4.1 / 390×844pt(1170×2532px), iPhoneSE3 / iOS26.4.1 / 375×667pt(750×1334px).
- 전체 화면 경계 유지, 잘라내기 없음. [HTML에서 원본 나란히 비교](2026-10-28-typing-prompt-9f40daf8-report.html#issue-comparison), [기기별 축소 모음](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/device-comparison.png).
- 실제 기기 폭·키보드·safe area를 따르는 방식은 사용자 후속 지시로 승인됨. 서로 다른 크기를 전체 픽셀 일치라고 판정하지 않는다. Figma의 문장·부분 입력 상태와 fixture의 문장·빈 입력 상태는 다르다.
- AS-IS: 수정 전 동일 HEAD `1b7335156ebe5b6a54a4002089a9dcfe993ef47c`의 [입력 전체 캡처](assets/qa-selected-2026-10-28/prompt-attachments/typing-prompt-full-frame.png). 같은 HomeUITests.testCopyAndTypingPrompt의 [수정 후 캡처](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/round1/typing-prompt-full-frame.png)와 비교한다.

## Component inventory

| 컴포넌트 | Figma | 검증 결과 |
|---|---|---|
| 캐릭터·안내 | `3087:28754/28984` | 원본 SVG 해시 일치, 자연60pt, Bold16/24 기준 패딩, #5C65FF. Light/Dark 실제 표시 확인 |
| 헤더·부모 | 전체 입력 프레임 | 화면 고정 폭·높이 없음, 원본 뒤로가기32+패딩으로 헤더50, 좌우20. 기존 언어 토글의 크기 차이는 남음 |
| 본문 | `2929:17923` 및 Dark 대응 | Regular20/30 기준 여백, 기본/긴 문장·한/영 전환. 2차: 큰 글자+긴 문장을 본문 스크롤로 끝까지 접근 확인 |
| 하단 액션 | 입력 프레임 하단 | 원본 복사/공유/빈 하트, 텍스트+패딩 저장, 상하6. 기본·큰 글자에서 키보드 위 저장 접근 확인 |
| 공통 폰트 | [48파일 목록](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/font-impact-inventory.json) | 실제 Regular/Bold 로드 확인. 광범위 기존 화면 캡처 회귀는 HTML의 실행 결과 참조 |

## Validation rounds

### Round 1

1. 등록 전 UIFont Regular/Bold 로드2건 실패, 등록 후2건 통과. [실패 로그](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/font-red.log), [통과 요약](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/components-summary.json).
2. 안내·본문을 Figma 문장/입력으로320/350pt Light/Dark 렌더. Dark 캐릭터의 원본 렌더링을 명시한 후 실제 전체 화면에서 얼굴·연필이 보이는 것을 재확인. ImageRenderer의1px 입력뷰 표시는 전체 런타임 증거와 구분한다.
3. 헤더/본문/액션을 조립한390pt Light/Dark 및375pt 기본/긴 문장/영어 화면 비교. 루트 white/#212121, 원본 아이콘, 안내 중앙 정렬, 글꼴을 확인. 시스템 status bar와 키보드는 기기 OS에 따른다. [원본 캡처/촬영 시각](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/round1/manifest.json), [작은 기기](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/compact/manifest.json).
4. 375pt에서 extra-extra-extra-large 글자 설정: 안내와 저장 접근 검사는 통과했으나 긴 문장 끝에 말줄임이 나타남. [실제 경계 조건](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/large-text/typing-layout-light-long.png). 화면 접근 검사 통과가 본문 가독성 통과를 뜻하지 않는다.

| 범위 | 남은 차이 | 처리 |
|---|---|---|
| 큰 글자·긴 문장 | 본문 끝 잘림 | 1차에서 사용자 판단 요청 → “본문만 스크롤하도록 허용” 승인 → 2차에서 반영 |
| 공용 언어 토글 | 기존 자연 크기가 Figma70×36보다 작음 | 미수정, 전체 시각 수용에 남은 차이로 기록 |
| 동일 문장·입력 | 커서가 문자 폭을 차지해 줄바꿈 차이 | 기존 입력 계약 유지, 전체 런타임 동일 데이터 정합 미완료 |

최초 비교를1차로 기록했다. 5차 소진이나 전체 Pass로 표기하지 않는다. 이후 본문 스크롤 추가 승인을 받아2차를 진행했다.

### Round 2 · 승인된 본문 스크롤

- 후속 승인: **“본문만 스크롤하도록 허용”**. 안내와 하단 액션은 스크롤 바깥에 유지하고, 본문만 남는 영역을 채우는 ScrollView로 배치한다. 화면 높이·본문 높이 숫자 하드코딩 없이 내용 전체를 측정한다.
- 스크롤이 없던 빌드에서 새 UI 검사 실패를 확인한 뒤 적용했다. [실패 요약](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/scroll-red-summary.json).
- 375×667pt 기본 크기와 extra-extra-extra-large에서 Light/Dark, 기본/긴 문장, 한/영 전환 검사를 각각 통과했다. 스크롤 전후 안내/저장 버튼의 Y 위치 유지와 긴 본문 이동을 검사했다.
- [큰 글자·본문 시작](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/scroll-large/typing-layout-light-long.png) → [본문 끝](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/scroll-large/typing-layout-light-long-scrolled.png): 마지막 “다시 시작된다.”까지 실제 화면에서 확인. 안내와 저장 위치, 키보드는 유지됐다. Dark도 같은 경계 조건을 확인했다.
- 전체 화면 경계·루트 배경·OS status bar/키보드를 포함한 원본 캡처이며 잘라내거나 재구성하지 않았다. Figma와의 배치·자산·글꼴 비교는1차와 동일 기준을 사용하고, 스크롤은 사용자 승인 예외로 기록한다.
- 남은 기존 차이: 공용 언어 토글 크기, 커서 폭에 따른 동일 문장 줄바꿈. 전체 화면 최종 정합은 아직 Pass가 아니다.

## Functional validation

- **최종 스크롤 반영 후** iPhone17e 관련 회귀13건, SE3 기본1건, SE3 큰 글자1건 모두 통과(총15회 실행, 실패/skip0). [최종13건](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/round2-summary.json), [SE3 기본](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/scroll-compact-summary.json), [SE3 큰 글자](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/scroll-large-summary.json).
- 아래168건은 스크롤 추가 전1차 공통 회귀이며, 기존 툴팁 실패가 포함되어 있다. 최신13건에 그 실패 검사를 재포함하지 않았으므로 전체 회귀 실패가 해결됐다는 의미가 아니다.


- iPhone17e 단위 전체 + Home + 저장 결과 + 전역 로딩 + 기기 배치: **167통과/1실패**, 총168. [실행 요약](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/round1-summary.json).
- 작은 기기 배치1건(여러 상태 반복): 통과. [요약](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/compact-summary.json).
- 같은 기기 큰 글자 배치1건: 통과, 단 본문 말줄임은 위 시각 검증에서 별도 Fail. [요약](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/large-text-summary.json).
- 실패: HomeUITests.testStreakTooltipArrowIsAnchoredToStatusButton. 글꼴 등록을 제거한 복사 빌드와 정상 빌드를 같은 SE 기기에서 비교해 둘 다55 vs63.5로 동일 실패. 등록 OFF에서 UIFont nil도 별도 확인. 이번 폰트 등록만으로 발생한 회귀가 아니다. [OFF](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/tooltip-control-summary.json), [ON](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/tooltip-registered-summary.json), [폰트 OFF 확인](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/font-control-summary.json).
- 로그의 인증/token 관련 줄은 증거 복사 시 제외했다. 토큰은 보고서에 포함하지 않는다.

## Final assembled-screen result

- **최종 수용 보류**. 캐릭터·글꼴·부모 공간/패딩 방식은 반영했고 기본 크기의 두 기기에서 입력·저장 접근을 확인했다. 큰 글자 본문 잘림은 승인된 본문 스크롤로 해소했다. 공용 토글·커서 등 위 기존 시각 차이가 남아 전체 Pass가 아니다.
- 실기기·접근성 최대 크기·임의 길이 문장·실제 한글 조합·실서버 검증은 미실시. 기존 reducer/입력 조합 코드와 API는 변경하지 않았다.
- [이슈1 HTML](2026-10-28-typing-prompt-9f40daf8-report.html)은 원본 전문·첨부3건·댓글 조회 결과·원인·수정·실제 AS-IS/Figma/TO-BE를 포함한다. Notion 상태·본문·댓글은 수정하지 않았다.

## Report validation

- 원본 전문·첨부3건·댓글 조회 범위·원인·수정·AS-IS/Figma/TO-BE·큰 글자 스크롤 전후를 개별 HTML에 반영했다.
- 연결된 Browser가 없어 bootstrap 확인 후 로컬 Chrome headless 미리보기를 사용했다.1440px/390px에서 이미지 로드·가로 넘침·스크립트 오류와 시각 구성을 확인했다. 깨진 이미지/로컬 링크·미치환 토큰·페이지 가로 넘침·스크립트 오류0건. [브라우저 점검](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/report-browser-check.json).

## Common-font regression

- FullScreenAuditUITests8건 통과, 실제 화면100건과 접근성 트리 확보. 7개 모음과 대표 화면의 수정 전후를 확인했다. [회귀 검토](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/font-audit-review.md), [실행 요약](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/font-audit-summary.json).
- 전체 화면 캡처 성공은 전 화면 Figma Pass를 뜻하지 않는다. 기존 가이드·공유·팝업·공지사항의 차이는 해당 독립 이슈에 남긴다.


## 2026-10-29 Notion 후속 댓글

- 페이지 댓글1건 추가. 안내 Bold, 복사 버튼 동작, 노란색 아이콘 제보. [댓글 조회 원문](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments.json), [원본 HEIC](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments-2026-10-29/comment-408e639f-original.heic), [PNG 열람본](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments-2026-10-29/comment-408e639f-preview.png).
- 댓글 확인 직후 v2 계획 작성 시점에는 현재 로컬 코드의 Pretendard-Bold 토큰/등록, Figma 단색 copy SVG, pasteboard 기록을 확인했으나 실제 붙여넣기와 버튼 자동 회귀 검사는 없었다.
- 당시 작성한 [후속 계획 v2](../screens/2026-10-29-typing-prompt-9f40daf8-plan-v2.md)는 사용자 승인 후 아래에 기록한 재현·검증을 진행했다.


## 2026-10-29 댓글 후속 검증 결과

- 승인: 사용자 발언 “좋아 진행하자”, 계획 v2. 대상: 동일 이슈 page ID `3ffe639f-c7a4-8026-9f40-daf8cf01f20c`.
- 최신 작업본은 iPhone17e / iOS26.4.1 Simulator에서 확인했다. 안내 문구는 Pretendard Bold로 보이며, Light/Dark·한/영·기본/긴 문장·본문 스크롤 확인 UI 테스트가 통과했다. `TypographyResourceTests` 2건과 `TypingLayoutUITests.testPromptAndSaveRemainAccessibleWithKeyboard` 1건 통과, 0 실패/0 skip.
- 복사 버튼 UI 탭 후 `scripts/test-typing-copy.sh <simulator-udid>`의 simulator pasteboard 읽기에서 `사랑이라는 선물은 억지로 줄 수 없고 받아들여지기를 기다릴 뿐이다.\n존우든`을 확인했다. 테스트 러너가 직접 UIPasteboard를 읽는 방법은 iOS 앱 간 붙여넣기 허용 팝업에서 대기해 사용하지 않았다.
- 현재 Figma 전체 프레임·복사 노드 캡처 및 로컬 복사 asset은 단색 윤곽이며, 댓글 첨부만 노란 면이 보인다. 현재 캡처 [복사 탭](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments-2026-10-29/current-run/typing-copy-button-tapped-full-frame.png), [Light](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments-2026-10-29/current-run/typing-layout-light-normal.png), [Dark](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments-2026-10-29/current-run/typing-layout-dark-normal.png), [Figma 아이콘 노드](assets/qa-selected-2026-10-28/typing-prompt-9f40daf8/comments-2026-10-29/current-run/figma-copy-node.png).
- 현재 작업본에서 댓글 증상이 재현되지 않아 production UI 수정은 하지 않았다. 승인 범위 내 회귀용 UI 테스트와 검증 스크립트만 추가했다. 댓글 첨부의 제보 빌드 식별정보가 없으므로 Notion 이슈는 In progress로 남기고, 현 QA 빌드/커밋 확인 전에는 완료 판정하지 않는다.
- Figma full-frame 360×720과 simulator 390×844가 달라 전체 픽셀 비교에 의한 UI 최종 수용은 Blocked다. 첨부와 화면은 앱 동작·타이포·아이콘 확인용으로 기록한다.

- HTML 보고서 정적 검사에서 로컬 이미지/문서 링크 76개 중 깨진 링크 0건, 중복 앵커 0건, 미치환 템플릿 토큰 0건. 브라우저 서비스가 이 세션에 연결되지 않아 넓은/좁은 뷰포트 미리보기는 수행하지 못했다.

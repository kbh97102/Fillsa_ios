# [Home] Dark root `2. home[Dark]`

## Figma UI 기준

- Figma file key: `VdFocqyqTgevMVCQxwAQ2X`
- Root URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%E2%9C%92%EF%B8%8F%ED%95%84%EC%82%AC?node-id=2929-9603
- Root section: `2929:9603` (`2. home[Dark]`, 4586×7550). Section은 상태 인벤토리용이며 런타임 비교 대상이 아니다.
- Render target: 아래 표의 360×821 또는 360×720 frame. 구현 작업자는 root section이 아니라 각 render target에 Figma MCP `get_design_context`를 다시 호출한다.
- Color mode: Dark
- 조사일: 2026-09-07
- 검증 상태: 문서화 완료 / 구현 및 런타임 검증 미착수
- 기준 이미지: `docs/design-qa/assets/home-figma-2929-9603/2026-09-07/`
- QA 준비 문서: `docs/design-qa/2026-09-07-ios-home-dark-root-qa.md`

## 범위 분리

### A. Home 조립 화면

| 상태 | Render node | 크기 | 기준 이미지 | 구현 의미 |
|---|---|---:|---|---|
| 기본 | `3039:26518` | 360×821 | `figma-dark-3039-26518-default.png` | 100일 streak, 미선택 좋아요, 이미지 미등록, 질문 기록 전 |
| 달력 열림 | `3139:1753` | 360×821 | `figma-dark-3139-1753-calendar-open.png` | 날짜 영역 탭 후 Home 위 inline calendar 표시 |
| 0일 streak 안내 | `3039:26778` | 360×821 | `figma-dark-3039-26778-streak-tooltip.png` | caution badge anchor, 안내 tooltip, Calendar 링크 |
| 복사 완료 | `3039:26996` | 360×821 | `figma-dark-3039-26996-copy-toast.png` | 하단 성공 toast `복사되었습니다.` |
| 좋아요·이미지 등록 상태 | `3039:27295` | 360×821 | `figma-dark-3039-27295-liked-home.png` | 선택 heart, thumbnail, `이미지 보기` |

### B. 재사용 컴포넌트/variant

| 컴포넌트 | Set/board | Variant nodes | 계약 |
|---|---|---|---|
| Calendar | `3039:28098` | default `3039:28099`, open `3039:28101` | 월 selector는 route 이동이 아니라 popup toggle이다. 날짜 선택 후 Home 날짜·명언을 갱신하고 닫는다. |
| Weekday | `3039:28626` | none `3039:28627`, today `3039:28629`, done `3039:28631` | 실제 완료 필사일만 done marker를 표시하고 today/selected를 우선한다. |
| Question dark | `3139:1453` | default `3139:1454`, focus `3139:1478`, done `3139:1466` | 200 grapheme, 기록/수정 CTA, UI session state. 정의되지 않은 영구 저장 계약은 만들지 않는다. |

### C. 오늘의 질문 흐름

- Section: `3136:863` (`오늘의 질문 인터랙션 · Dark mode`)
- 기록 전: `3139:910`
- 기록 중 + keyboard: `3136:1198`
- 기록 후 + toast: `3139:1061`
- 기록 후: `3139:1238`
- Composite reference: `figma-dark-3136-863-question-flow.png`

상태 전이는 `기록 전 → 기록 중 → 기록 후 toast → 기록 후`이며, 수정 CTA는 기록 중으로 돌아간다. 질문 CTA는 명언 필사 화면으로 이동하지 않는다.

### D. 이미지 등록 흐름

- Section: `3223:5589` (`이미지등록`)
- 등록 전: `3223:5985`
- 등록 후: `3223:6126`
- 업로드 이미지 보기: `3223:6435`
- 템플릿 이미지 보기: `3223:6600`
- 삭제 확인: `3223:6912`
- Composite reference: `figma-dark-3223-5589-image-flow.png`

`이미지 등록 → 이미지 보기 → 이미지 변경/확인`과 삭제 확인을 기존 domain/API에 연결한다. 보기 modal은 배경 dim, 삭제 action, preview 종류별 content를 포함한다.

### E. 연결 화면: 필사·저장 결과

- Target URL: https://www.figma.com/design/VdFocqyqTgevMVCQxwAQ2X/%E2%9C%92%EF%B8%8F%ED%95%84%EC%82%AC?node-id=3087-28815

| 상태 | Node | 크기 |
|---|---|---:|
| 필사 입력 중 | `3087:28815` | 360×720 |
| 저장 성공 toast | `2929:9764` | 360×720 |
| 오늘도 이어서 필사 | `2929:9801` | 360×720 |
| 연속 필사 완료 | `2929:9844` | 360×720 |
| 필사 미완료 | `2929:9884` | 360×720 |
| 이어서 필사 modal 단독 | `2929:10996` | 320×245 |
| 연속 완료 modal 단독 | `3025:24578` | 320×245 |
| 미완료 modal 단독 | `3025:24618` | 320×245 |

대표 reference는 `figma-dark-3087-28815-typing-active.png`이다. 이 묶음은 Home 내부 컴포넌트가 아니라 기존 필사 route의 dark appearance 회귀 범위다.
입력 중 화면의 `저장하기` 버튼은 `3087:28973`이며 흰색 채움/테두리, `#212121` 텍스트, 8pt radius를 사용한다.

### F. 연결 화면: 인증

- 비회원 login modal: `2929:9931`, reference `figma-dark-2929-9931-login-modal.png`
- 전체 dark login: `2929:10788`

Home의 보호된 이미지 action에서 기존 인증 정책에 따라 modal/route를 사용한다. 인증 정책 자체는 이번 UI 범위에서 바꾸지 않는다.

### G. 연결 화면: 공유

- 첫 공유 진입: `2929:10884`, reference `figma-dark-2929-10884-share-first.png`
- 공유 carousel: `2929:10850`, reference `figma-dark-2929-10850-share-carousel.png`
- 배경 template: `2929:10923`, `2929:10927`, `2929:10931`, `2929:10936`, `2929:10941`, `2929:10945`, `2929:10949`, `2929:10954`, `2929:10963`, `2929:10968`

첫 진입 guide, 좌우 carousel, 저장/복사/카카오 공유의 기존 기능을 보존하고 dark surface만 Figma와 대조한다.

## Dark visual contract

- Root/background: `#212121`
- Quote/input/card surface: `#424242`
- Border/divider: `#616161`
- Primary text: `#FFFFFF`
- Action text: `#E0E0E0`
- Muted weekday/input metadata: `#9E9E9E`
- Primary action/selected date: `#5C65FF`
- CTA secondary/recorded answer: `#D3D5FF`
- Accent: `#FFCB5C`

실제 색·opacity·asset은 각 render node의 `get_design_context` 결과를 우선한다. 특히 `3136:1198`은 keyboard가 포함된 focus 상태이므로 조립 화면과 OS keyboard 영역을 분리해서 비교한다.

## 공통 구현 원칙

1. 라이트 Home에서 이미 구현한 상태 전이와 domain/API는 공유한다. dark 전용 reducer/ViewModel 상태를 복제하지 않는다.
2. 공용 하단 바는 3개 탭을 사용하며, 이번 출시에서는 Figma의 static AD를 포함한 모든 광고 UI를 제외한다.
3. 질문 답변은 현재 data contract가 없으므로 UI session state만 사용한다.
4. 구현 순서는 Home 조립 화면 → 질문 → 이미지 → 필사/인증/공유 연결 화면이다.
5. 테스트는 구현 후 기존 회귀 테스트와 추가된 상태 검증을 실행한다. 별도 TDD 단계는 두지 않는다.
6. 최종 수용은 `docs/ui-redesign-workflow.md`에 따라 emulator/simulator 전체 프레임 비교로만 결정한다.

## 플랫폼별 실행 문서

- iOS: `docs/superpowers/plans/2026-09-07-ios-home-dark-root.md`
- Android: `docs/superpowers/plans/2026-09-07-android-home-dark-root.md`

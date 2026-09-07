# iOS Home Interactions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Figma `2. home`의 inline 달력, 질문 기록/수정, 0일 연속 필사 안내를 기존 이미지·복사·좋아요 흐름과 함께 SwiftUI/TCA Home에 완성한다.

**Architecture:** `HomeFeature.State`를 Home 상호작용의 단일 상태 원천으로 확장하고, 순수 날짜/질문 모델을 SwiftUI 컴포넌트가 렌더링한다. 달력 링크만 `AppView`의 기존 Calendar 탭 선택으로 연결한다. 질문 답변은 UI 세션 상태로만 유지하며 정의되지 않은 서버/API 계약은 만들지 않는다.

**Tech Stack:** Swift 5, SwiftUI, The Composable Architecture, Swift Testing, XCTest UI tests, Figma MCP.

**Spec:** `docs/screens/2_home.md`; Figma file `VdFocqyqTgevMVCQxwAQ2X`; parent `2929:17193`; default `2929:13556`; calendar open `3139:1501`; question flow `3110:33782`; streak tooltip `2929:18871`.

## Global Constraints

- Figma가 UI의 유일한 시각 기준이다. Android/기존 iOS 화면을 시각 기준으로 삼지 않는다.
- 하단 4-route navigation과 질문 영구 저장은 이번 Home 범위 밖이다.
- 컴포넌트 단위 구현 후 빌드·기존 회귀 테스트·런타임 시각 QA 순서로 검증한다.
- 기존 이미지 업로드/삭제, 명언 조회/필사/공유, 좋아요 API 동작을 보존한다.
- 최종 QA는 360×821 light/dark 및 주요 overlay 상태를 캡처해 최대 5회 보정한다.

### Task 1: Reducer interaction state

**Files:**
- Modify: `FiilsaTests/HomeFeatureTests.swift`
- Modify: `Fiilsa/Presentation/Home/HomeFeature.swift`

1. `HomeFeature.State`에 `isCalendarPresented`, `calendarDisplayedMonth`, `isStreakTooltipPresented`, `answerDraft`, `recordedAnswer`, `isEditingAnswer`를 추가한다.
2. `HomeFeature.Action`에 calendar/streak/question action을 추가하고 상태 전이를 구현한다.
3. 날짜 선택은 popup을 닫고 기존 명언 조회 effect를 재사용한다.

### Task 2: Calendar and week components

**Files:**
- Modify: `FiilsaTests/HomeFeatureTests.swift`
- Modify: `Fiilsa/Presentation/Home/HomeFigmaComponents.swift`
- Create: `Fiilsa/Presentation/Home/HomeInlineCalendar.swift`

1. `HomeWeekStrip` 날짜 범위를 `-6...0`으로 바꾸고 날짜 탭 action을 노출한다.
2. `HomeCalendarDay`와 월 grid 생성기를 순수 값 타입으로 구현한다.
3. Figma `2929:16227`의 248×335 popup, `2929:16229`/`16240` 월 이동, `2929:16232` 연도, `2929:16236` 월 선택, `2929:16243` 요일, `2929:16258` grid를 `HomeInlineCalendar`로 구현한다.

### Task 3: Question and streak components

**Files:**
- Modify: `Fiilsa/Presentation/Home/HomeFigmaComponents.swift`
- Modify: `FiilsaUITests/HomeUITests.swift`

1. `HomeQuestionAnswerCard`를 기본 `3087:29376`, focus `3139:1399`, done `3087:29378` 상태로 분리하고 기록/수정 action을 노출한다.
2. `HomeHeader`에 `2929:19015` 툴팁과 외부 닫기 hit area를 추가한다.
3. 저장 toast는 `3110:34293`의 문구와 기존 Home toast visual을 재사용한다.
4. 주요 상태에 `home.calendarTrigger`, `home.calendarPopup`, `home.streakStatus`, `home.streakTooltip`, `home.answerRecord`, `home.answerEdit` 식별자를 부여한다.

### Task 4: Home assembly and Calendar route

**Files:**
- Modify: `Fiilsa/Presentation/Home/HomeView.swift`
- Modify: `Fiilsa/App/AppView.swift`
- Modify: `FiilsaTests/AppFeatureTests.swift`

1. `HomeView`의 로컬 `answer` 상태와 질문 CTA의 `openTyping` 연결을 제거하고 reducer action에 연결한다.
2. 월 selector 아래에 popup을 overlay로 배치하며 외부 탭으로 닫는다. 날짜 선택은 reducer가 명언을 다시 조회한다.
3. streak tooltip의 `나의 필사현황 보기`를 기존 `.calendar` tab 선택 action에 연결한다.
4. 기존 명언 카드 탭만 `openTyping`을 유지하는 회귀 테스트를 실행한다.

### Task 5: Build, runtime QA, documentation

**Files:**
- Modify: `docs/screens/2_home.md`
- Create/Modify: `docs/design-qa/2026-09-07-ios-home-interactions-qa.md`
- Add captures: `docs/design-qa/assets/home-figma-2929-17193/2026-09-07/runtime-ios-*.png`

1. `xcodebuild -quiet -project Fiilsa.xcodeproj -scheme Fiilsa -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages CODE_SIGNING_ALLOWED=NO build`를 실행한다.
2. Task 1의 targeted tests와 관련 UI test를 실행한다.
3. simulator에서 default, calendar-open, question-focus/done/toast, streak-tooltip, image modal, light/dark 화면을 캡처한다.
4. Figma 기준 캡처와 구조/간격/색/타이포/아이콘/상태를 비교하고 최대 5회 수정한다.
5. `docs/screens/2_home.md`의 검증 상태와 QA 링크를 최종 결과로 갱신한다.

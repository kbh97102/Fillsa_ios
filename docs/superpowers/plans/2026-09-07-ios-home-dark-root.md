# iOS Home Dark Root Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` to execute this plan task-by-task. Read `figma:figma-design-to-code` and `figma:figma-swiftui` before the first Figma MCP call.

**Goal:** Figma dark Home root `2929:9603`의 Home 조립 상태와 연결된 질문·이미지·필사·인증·공유 화면을 기존 SwiftUI/TCA 동작을 보존하면서 시각적으로 정렬한다.

**Architecture:** 기존 `HomeFeature.State`와 light/dark 공용 action을 단일 상태 원천으로 유지하고, 색상·asset·surface 차이는 SwiftUI environment와 전용 presentation 값에서 해결한다. Home에서 연결되는 Typing/Login/Share는 기존 route와 domain/API를 재사용하며 dark 전용 상태 모델을 만들지 않는다.

**Tech Stack:** Swift, SwiftUI, The Composable Architecture, PhotosUI, XCTest/Swift Testing, Figma MCP, iOS Simulator.

**Spec:** `docs/screens/2_home_dark.md`; Figma file `VdFocqyqTgevMVCQxwAQ2X`; root `2929:9603`.

## Global Constraints

- 구현 전에 맡은 render node에 `get_design_context`를 개별 호출한다. section root의 sparse metadata만으로 구현하지 않는다.
- `docs/ui-redesign-workflow.md`를 따르며 Figma가 유일한 시각 기준이다.
- 기존 4-route navigation, live ad, 명언/좋아요/이미지/필사 API와 인증 정책을 보존한다.
- 질문 답변은 정의된 backend 계약이 없으므로 기존 UI session state 범위를 넘기지 않는다.
- 구현 후 회귀 테스트를 수행한다. 별도 TDD/red-green 단계는 두지 않는다.
- 최종 결과는 dark simulator 전체 프레임을 상태별로 캡처해 최대 5회 비교한 뒤 `Pass` 또는 `Blocked`로 기록한다.

---

### Task 1: Dark Home shell과 공용 component delta audit

**Figma:** 기본 `3039:26518`; calendar open `3139:1753`; Calendar variants `3039:28099`/`3039:28101`; Weekday variants `3039:28627`/`3039:28629`/`3039:28631`.

**Files:**
- Modify if a measured delta exists: `Fiilsa/Presentation/Home/HomeFigmaComponents.swift`
- Modify if a measured delta exists: `Fiilsa/Presentation/Home/HomeInlineCalendar.swift`
- Modify if a measured delta exists: `Fiilsa/Presentation/Home/HomeView.swift`
- Post-implementation tests: `FiilsaTests/HomeFeatureTests.swift`, `FiilsaUITests/HomeUITests.swift`

**Interfaces:**
- Preserve: `HomeFigmaPalette.resolve(isDark: Bool) -> HomeFigmaPalette`
- Preserve: `HomeFeature.Action.calendarTriggerTapped`, `.calendarMonthChanged(Date)`, `.calendarDateSelected(Date)`, `.calendarDismissed`
- Preserve: `HomeDateControls(date:completedWritingDates:selectCalendar:selectDate:)`

- [ ] Export/read both render nodes and record exact frame, spacing, typography, opacity, and asset differences against the current dark runtime.
- [ ] Correct only verified dark deltas in root background, header, date strip, locale toggle, quote card, action row, question shell, ad boundary, and popup stacking.
- [ ] Confirm calendar tap toggles the inline popup, outside tap dismisses it, and valid date selection refreshes the Home quote.
- [ ] Run Home unit/UI regression tests after the implementation changes.

### Task 2: Streak tooltip, copy toast, and selected Home state

**Figma:** streak tooltip `3039:26778`; copy toast `3039:26996`; liked/image state `3039:27295`.

**Files:**
- Modify if required: `Fiilsa/Presentation/Home/HomeStreakTooltip.swift`
- Modify if required: `Fiilsa/Presentation/Home/HomeFigmaComponents.swift`
- Modify if required: `Fiilsa/Presentation/Home/HomeView.swift`
- Modify behavior only for a verified mismatch: `Fiilsa/Presentation/Home/HomeFeature.swift`
- Post-implementation tests: `FiilsaTests/HomeFeatureTests.swift`, `FiilsaUITests/HomeUITests.swift`

**Interfaces:**
- Preserve: `HomeFeature.Action.streakStatusTapped`, `.streakTooltipDismissed`, `.copyCompleted`, `.toastDismissed`, `.likeTapped(Bool)`
- Preserve: `HomeToastPresentation.resolve(message: String)`

- [ ] Match the tooltip anchor, caret, dim behavior, text, underline link, and Calendar navigation to `3039:26778`.
- [ ] Match the standard copy toast to `3039:26996` without changing the separate success presentation used by question recording.
- [ ] Match selected heart color and registered-image thumbnail/label to `3039:27295`.
- [ ] Run reducer and UI regressions for zero/unknown/positive streak, copy dismissal, like toggle, and image label state.

### Task 3: Dark question state family

**Figma:** component board `3139:1453`; default `3139:1454`; focus `3139:1478`; done `3139:1466`; flow `3136:863`; full frames `3139:910`, `3136:1198`, `3139:1061`, `3139:1238`.

**Files:**
- Modify if required: `Fiilsa/Presentation/Home/HomeFigmaComponents.swift`
- Modify if required: `Fiilsa/Presentation/Home/HomeView.swift`
- Modify behavior only for a verified mismatch: `Fiilsa/Presentation/Home/HomeFeature.swift`
- Post-implementation tests: `FiilsaTests/HomeFeatureTests.swift`, `FiilsaUITests/HomeUITests.swift`

**Interfaces:**
- Preserve: `answerDraft`, `recordedAnswer`, `isEditingAnswer`
- Preserve: `.answerDraftChanged(String)`, `.answerRecordTapped`, `.answerEditTapped`
- Preserve the 200-grapheme limiter and `답변을 기록했어요.` success toast.

- [ ] Align default, focused, recorded-toast, and recorded states with the four dark full frames.
- [ ] Verify focus border, keyboard-driven viewport, counter, placeholder, CTA colors, and read-only recorded field independently.
- [ ] Confirm the question CTA never invokes the Typing route and edit returns to the inline input state.
- [ ] Run post-implementation reducer/UI regression tests, including Korean composed-character length behavior.

### Task 4: Dark image registration and modal family

**Figma:** section `3223:5589`; before `3223:5985`; after `3223:6126`; uploaded preview `3223:6435`; template preview `3223:6600`; delete confirmation `3223:6912`.

**Files:**
- Modify if required: `Fiilsa/Presentation/HomeSub/HomeImageDialog.swift`
- Modify if required: `Fiilsa/Presentation/Home/HomeView.swift`
- Modify behavior only for a verified mismatch: `Fiilsa/Presentation/Home/HomeFeature.swift`
- Add/update only verified Figma assets: `Fiilsa/Assets.xcassets/`
- Post-implementation tests: `FiilsaTests/HomeFeatureTests.swift`, `FiilsaUITests/HomeUITests.swift`

**Interfaces:**
- Preserve: `.imageTapped`, `.imagePicked(URL)`, `.imageDialogDismissed`, `.deleteImageTapped`, `.deleteImageConfirmed`, `.deleteImageCancelled`
- Preserve existing image upload/delete use cases and authenticated access rules.

- [ ] Separate upload-image and template-image preview presentation without duplicating upload/delete effects.
- [ ] Match modal size, corner radius, background dim, close/delete controls, quote layout, and `이미지 변경`/`확인` buttons.
- [ ] Match delete confirmation copy and button order to `3223:6912`.
- [ ] Run post-implementation image state and authentication regressions; use deterministic fixture images for UI capture.

### Task 5: Linked Typing, Login, and Share dark surfaces

**Figma:** Typing `3087:28815`, `2929:9764`, `2929:9801`, `2929:9844`, `2929:9884`; completion modals `2929:10996`, `3025:24578`, `3025:24618`; login `2929:9931`, `2929:10788`; share `2929:10884`, `2929:10850`; templates listed in the spec.

**Files:**
- Modify if required: `Fiilsa/Presentation/HomeSub/TypingQuoteView.swift`
- Modify if required: `Fiilsa/Presentation/HomeSub/TypingQuoteBodySection.swift`
- Modify if required: `Fiilsa/Presentation/HomeSub/TypingFeature.swift`
- Modify if required: `Fiilsa/Presentation/Login/LoginView.swift`
- Modify if required: `Fiilsa/Presentation/HomeSub/ShareView.swift`
- Modify if required: `Fiilsa/Presentation/HomeSub/ShareFeature.swift`
- Add/update only verified assets: `Fiilsa/Assets.xcassets/`
- Post-implementation tests: `FiilsaTests/LoginFeatureTests.swift`, `FiilsaUITests/LoginDarkModeUITests.swift`

- [ ] Treat these as route-level dark appearance regressions, not new Home-local state.
- [ ] Align typing input, save toast, three completion outcomes, login modal/full login, first-share guide, carousel, and action bar with their individual nodes.
- [ ] Preserve typing persistence, social login, photo save, clipboard, native share, and Kakao integrations.
- [ ] Run existing route-level regression tests after all visual changes.

### Task 6: Build, simulator QA, and documentation

**Files:**
- Create/update: `docs/design-qa/2026-09-07-ios-home-dark-root-qa.md`
- Modify: `docs/screens/2_home_dark.md`
- Add runtime captures: `docs/design-qa/assets/home-figma-2929-9603/2026-09-07/runtime-ios-dark-*.png`

- [ ] Run `xcodebuild -quiet -project Fiilsa.xcodeproj -scheme Fiilsa -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages CODE_SIGNING_ALLOWED=NO build`.
- [ ] Run affected unit tests and Home/Login UI tests after implementation.
- [ ] Boot an iOS Simulator, force dark appearance, and capture every Task 1–5 target that is reachable.
- [ ] Compare component crops and complete assembled frames against the stored Figma references for up to five rounds.
- [ ] Record viewport differences explicitly. A 402×874 simulator capture does not satisfy strict 360×821 acceptance; if no exact full-frame runtime target exists, final status remains `Blocked`.
- [ ] Update the spec and QA document with commands, captures, comparison method, remaining differences, and final result.

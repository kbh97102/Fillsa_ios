# Home Responsive Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Home의 액션 행, 질문 입력창, 명언 카드, 이미지 팝업, 달력/연속필사 툴팁을 고정 화면 좌표·고정 콘텐츠 높이 대신 부모 폭, 최소 높이, 자연스러운 콘텐츠 흐름, 대상 버튼 앵커로 배치한다.

**Architecture:** 기존 `HomeView`와 Home 하위 SwiftUI 컴포넌트 경계를 유지한다. 화면 상태와 이벤트는 이미 `HomeFeature`에 있으므로 TCA State/Action/Reducer는 변경하지 않는다. 레이아웃은 SwiftUI 기본 기능(`GeometryReader`, `Spacer`, `frame(minHeight:)`, `anchorPreference`)만 사용하며 새 의존성이나 범용 레이아웃 계층을 만들지 않는다.

**Tech Stack:** Swift 6, SwiftUI, The Composable Architecture, XCTest/XCUITest, Figma MCP QA

**Spec:** [Home 화면 명세](/Users/gangbohun/iosProjects/Fiilsa/docs/screens/2_home.md), [UI 검증 절차](/Users/gangbohun/iosProjects/Fiilsa/docs/ui-redesign-workflow.md), Figma root `2929:13556`

## Global Constraints

- Figma가 단일 기준이다. 이번 범위의 기준 노드는 액션 행 `3207:3059`(버튼 비율 `70:70:70:107`), 질문 `2929:13630`, 명언 카드 `2929:13642`, 이미지 보기 `3223:4773`/팝업 `3223:4966`, 달력 열림 `3139:1501`/컴포넌트 `2929:16221`, 연속필사 안내 `2929:18871`/툴팁 `2929:19016`이다.
- 아이콘의 Figma 고정 크기는 이번 변경에서 제외한다.
- 액션 행의 42pt, 질문 입력창의 174pt, 명언 카드의 150pt, 이미지 팝업의 320:373, 달력 버튼과 팝업 사이 6pt는 절대 화면 좌표가 아니라 Figma가 정의한 컴포넌트 내부 계약으로만 사용한다.
- `HomeFeature`의 상태, 액션, 효과, API 흐름은 변경하지 않는다.
- 전체 테스트 스위트는 실행하지 않는다. 각 작업의 focused UI test와 영향받은 기존 Home UI test만 실행한다.
- 시뮬레이터에서 360×821 런타임을 만들 수 없으면 기존 규칙대로 최종 Figma 판정은 `Blocked`로 기록하고, 402×874 캡처는 부분 증거로만 사용한다.

## Review Focus

- 360pt 기준에서 액션 행이 좌우 20pt inset 안의 320pt를 정확히 채우고 `70:70:70:107` 비율을 유지하는가.
- 긴 명언과 접근성 글자 크기에서 명언 카드가 150pt 아래로 압축되거나 잘리지 않는가. 질문 입력창은 174pt를 최소값으로 유지하는가.
- 이미지 팝업에서 90pt/86pt 고정 여백이 사라지고, 헤더·본문·버튼 사이 남는 공간이 유연하게 분배되는가.
- 달력은 월 버튼의 leading과 일치하고 버튼 아래 6pt에 열리는가. 툴팁 화살표 중심은 연속필사 버튼 중심을 가리키는가.
- 팝업/툴팁 외부 탭 dismiss, 날짜 선택, Calendar 이동, 이미지 변경/삭제/확인 동작이 유지되는가.

---

### Task 1: 명언 액션 버튼을 부모 폭의 Figma 비율로 분배

**Files:**
- Modify: `Fiilsa/Presentation/Home/HomeFigmaComponents.swift:487-561`
- Modify: `Fiilsa/Presentation/Home/HomeView.swift:58-63`
- Test: `FiilsaUITests/HomeUITests.swift:3-20`

- [ ] **Step 1: 고정 폭을 검출하는 UI test를 먼저 추가한다**

`HomeUITests`에 아래 테스트를 추가한다. 테스트를 안정적으로 조회할 수 있도록 구현 단계에서 복사/공유/좋아요 버튼에 각각 `home.copy`, `home.share`, `home.like` 식별자를 붙인다.

```swift
@MainActor
func testQuoteActionsUseFigmaProportionsWithinScreenInsets() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing-home"]
    app.launch()

    let copy = app.buttons["home.copy"]
    let share = app.buttons["home.share"]
    let like = app.buttons["home.like"]
    let image = app.buttons["home.registerImage"]
    XCTAssertTrue(image.waitForExistence(timeout: 2))

    XCTAssertEqual(copy.frame.minX, 20, accuracy: 1)
    XCTAssertEqual(image.frame.maxX, app.frame.maxX - 20, accuracy: 1)
    XCTAssertEqual(copy.frame.width, share.frame.width, accuracy: 1)
    XCTAssertEqual(share.frame.width, like.frame.width, accuracy: 1)
    XCTAssertEqual(copy.frame.width / image.frame.width, 70.0 / 107.0, accuracy: 0.02)
}
```

- [ ] **Step 2: 테스트가 현재 80/80/80/90pt 구현에서 실패하는지 확인한다**

Run:

```bash
xcodebuild -quiet test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -only-testing:FiilsaUITests/HomeUITests/testQuoteActionsUseFigmaProportionsWithinScreenInsets \
  -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 \
  -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' \
  -derivedDataPath /tmp/fiilsa-home-responsive-derived \
  -clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages \
  CODE_SIGNING_ALLOWED=NO
```

Expected: 버튼 식별자가 없거나 좌우 inset/`70:107` 비율 assertion이 실패한다.

- [ ] **Step 3: 3개 divider를 제외한 폭을 비율로 나눈다**

`HomeQuoteActionRow.body`를 다음 구조로 바꾼다. `317`은 Figma 버튼 폭 합계 `70 + 70 + 70 + 107`이며 화면 폭과 무관하다.

```swift
var body: some View {
    GeometryReader { proxy in
        let buttonWidth = max(0, proxy.size.width - 3)
        let standardWidth = buttonWidth * 70 / 317

        HStack(spacing: 0) {
            action("home_action_copy", "복사", copy)
                .frame(width: standardWidth)
                .accessibilityIdentifier("home.copy")
            divider
            action("home_action_share", "공유", share)
                .frame(width: standardWidth)
                .accessibilityIdentifier("home.share")
            divider
            likeAction
                .frame(width: standardWidth)
                .accessibilityIdentifier("home.like")
            divider
            action("home_action_camera", "이미지 등록", registerImage)
                .frame(width: buttonWidth - standardWidth * 3)
                .accessibilityIdentifier("home.registerImage")
        }
    }
    .frame(height: 42)
}
```

`HomeView`의 호출부에는 Figma row `x=20, width=320`을 부모 폭에 맞춰 유지하도록 horizontal inset만 둔다.

```swift
HomeQuoteActionRow(...)
    .padding(.top, 10)
    .padding(.horizontal, 20)
```

- [ ] **Step 4: focused test를 다시 실행한다**

Expected: PASS. iPhone 17 Pro 폭에서도 좌우 20pt를 제외한 남은 폭이 같은 비율로 분배된다.

- [ ] **Step 5: 변경 파일만 커밋한다**

```bash
git add Fiilsa/Presentation/Home/HomeFigmaComponents.swift Fiilsa/Presentation/Home/HomeView.swift FiilsaUITests/HomeUITests.swift
git commit -m "fix: make home quote actions proportional"
```

### Task 2: 질문 입력창과 명언 카드를 최소 높이 기반으로 전환

**Files:**
- Modify: `Fiilsa/Presentation/Home/HomeFigmaComponents.swift:402-450`
- Modify: `Fiilsa/Presentation/Home/DailyQuoteSection.swift:48-90`
- Modify: `Fiilsa/FiilsaApp.swift:53-72`
- Test: `FiilsaUITests/HomeUITests.swift`

- [ ] **Step 1: 긴 명언 fixture와 실패 테스트를 추가한다**

`FiilsaApp.makeInitialState`의 Home fixture에서 launch argument에 따라 명언만 교체한다.

```swift
let homeQuote = arguments.contains("-ui-testing-home-long-quote")
    ? "사랑은 상대를 바꾸려는 마음이 아니라 서로 다른 시간을 이해하고 기다리며, 늦게 도착한 진심까지도 다치지 않게 받아들이는 오래된 연습이다. 그 연습은 오늘의 작은 친절에서 다시 시작된다."
    : "사랑이라는 선물은 억지로 줄 수 없고 받아들여지기를 기다릴 뿐이다."
```

`DailyQuote(korQuote:)`에는 기존 literal 대신 `homeQuote`를 전달한다. 이어서 아래 테스트를 추가한다.

```swift
@MainActor
func testLongQuoteExpandsCardBeyondFigmaMinimum() throws {
    let app = XCUIApplication()
    app.launchArguments = [
        "-ui-testing-home",
        "-ui-testing-home-long-quote",
        "-UIPreferredContentSizeCategoryName",
        "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
    ]
    app.launch()

    let quoteCard = app.buttons["home.quoteCard"]
    XCTAssertTrue(quoteCard.waitForExistence(timeout: 2))
    XCTAssertGreaterThan(quoteCard.frame.height, 150)
}
```

- [ ] **Step 2: 현재 150pt 고정 카드에서 실패하는지 확인한다**

Run:

```bash
xcodebuild -quiet test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -only-testing:FiilsaUITests/HomeUITests/testLongQuoteExpandsCardBeyondFigmaMinimum \
  -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 \
  -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' \
  -derivedDataPath /tmp/fiilsa-home-responsive-derived \
  -clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages \
  CODE_SIGNING_ALLOWED=NO
```

Expected: `quoteCard.frame.height == 150`으로 실패한다.

- [ ] **Step 3: 질문 입력창은 174pt를 최소값으로만 유지한다**

입력창 컨테이너의 `maxHeight: 174`만 제거한다. 입력 텍스트와 placeholder는 기본 크기는 유지하면서 Dynamic Type을 따르도록 같은 상대 스타일을 사용한다.

```swift
ZStack(alignment: .topLeading) {
    TextEditor(text: limitedAnswer)
        .font(.custom("Pretendard-Regular", size: 12, relativeTo: .caption))
        .foregroundStyle(palette.primaryText.color)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("home.answer")
        .accessibilityLabel("오늘의 답변")
        .accessibilityHint("최대 200자까지 입력할 수 있습니다.")
        .disabled(!isEditing)
        .focused($isAnswerFocused)

    if answer.isEmpty {
        Text(placeholder)
            .font(.custom("Pretendard-Regular", size: 12, relativeTo: .caption))
            .foregroundStyle(palette.answerPlaceholder.color)
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .allowsHitTesting(false)
    }
}
.frame(maxWidth: .infinity, minHeight: 174)
.background(palette.answerFieldBackground.color.opacity(palette.answerFieldOpacity))
.clipShape(RoundedRectangle(cornerRadius: 17))
.overlay(
    RoundedRectangle(cornerRadius: 17)
        .stroke(
            isAnswerFocused && isEditing ? FillsaColor.purple01 : palette.answerFieldBorder.color,
            lineWidth: 1
        )
)
```

`TextEditor` 자체의 스크롤 동작과 200자 제한은 유지한다. 콘텐츠 높이를 재는 별도 `PreferenceKey`나 UIKit bridge는 추가하지 않는다.

- [ ] **Step 4: 명언 카드는 콘텐츠가 150pt를 넘으면 확장되게 한다**

```swift
Text(text)
    .font(.custom("GangwonEduAll-Light", size: 16, relativeTo: .body).weight(.bold))
    .foregroundStyle(palette.primaryText.color)
    .multilineTextAlignment(.center)
    .lineSpacing(4)
    .fixedSize(horizontal: false, vertical: true)
    .frame(maxWidth: .infinity)
    .padding(.top, 28)
    .padding(.horizontal, 10)
```

같은 ZStack의 기존 `.frame(height: 150)`은 `.frame(minHeight: 150)`으로 교체한다.

기존 `Spacer()`가 짧은 문구에서는 Figma의 저자 위치를 유지하고, 긴 문구에서는 먼저 축소된 뒤 카드 자체가 커지게 한다.

- [ ] **Step 5: 긴 명언 test와 기존 키보드 회귀 test만 실행한다**

Run:

```bash
xcodebuild -quiet test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -only-testing:FiilsaUITests/HomeUITests/testLongQuoteExpandsCardBeyondFigmaMinimum \
  -only-testing:FiilsaUITests/HomeUITests/testAnswerRecordButtonRemainsVisibleAboveKeyboard \
  -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 \
  -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' \
  -derivedDataPath /tmp/fiilsa-home-responsive-derived \
  -clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages \
  CODE_SIGNING_ALLOWED=NO
```

Expected: 두 test PASS. 질문 CTA가 키보드 위에 유지되고 긴 명언 카드는 150pt보다 커진다.

- [ ] **Step 6: 변경 파일만 커밋한다**

```bash
git add Fiilsa/Presentation/Home/HomeFigmaComponents.swift Fiilsa/Presentation/Home/DailyQuoteSection.swift Fiilsa/FiilsaApp.swift FiilsaUITests/HomeUITests.swift
git commit -m "fix: let home text containers grow"
```

### Task 3: 이미지 팝업의 고정 상하 여백을 유연한 공간으로 교체

**Files:**
- Modify: `Fiilsa/Presentation/HomeSub/HomeImageDialog.swift:19-91`
- Test: `FiilsaUITests/HomeUITests.swift`

- [ ] **Step 1: 팝업의 비율과 버튼 경계를 검증하는 test를 추가한다**

```swift
@MainActor
func testImageDialogUsesWidthBasedFigmaRatio() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing-home", "-ui-testing-home-image-modal"]
    app.launch()

    let dialog = app.otherElements["home.imageDialog"]
    let confirm = app.buttons["확인"]
    XCTAssertTrue(dialog.waitForExistence(timeout: 2))
    XCTAssertTrue(confirm.exists)
    XCTAssertEqual(dialog.frame.width / dialog.frame.height, 320.0 / 373.0, accuracy: 0.02)
    XCTAssertLessThan(confirm.frame.maxY, dialog.frame.maxY)
}
```

- [ ] **Step 2: 현재 content-fixed 팝업에서 ratio assertion이 실패하는지 확인한다**

Run:

```bash
xcodebuild -quiet test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -only-testing:FiilsaUITests/HomeUITests/testImageDialogUsesWidthBasedFigmaRatio \
  -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 \
  -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' \
  -derivedDataPath /tmp/fiilsa-home-responsive-derived \
  -clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages \
  CODE_SIGNING_ALLOWED=NO
```

Expected: `fixedSize(vertical: true)`와 90/86pt padding 때문에 320:373 비율이 맞지 않아 실패한다.

- [ ] **Step 3: 헤더/본문/버튼을 자연스러운 세 구간으로 배치한다**

`padding(.top, 90)`, `padding(.top, 86)`, `fixedSize(vertical: true)`를 제거하고 아래 흐름으로 교체한다.

```swift
ZStack(alignment: .topLeading) {
    background
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()

    VStack(spacing: 0) {
        HStack(spacing: 8) {
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(FillsaColor.gray700)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)

            if !imagePath.isEmpty {
                Button(action: delete) {
                    Text("삭제하기")
                        .font(FillsaTypography.body2)
                        .foregroundStyle(FillsaColor.gray700)
                        .underline()
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        Spacer(minLength: 12)

        VStack(spacing: 12) {
            Text(quote)
                .font(FillsaTypography.body2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
            Text(author)
                .font(FillsaTypography.body2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }

        Spacer(minLength: 12)
        HStack(spacing: 10) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Text("이미지 변경")
                    .font(FillsaTypography.subtitle1)
                    .foregroundStyle(FillsaColor.gray700)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(FillsaColor.white.opacity(0.9))
                    )
            }
            .buttonStyle(.plain)

            dialogButton("확인", action: dismiss)
        }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 20)
}
.aspectRatio(320.0 / 373.0, contentMode: .fit)
.clipShape(RoundedRectangle(cornerRadius: 12))
.padding(.horizontal, 20)
.accessibilityElement(children: .contain)
.accessibilityIdentifier("home.imageDialog")
```

헤더와 버튼 행은 새 타입으로 추출하지 않고 현재 HStack 코드를 같은 `body` 안에서 이동한다. 320pt 폭에서는 Figma 373pt 높이가 나오고, 다른 폭에서는 같은 비율로 변한다.

- [ ] **Step 4: 이미지 팝업 focused test를 다시 실행한다**

Expected: PASS. 닫기/삭제/변경/확인 버튼은 기존 동작을 유지한다.

- [ ] **Step 5: 변경 파일만 커밋한다**

```bash
git add Fiilsa/Presentation/HomeSub/HomeImageDialog.swift FiilsaUITests/HomeUITests.swift
git commit -m "fix: make home image dialog spacing flexible"
```

### Task 4: 달력과 연속필사 툴팁을 버튼 앵커에 연결

**Files:**
- Modify: `Fiilsa/Presentation/Home/HomeFigmaComponents.swift:121-245`
- Modify: `Fiilsa/Presentation/Home/HomeView.swift:87-143`
- Modify: `Fiilsa/Presentation/Home/HomeStreakTooltip.swift:21-31`
- Test: `FiilsaUITests/HomeUITests.swift`

- [ ] **Step 1: 절대 top padding을 검출하는 anchor test를 추가한다**

```swift
@MainActor
func testCalendarPopupIsAnchoredToMonthButton() throws {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing-home", "-ui-testing-home-calendar-open"]
    app.launch()

    let trigger = app.buttons["home.calendarTrigger"]
    let popup = app.otherElements["home.calendarPopup"]
    XCTAssertTrue(popup.waitForExistence(timeout: 2))
    XCTAssertEqual(popup.frame.minX, trigger.frame.minX, accuracy: 1)
    XCTAssertEqual(popup.frame.minY, trigger.frame.maxY + 6, accuracy: 1)
}

@MainActor
func testStreakTooltipArrowIsAnchoredToStatusButton() throws {
    let app = XCUIApplication()
    app.launchArguments = [
        "-ui-testing-home",
        "-ui-testing-home-zero-streak",
        "-ui-testing-home-streak-tooltip"
    ]
    app.launch()

    let trigger = app.buttons["home.streakStatus"]
    let tooltip = app.otherElements["home.streakTooltip"]
    XCTAssertTrue(tooltip.waitForExistence(timeout: 2))
    XCTAssertEqual(tooltip.frame.minY, trigger.frame.maxY + 7, accuracy: 1)
    XCTAssertEqual(tooltip.frame.maxX - 26.5, trigger.frame.midX, accuracy: 1)
}
```

- [ ] **Step 2: 현재 84pt/49pt top padding 구현에서 실패하는지 확인한다**

Run both new tests. Expected: popup/tooltip 위치가 trigger frame 변화와 연결되지 않아 적어도 하나의 assertion이 실패한다.

- [ ] **Step 3: 두 trigger의 bounds를 한 PreferenceKey로 노출한다**

`HomeFigmaComponents.swift`에 Home 전용 최소 타입만 추가한다.

```swift
enum HomeOverlayAnchor: Hashable {
    case calendarTrigger
    case streakStatus
}

struct HomeOverlayAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [HomeOverlayAnchor: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [HomeOverlayAnchor: Anchor<CGRect>],
        nextValue: () -> [HomeOverlayAnchor: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}
```

`HomeHeader`의 streak button과 `HomeMonthSelector` button에 각각 다음 modifier를 붙인다.

```swift
.anchorPreference(
    key: HomeOverlayAnchorPreferenceKey.self,
    value: .bounds,
    transform: { [.streakStatus: $0] }
)
```

```swift
.anchorPreference(
    key: HomeOverlayAnchorPreferenceKey.self,
    value: .bounds,
    transform: { [.calendarTrigger: $0] }
)
```

- [ ] **Step 4: HomeView overlay를 anchor 좌표로 배치한다**

기존 `.overlay { ... }`를 `.overlayPreferenceValue`와 `GeometryReader`로 교체한다. backdrop, 이미지 팝업, toast 순서는 유지한다.

```swift
.overlayPreferenceValue(HomeOverlayAnchorPreferenceKey.self) { anchors in
    GeometryReader { proxy in
        ZStack(alignment: .topLeading) {
            if viewStore.isCalendarPresented || viewStore.isStreakTooltipPresented {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if viewStore.isCalendarPresented {
                            viewStore.send(.calendarDismissed)
                        }
                        if viewStore.isStreakTooltipPresented {
                            viewStore.send(.streakTooltipDismissed)
                        }
                    }
            }

            if viewStore.isCalendarPresented,
               let anchor = anchors[.calendarTrigger] {
                let trigger = proxy[anchor]
                HomeInlineCalendar(
                    displayedMonth: viewStore.calendarDisplayedMonth,
                    selectedDate: viewStore.date,
                    selectDate: { viewStore.send(.calendarDateSelected($0)) },
                    changeMonth: { viewStore.send(.calendarMonthChanged($0)) }
                )
                .position(
                    x: trigger.minX + 248 / 2,
                    y: trigger.maxY + 6 + 335 / 2
                )
            }

            if viewStore.isStreakTooltipPresented,
               let anchor = anchors[.streakStatus] {
                let trigger = proxy[anchor]
                let tooltipMinX = trigger.midX - (231 - 26.5)
                HomeStreakTooltip(openCalendar: {
                    viewStore.send(.streakTooltipDismissed)
                    openCalendar()
                })
                .position(
                    x: tooltipMinX + 231 / 2,
                    y: trigger.maxY + 7 + 68 / 2
                )
            }

            if viewStore.isImageDialogPresented {
                HomeImageDialog(
                    quote: quote(from: viewStore.quote),
                    author: author(from: viewStore.quote),
                    imagePath: viewStore.quote.imagePath ?? "",
                    dismiss: { viewStore.send(.imageDialogDismissed) },
                    delete: { viewStore.send(.deleteImageTapped) },
                    selectedPhotoItem: $selectedPhotoItem
                )
            }

            if let message = viewStore.toastMessage {
                toast(message, presentation: .resolve(message: message))
                    .transition(.opacity)
                    .onAppear {
                        guard !isQuestionDoneFixture else { return }
                        Task {
                            try? await Task.sleep(nanoseconds: 1_600_000_000)
                            await viewStore.send(.toastDismissed).finish()
                        }
                    }
            }
        }
    }
}
```

- [ ] **Step 5: 툴팁 화살표 중심을 Figma의 trailing 26.5pt에 맞춘다**

`HomeStreakTooltip`의 triangle은 크기를 유지하고 x offset만 Figma `right=16.22`, `width≈21`에 맞춘다.

```swift
Triangle()
    .fill(FillsaColor.gray700)
    .frame(width: 21, height: 18)
    .offset(x: -16, y: -9)
```

- [ ] **Step 6: anchor tests와 기존 열기/닫기 회귀 test를 실행한다**

Run:

```bash
xcodebuild -quiet test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -only-testing:FiilsaUITests/HomeUITests/testCalendarPopupIsAnchoredToMonthButton \
  -only-testing:FiilsaUITests/HomeUITests/testStreakTooltipArrowIsAnchoredToStatusButton \
  -only-testing:FiilsaUITests/HomeUITests/testHomeCalendarAndQuestionRemainInHome \
  -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 \
  -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' \
  -derivedDataPath /tmp/fiilsa-home-responsive-derived \
  -clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages \
  CODE_SIGNING_ALLOWED=NO
```

Expected: 세 test PASS. 외부 탭 dismiss와 Calendar 이동도 수동 QA에서 확인한다.

- [ ] **Step 7: 변경 파일만 커밋한다**

```bash
git add Fiilsa/Presentation/Home/HomeFigmaComponents.swift Fiilsa/Presentation/Home/HomeView.swift Fiilsa/Presentation/Home/HomeStreakTooltip.swift FiilsaUITests/HomeUITests.swift
git commit -m "fix: anchor home overlays to their controls"
```

### Task 5: 컴포넌트별 Figma QA와 문서화

**Files:**
- Modify: `docs/screens/2_home.md`
- Create: `docs/design-qa/2026-09-25-ios-home-responsive-layout-qa.md`
- Create captures under: `docs/design-qa/assets/home-responsive-layout/2026-09-25/`

- [ ] **Step 1: 화면 문서에 이번 범위와 QA 링크를 먼저 추가한다**

`docs/screens/2_home.md`의 Figma UI 기준에 새 QA 링크를 추가하고, 대상 노드·기본/긴 명언·달력 열림·zero streak tooltip·이미지 팝업 상태를 기록한다.

- [ ] **Step 2: 기준 이미지를 영구 경로에 보관한다**

다음 파일명을 사용한다.

```text
figma-home-2929-13556.png
figma-calendar-3139-1501.png
figma-streak-tooltip-2929-18871.png
figma-image-dialog-3223-4773.png
```

- [ ] **Step 3: 영향받은 상태만 런타임 캡처한다**

```text
runtime-home-default.png
runtime-home-long-quote-accessibility.png
runtime-home-calendar-open.png
runtime-home-streak-tooltip.png
runtime-home-image-dialog.png
```

- [ ] **Step 4: 컴포넌트 우선으로 최대 5회 비교·수정한다**

각 round에서 액션 행 → 질문/명언 → 이미지 팝업 → 달력/툴팁 → 전체 Home 순으로 side-by-side 또는 overlay를 기록한다. 360×821과 402×874의 기기 차이는 raw 절대 좌표가 아니라 부모 inset, 비율, anchor 관계로 비교한다.

- [ ] **Step 5: focused Home tests만 한 번 직렬 실행한다**

```bash
xcodebuild -quiet test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -only-testing:FiilsaUITests/HomeUITests/testQuoteActionsUseFigmaProportionsWithinScreenInsets \
  -only-testing:FiilsaUITests/HomeUITests/testLongQuoteExpandsCardBeyondFigmaMinimum \
  -only-testing:FiilsaUITests/HomeUITests/testImageDialogUsesWidthBasedFigmaRatio \
  -only-testing:FiilsaUITests/HomeUITests/testCalendarPopupIsAnchoredToMonthButton \
  -only-testing:FiilsaUITests/HomeUITests/testStreakTooltipArrowIsAnchoredToStatusButton \
  -only-testing:FiilsaUITests/HomeUITests/testAnswerRecordButtonRemainsVisibleAboveKeyboard \
  -only-testing:FiilsaUITests/HomeUITests/testHomeCalendarAndQuestionRemainInHome \
  -parallel-testing-enabled NO -maximum-parallel-testing-workers 1 \
  -destination 'platform=iOS Simulator,id=89410CC6-A661-4252-B810-0E54DE5FB620' \
  -derivedDataPath /tmp/fiilsa-home-responsive-derived \
  -clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages \
  CODE_SIGNING_ALLOWED=NO
```

Expected: focused tests PASS. 전체 테스트 스위트는 사용자 요청대로 생략한다.

- [ ] **Step 6: QA 결과를 커밋한다**

```bash
git add docs/screens/2_home.md docs/design-qa/2026-09-25-ios-home-responsive-layout-qa.md docs/design-qa/assets/home-responsive-layout/2026-09-25
git commit -m "docs: record home responsive layout QA"
```

## Final Acceptance

- [ ] 액션 4개가 화면 폭 변화에도 좌우 20pt 안에서 `70:70:70:107` 비율로 분배된다.
- [ ] 질문 입력창은 최소 174pt이고, 명언 카드는 최소 150pt이며 긴 문구/접근성 글자 크기에서 세로로 확장된다.
- [ ] 이미지 팝업에 90pt/86pt 고정 상하 padding이 없고 320:373 비율 안에서 남는 공간이 `Spacer`로 분배된다.
- [ ] 달력 popup의 leading/top이 월 버튼 anchor 기준이고, tooltip 화살표가 streak button 중심을 가리킨다.
- [ ] Home TCA 상태/동작과 이미지·달력·툴팁 dismiss/navigation 회귀가 없다.
- [ ] QA 기록에 영향받은 컴포넌트와 전체 화면의 최종 결과가 남아 있다.

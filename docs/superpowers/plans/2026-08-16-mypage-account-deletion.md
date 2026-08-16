# My Page Account Deletion Entry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move account deletion from the notification screen to the signed-in My Page bottom menu, matching Figma node `2929:11031` while preserving the existing server deletion flow.

**Architecture:** `MyPageFeature` becomes the single owner of the account-deletion dialog, API effect, failure state, and success delegate. `MyPageBottomButtonSection` renders Figma's signed-in bottom rows and only emits UI callbacks. `AlertFeature` returns to notification-only responsibility; `AppFeature` receives the My Page success delegate and resets the app to logged-out Home.

**Tech Stack:** Swift 5, SwiftUI, The Composable Architecture, XCTest / TCA `TestStore`, existing authenticated `CommonClient`.

## Global Constraints

- Use Figma node `2929:11031` as the iOS visual source of truth for this approved change.
- Show `회원탈퇴` only when `MyPageFeature.State.isLoggedIn` is `true`.
- Preserve the request `DELETE /api/v1/auth/withdraw`, current confirmation copy, local `sessionClient.logout()`, and success destination (Home tab).
- Do not add a new screen, a web deletion flow, a second confirmation, or a new server API.
- Keep the guest My Page free of both `로그아웃` and `회원탈퇴`.
- Keep `Fiilsa.xcodeproj/project.xcworkspace/xcuserdata/**` out of commits.

---

## File Structure

| File | Responsibility |
|---|---|
| `Fiilsa/Presentation/MyPage/MyPageFeature.swift` | My Page deletion state, actions, dependencies, effect, and delegate. |
| `Fiilsa/Presentation/MyPage/MyPageBottomButtonSection.swift` | Figma's `로그아웃 → 버전 → 회원탈퇴` visual rows and tap callbacks. |
| `Fiilsa/Presentation/MyPage/MyPageResignDialog.swift` | Reusable My Page-owned confirmation modal using the existing deletion copy and visual treatment. |
| `Fiilsa/Presentation/MyPage/MyPageView.swift` | Wires deletion callback, dialog, toast, and disabled processing state. |
| `Fiilsa/Presentation/MyPage/MyPageAccessibilityIdentifier.swift` | Stable identifiers for the delete row, dialog, confirm, cancel, and toast. |
| `Fiilsa/Presentation/MyPageSub/AlertFeature.swift` | Notification-only reducer after deletion state/effects are removed. |
| `Fiilsa/Presentation/MyPageSub/AlertView.swift` | Notification-only UI after deletion row, modal, and toast are removed. |
| `Fiilsa/App/AppFeature.swift` | Handles the My Page deletion delegate and resets authenticated feature state. |
| `FiilsaTests/MyPageFeatureTests.swift` | TCA reducer coverage for confirmation, success, cancellation, and failure. |
| `FiilsaTests/AlertFeatureTests.swift` | New focused tests proving the notification reducer no longer carries deletion behavior. |
| `docs/screens/5_mypage.md` | Updates the approved member menu path and Figma layout rules. |
| `docs/screens/5_2_inform.md` | Removes stale account-deletion ownership from the notification screen. |
| `docs/unfinished-features.md` | Marks account deletion as implemented in its new discoverable location and records QA evidence. |

---

### Task 1: Move deletion state and effects into `MyPageFeature`

**Files:**
- Modify: `Fiilsa/Presentation/MyPage/MyPageFeature.swift`
- Modify: `FiilsaTests/MyPageFeatureTests.swift`

**Interfaces:**
- Consumes: `CommonClient.deleteResign: @Sendable () async throws -> Int` and `SessionClient.logout: @Sendable () async throws -> Void`.
- Produces: `MyPageFeature.Action.delegate(.resignCompleted)` after a successful server deletion and local logout.

- [ ] **Step 1: Write the successful account-deletion reducer test**

Add this test using dependency stubs that count one API deletion and one local logout:

```swift
func test_resignConfirmationDeletesAccountThenEmitsSuccessDelegate() async {
    let deleted = LockIsolated(0)
    let loggedOut = LockIsolated(0)
    let store = TestStore(initialState: MyPageFeature.State(isLoggedIn: true, userName: "필사", imagePath: "profile")) {
        MyPageFeature()
    } withDependencies: {
        $0.commonClient.deleteResign = {
            deleted.withValue { $0 += 1 }
            return 1
        }
        $0.sessionClient.logout = {
            loggedOut.withValue { $0 += 1 }
        }
    }

    await store.send(.resignTapped) {
        $0.isResignDialogPresented = true
    }
    await store.send(.resignConfirmed) {
        $0.isResignDialogPresented = false
        $0.isProcessing = true
    }
    await store.receive(.resignCompleted(.success)) {
        $0.isProcessing = false
        $0.isLoggedIn = false
        $0.userName = ""
        $0.imagePath = ""
    }
    await store.receive(.delegate(.resignCompleted))
    XCTAssertEqual(deleted.value, 1)
    XCTAssertEqual(loggedOut.value, 1)
}
```

- [ ] **Step 2: Run the focused test and confirm it fails because `MyPageFeature` has no deletion actions**

Run:

```bash
xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:FiilsaTests/MyPageFeatureTests/test_resignConfirmationDeletesAccountThenEmitsSuccessDelegate
```

Expected: compilation failure referencing missing `resignTapped`, `resignConfirmed`, or `resignCompleted`.

- [ ] **Step 3: Add the minimum My Page deletion reducer contract**

In `State`, add `isProcessing`, `isResignDialogPresented`, and `toastMessage`. In `Action`, add:

```swift
case resignTapped
case resignDialogDismissed
case resignConfirmed
case resignCompleted(Result<Void, ResignError>)
case toastDismissed
```

Add `case resignCompleted` to `Action.Delegate` and add:

```swift
enum ResignError: Error, Equatable { case failed }

@Dependency(\.commonClient) private var commonClient
```

Implement the effect so `resignConfirmed` sets processing, awaits `commonClient.deleteResign()`, then awaits `sessionClient.logout()`. Map any error to `.resignCompleted(.failure(.failed))`; do not clear state before both operations succeed. On success clear member UI values and send the delegate. On failure clear processing and set `탈퇴 처리에 실패했습니다.`. Ignore repeated confirmation while processing.

- [ ] **Step 4: Add cancellation and failure tests**

Add these tests:

```swift
func test_resignDialogDismissalOnlyClosesDialog() async {
    let store = TestStore(initialState: MyPageFeature.State(isLoggedIn: true, isResignDialogPresented: true)) {
        MyPageFeature()
    }
    await store.send(.resignDialogDismissed) {
        $0.isResignDialogPresented = false
    }
}

func test_resignFailureKeepsMemberStateAndShowsToast() async {
    let store = TestStore(initialState: MyPageFeature.State(isLoggedIn: true, userName: "필사")) {
        MyPageFeature()
    } withDependencies: {
        $0.commonClient.deleteResign = { throw TestResignError.failed }
    }
    await store.send(.resignConfirmed) {
        $0.isProcessing = true
    }
    await store.receive(.resignCompleted(.failure(.failed))) {
        $0.isProcessing = false
        $0.toastMessage = "탈퇴 처리에 실패했습니다."
    }
}
```

Define `private enum TestResignError: Error { case failed }` in the test file. Include a `toastDismissed` assertion so the feature has no retained failure UI state.

Add a duplicate-submission guard test:

```swift
func test_resignConfirmationDoesNothingWhileAlreadyProcessing() async {
    let store = TestStore(initialState: MyPageFeature.State(isLoggedIn: true, isProcessing: true)) {
        MyPageFeature()
    }
    await store.send(.resignConfirmed)
}
```

This test must finish without receiving a deletion completion action, proving a second confirm tap cannot start another request.

- [ ] **Step 5: Run the My Page reducer suite**

Run:

```bash
xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:FiilsaTests/MyPageFeatureTests
```

Expected: all My Page reducer tests pass.

- [ ] **Step 6: Commit the reducer and reducer tests**

```bash
git add Fiilsa/Presentation/MyPage/MyPageFeature.swift FiilsaTests/MyPageFeatureTests.swift
git commit -m "feat: move account deletion flow to my page"
```

---

### Task 2: Render the Figma bottom menu and My Page confirmation UI

**Files:**
- Modify: `Fiilsa/Presentation/MyPage/MyPageBottomButtonSection.swift`
- Create: `Fiilsa/Presentation/MyPage/MyPageResignDialog.swift`
- Modify: `Fiilsa/Presentation/MyPage/MyPageView.swift`
- Modify: `Fiilsa/Presentation/MyPage/MyPageAccessibilityIdentifier.swift`

**Interfaces:**
- Consumes: `isLogged`, `isProcessing`, `isResignDialogPresented`, `toastMessage`, and the Task 1 actions.
- Produces: row callbacks that send `.logoutTapped`, `.resignTapped`, `.resignConfirmed`, `.resignDialogDismissed`, and `.toastDismissed`.

- [ ] **Step 1: Add stable accessibility identifiers before writing the UI**

Add identifiers with these exact values:

```swift
static let logout = "myPage.logout"
static let version = "myPage.version"
static let resign = "myPage.resign"
static let resignDialog = "myPage.resignDialog"
static let resignConfirm = "myPage.resign.confirm"
static let resignCancel = "myPage.resign.cancel"
static let resignToast = "myPage.resignToast"
```

- [ ] **Step 2: Restructure `MyPageBottomButtonSection` to match Figma node `2929:11031`**

Change the initializer to accept a `resign` callback alongside `logout`. Render the rows in this exact order when logged in:

```swift
if isLogged { logoutRow }
versionRow
if isLogged { resignRow }
```

Each row is 50pt high inside the existing horizontal 12pt inset. Keep the logout chevron. Keep version text on the trailing edge. The delete row has no icon and no chevron, uses `FillsaTypography.body2`, `FillsaColor.gray500`, and calls `resign` across the entire row. Disable both destructive and logout controls while `isProcessing` is true. Preserve the guest behavior of showing only version.

- [ ] **Step 3: Create `MyPageResignDialog` from the existing deletion modal**

Move the visual modal from `AlertView.resignDialog` into this new view with this interface:

```swift
struct MyPageResignDialog: View {
    let confirm: () -> Void
    let dismiss: () -> Void
    let isProcessing: Bool
}
```

Keep the existing Korean copy, `312pt` maximum dialog width, `8pt` corner radius, dimmed dismissible backdrop, `탈퇴하기` then `취소` button order, and divider treatment. Attach the Task 2 identifiers to the dialog and its two buttons. Disable confirm while processing.

- [ ] **Step 4: Wire the new row, modal, and failure toast into `MyPageView`**

Pass `isProcessing` and `resign: { viewStore.send(.resignTapped) }` to the bottom section. In the root `ZStack`, show `MyPageResignDialog` when `isResignDialogPresented` is true. Render the existing capsule toast style for `toastMessage`, assign `myPage.resignToast`, and dismiss it after 1.6 seconds by sending `.toastDismissed`. Do not add a success toast: successful deletion immediately transitions to Home as in the existing flow.

- [ ] **Step 5: Build the app and inspect the signed-in visual state**

Run:

```bash
xcodebuild build -project Fiilsa.xcodeproj -scheme Fiilsa \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: build succeeds. In the signed-in test state, verify the Figma order, 50pt rows, grey `회원탈퇴` label, and absence of a chevron on that row. In guest state, verify both logged-in-only rows are absent.

- [ ] **Step 6: Commit the visual My Page change**

```bash
git add Fiilsa/Presentation/MyPage/MyPageBottomButtonSection.swift \
  Fiilsa/Presentation/MyPage/MyPageResignDialog.swift \
  Fiilsa/Presentation/MyPage/MyPageView.swift \
  Fiilsa/Presentation/MyPage/MyPageAccessibilityIdentifier.swift
git commit -m "feat: expose account deletion on my page"
```

---

### Task 3: Remove deletion ownership from the notification feature and update root routing

**Files:**
- Modify: `Fiilsa/Presentation/MyPageSub/AlertFeature.swift`
- Modify: `Fiilsa/Presentation/MyPageSub/AlertView.swift`
- Modify: `Fiilsa/App/AppFeature.swift`
- Create: `FiilsaTests/AlertFeatureTests.swift`

**Interfaces:**
- Consumes: `MyPageFeature.Action.delegate(.resignCompleted)`.
- Produces: a notification-only `AlertFeature` and a logged-out reset of `AppFeature.State` after deletion succeeds.

- [ ] **Step 1: Write a notification-only reducer test**

Create `AlertFeatureTests.swift` with a test that loads an alarm state without any login or deletion state:

```swift
@MainActor
final class AlertFeatureTests: XCTestCase {
    func test_loadedStoresOnlyAlarmState() async {
        let store = TestStore(initialState: AlertFeature.State()) {
            AlertFeature()
        }
        await store.send(.loaded(alarm: true)) {
            $0.isAlarmOn = true
        }
    }
}
```

- [ ] **Step 2: Run the test and confirm it fails against the old `loaded(alarm:isLoggedIn:)` contract**

Run:

```bash
xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:FiilsaTests/AlertFeatureTests/test_loadedStoresOnlyAlarmState
```

Expected: compilation failure because the existing action still requires `isLoggedIn`.

- [ ] **Step 3: Simplify `AlertFeature` and `AlertView`**

Remove `isLoggedIn`, deletion dialog and toast state, all `resign*` / `toastDismissed` actions, `AlertError`, `commonClient`, and `sessionClient`. Change loading to `.loaded(alarm: Bool)`. Keep notification permission, alarm persistence, push registration, and back delegate behavior unchanged. Remove the conditional resignation button, modal, toast, and their helper views from `AlertView`.

- [ ] **Step 4: Update `AppFeature` to handle the new My Page success delegate**

Replace the old `.alert(.delegate(.resignCompleted))` branch with `.myPage(.delegate(.resignCompleted))`. Preserve the reset behavior exactly: set `screen = .main`, select `.home`, recreate Home/QuoteList/Calendar/MyPage/Alert state, and retain `selectedTheme` when recreating `MyPageFeature.State`.

- [ ] **Step 5: Run focused tests and the complete unit-test target**

Run:

```bash
xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:FiilsaTests/AlertFeatureTests \
  -only-testing:FiilsaTests/MyPageFeatureTests

xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:FiilsaTests
```

Expected: all targeted and complete unit tests pass.

- [ ] **Step 6: Commit the notification cleanup and root routing**

```bash
git add Fiilsa/Presentation/MyPageSub/AlertFeature.swift \
  Fiilsa/Presentation/MyPageSub/AlertView.swift \
  Fiilsa/App/AppFeature.swift \
  FiilsaTests/AlertFeatureTests.swift
git commit -m "refactor: keep account deletion in my page"
```

---

### Task 4: Update product documentation and perform release verification

**Files:**
- Modify: `docs/screens/5_mypage.md`
- Modify: `docs/screens/5_2_inform.md`
- Modify: `docs/unfinished-features.md`

**Interfaces:**
- Consumes: the completed UI and reducer behavior from Tasks 1–3.
- Produces: an accurate App Review / QA navigation record for account deletion.

- [ ] **Step 1: Update the My Page screen plan**

In `docs/screens/5_mypage.md`, add the member-only `로그아웃 → 버전 → 회원탈퇴` order; state that deletion is directly visible without opening 알림; record the Figma node ID; and document the existing confirmation/API/success navigation.

- [ ] **Step 2: Remove stale deletion requirements from the notification plan**

In `docs/screens/5_2_inform.md`, remove the `회원 전용 — 탈퇴하기` and withdrawal API sections. Keep only notification toggling, local notification, and push-device-registration behavior.

- [ ] **Step 3: Correct the unfinished-feature status**

In `docs/unfinished-features.md`, change the P1 account-deletion entry from the old notification-screen ownership to `마이페이지에서 구현 완료, 실기기/서버 삭제 QA 및 App Review 녹화 대기`. Replace its checklist with the direct My Page path.

- [ ] **Step 4: Build a Release app for the physical QA device**

Run:

```bash
xcodebuild build -project Fiilsa.xcodeproj -scheme Fiilsa -configuration Release \
  -destination 'platform=iOS,id=00008130-0012794E2140001C' \
  -derivedDataPath /tmp/fiilsa-account-deletion-release
```

Expected: `** BUILD SUCCEEDED **` and the app is signed for the attached device.

- [ ] **Step 5: Complete physical-device QA with a disposable account**

Record this exact sequence for App Review Notes:

1. Sign in using an account created only for this test.
2. Open `My page`.
3. Show the directly visible `회원탈퇴` row below `버전`.
4. Tap it, show the confirmation modal, and tap `탈퇴하기`.
5. Show Home after local logout and verify My Page no longer shows `로그아웃` or `회원탈퇴`.

Do not use a production personal account because deletion is irreversible.

- [ ] **Step 6: Commit documentation only after QA evidence is recorded**

```bash
git add docs/screens/5_mypage.md docs/screens/5_2_inform.md docs/unfinished-features.md
git commit -m "docs: document my page account deletion flow"
```

---

## Final Verification Checklist

- [ ] `git diff --check` returns no output.
- [ ] My Page reducer success, cancellation, duplicate-tap, and failure paths pass.
- [ ] Notification reducer tests pass with no account-deletion state.
- [ ] Full `FiilsaTests` target passes.
- [ ] Debug and Release builds succeed.
- [ ] Physical-device recording proves account creation/sign-in, direct deletion discovery, confirmation, server deletion, and logged-out result.
- [ ] The App Review Notes describe `My Page → 회원탈퇴` and include the recording.

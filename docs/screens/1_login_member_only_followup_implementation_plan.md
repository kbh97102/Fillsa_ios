# iOS 회원 전용 화면 진입과 세션 종료 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 로그인 성공 전과 세션 종료 후에는 로그인 화면만 열고, 수동 로그아웃·세션 만료·회원 탈퇴가 같은 회원 화면 정리 규칙을 사용한다.

**Architecture:** `AppFeature`의 인증 진입 상태가 회원 화면 이동의 문지기다. `LoginFeature`와 `MyPageFeature`는 결과 이벤트만 올리고, 루트 reducer가 화면을 전환한다. 만료 이벤트는 실패한 요청의 토큰 지문과 현재 토큰을 비교해 이전 세션의 늦은 응답이 새 로그인을 종료하지 못하게 한다.

**Tech Stack:** Swift, SwiftUI, TCA, Keychain, UserDefaults, Alamofire, CryptoKit, XCTest, XCUITest.

**Spec:** [로그인 화면의 2차 목표](1_login.md), [My Page의 탈퇴 목표](5_mypage.md), [세션 만료 흐름](../session-expiration-flow.md), [스플래시](0_onboarding.md), [온보딩 가이드](0_onboarding_guide.md).

**Next plan:** 회원 화면 진입을 닫은 뒤 [비회원 분기 정리](1_login_guest_cleanup_implementation_plan.md)를 실행한다.

## Global Constraints

- `Home`, `Calendar`, `List`, `My Page`, 필사와 메모 화면은 확인된 회원 세션에서만 접근한다. 첫 실행 기록이나 화면의 `isLoggedIn` 표시값으로 인증을 대신하지 않는다.
- 사용자 지시에 따라 회원 전용 화면 이동은 Figma 대조 없이 진행한다. 현재 회원 화면의 문구와 레이아웃은 변경하지 않는다.
- 탈퇴 API 실패 또는 삭제 전 취소는 My Page에 남는다. API 성공 또는 이미 탈퇴된 계정은 로컬 정리 오류가 나도 로그인 화면으로 이동한다.
- 이 계획에서는 로그인 성공 후 Home 이동을 유지한다. 기존 로그인 코드의 로컬 필사 읽기·전송·삭제는 [다음 계획](1_login_guest_cleanup_implementation_plan.md)의 첫 작업에서 제거한다.
- UI 테스트 전 기존 `HomeUITests.testStreakTooltipArrowIsAnchoredToStatusButton`의 독립적인 좌표 실패가 기록돼 있다. 전체 테스트 결과에서는 이 항목을 분리해 보고한다.

## File Map

| 파일 | 책임 |
|---|---|
| `Fiilsa/App/AppFeature.swift`, `Fiilsa/App/AppRoute.swift`, `Fiilsa/App/AppView.swift` | 회원 접근 상태, 공통 로그인 이동, 모든 회원 화면 경로 검사 |
| `Fiilsa/Presentation/Login/LoginFeature.swift`, `Fiilsa/Presentation/Login/LoginView.swift`, `Fiilsa/Presentation/Splash/SplashFeature.swift` | 닫기·비회원 진입 액션 제거와 단일 로그인 목적지 |
| `Fiilsa/Presentation/MyPage/MyPageFeature.swift` | 탈퇴 서버 결과와 로컬 정리 결과 구분 |
| `Fiilsa/Data/API/SessionExpirationEvent.swift`, `Fiilsa/Data/API/FillsaRequestInterceptor.swift`, `Fiilsa/Core/Dependencies/SessionExpirationClient.swift` | 실패한 세션 식별값을 만료 이벤트와 함께 전달 |
| `Fiilsa/FiilsaApp.swift` | 인증된 회원 화면 UI fixture와 로그아웃된 fixture 구분 |
| `FiilsaTests/AppFeatureTests.swift`, `FiilsaTests/MyPageFeatureTests.swift`, `FiilsaTests/LoginFeatureTests.swift`, `FiilsaTests/SessionExpirationTests.swift` | reducer 분기·중복 이벤트·탈퇴 경계 검증 |
| `FiilsaUITests/LoginDarkModeUITests.swift`, `FiilsaUITests/MyPageUITests.swift`, `FiilsaUITests/OnboardingGuideUITests.swift` | 로그인 화면·탈퇴 후 진입의 화면 검증 |

## Review Focus

1. 로그아웃 직후 이전 화면의 늦은 액션이 도착하면 Home이 다시 열리거나 회원 데이터가 다시 쌓이는가? Task 1의 차단 상태 테스트.
2. 첫 실행이든 재실행이든 미로그인 사용자가 X·가이드 종료 액션으로 Home에 들어가는가? Task 2의 경로 테스트.
3. 이전 세션의 401이 새 로그인 뒤 늦게 도착하면 새 토큰이 삭제되는가? Task 3의 토큰 지문 테스트.
4. 토큰 삭제가 실패하거나 만료 이벤트가 연속 도착하면 로그인 화면과 로그아웃 차단 기록이 유지되는가? Task 3의 오류·중복 테스트.
5. 서버 탈퇴가 확정된 뒤 로컬 정리 오류·취소가 발생하면 회원 화면에 남는가? Task 4의 탈퇴 완료 테스트.

---

### Task 1: 루트에서 회원 화면 진입을 한곳으로 제한

**Files:** `AppFeature.swift`, `FiilsaApp.swift`; test `AppFeatureTests.swift`.

**Interfaces:** `AppFeature.State.MemberAccess` = `.unknown`, `.member`, `.loginRequired`; `State.memberAccess`의 초깃값은 `.unknown`. `State.routeToLoginAndClearMemberState()`는 수동 로그아웃에서 이미 초기화하는 `login`, `home`, `quoteList`, `calendar`, `myPage`, `notice`, `alert`, `memoInsert`, `typing`, `share`, `generalPopup`, `selectedTab`을 초기화하고 테마를 유지한다. `AppFeature.Action.memberAccessLost`는 화면 내부에서 인증 소실을 감지했을 때 로그아웃을 요청한다. `.main` 및 회원 전용 세부 화면 경로는 `.member`에서만 허용한다.

- [ ] **Step 1 — 실패 테스트:** `AppFeatureTests`에 스플래시 미로그인 결과→`.loginRequired`, 로그인 성공→`.member`, 수동 로그아웃→로그인 및 민감 상태 초기화, `memberAccessLost`→로컬 로그아웃 뒤 로그인, 로그아웃 뒤 늦은 `notice.back`·`myPage.homeSelected`·탭 선택→로그인 유지, 늦은 Home 응답→회원 데이터 미복원 검사를 작성한다.
- [ ] **Step 2 — 실패 확인:** `xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,name=iPhone 17e,OS=26.4' -only-testing:FiilsaTests/AppFeatureTests`에서 새 검사만 기대한 이유로 실패하는지 확인한다.
- [ ] **Step 3 — 구현:** 기존 수동 로그아웃 초기화를 `routeToLoginAndClearMemberState()`로 옮긴다. 스플래시 Home과 로그인 성공에만 `.member`를 설정하고, 스플래시 로그인·세션 종료에는 `.loginRequired`를 설정한다. `memberAccessLost`는 `SessionClient.logout()`의 성공·오류 모두 로그인으로 이동한다. `AppFeature`의 `.main` 및 회원 세부 화면 진입 위치를 감사하고, 차단 상태에서 도착한 회원 feature 액션이 scoped reducer를 거쳐도 화면과 민감 상태를 다시 채우지 못하게 한다. 직접 회원 화면으로 시작하는 UI fixture에는 `.member`를 명시한다.
- [ ] **Step 4 — 통과 확인:** Task 1 테스트와 기존 `MyPageFeatureTests`, `SplashFeatureTests`, `MyPageUITests.test_memberLogoutOpensLogin`을 실행한다.
- [ ] **Step 5 — 커밋:** 루트 경로·fixture·테스트만 검토해 별도 커밋한다.

### Task 2: 로그인 닫기와 비회원 시작의 우회 경로 제거

**Files:** `LoginFeature.swift`, `LoginView.swift`, `SplashFeature.swift`, `AppRoute.swift`, `AppFeature.swift`, `AppView.swift`, `FiilsaApp.swift`; tests `LoginFeatureTests.swift`, `AppFeatureTests.swift`, `LoginDarkModeUITests.swift`, `OnboardingGuideUITests.swift`.

**Interfaces:** `AppScreen.login`과 `SplashDestination.login`은 목적지만 나타내고 `isOnboarding` 인자를 갖지 않는다. `LoginFeature.State`의 `isOnboarding`, `Action.nonMemberTapped`·`closeTapped`, `Delegate.close`·`moveOnboardingGuide`, `AppFeature.Action.loginClosed`·`loginNonMemberSelected`는 제거한다. `onboardingGuideFinished`는 UI 테스트 fixture를 위해 남기되 Task 1의 `.memberAccess == .member`일 때만 Home으로 이동한다.

- [ ] **Step 1 — 실패 테스트:** 미로그인 가이드 fixture에서 건너뛰기·마지막 버튼을 눌러도 로그인으로 돌아오는 UI 테스트와, `onboardingGuideFinished`를 직접 보낸 미로그인 reducer 테스트를 작성한다. 회원의 정상 로그인 성공은 Home으로 가는 기존 테스트를 유지한다.
- [ ] **Step 2 — 실패 확인:** 새 `AppFeatureTests`와 `OnboardingGuideUITests`를 실행해 현재 가이드 종료가 비회원 Home으로 이동하는 실패를 확인한다.
- [ ] **Step 3 — 구현:** 표시되지 않는 X의 `topSection`과 액션, 비회원 시작 액션 및 delegate, 비회원에서 가이드로 가는 루트 액션을 제거한다. `isOnboarding` 인자와 모든 생성 호출·fixture를 갱신한다. 가이드 화면 자체와 디자인 자산은 기존 UI 테스트 fixture에 보존한다.
- [ ] **Step 4 — 통과 확인:** `LoginFeatureTests`, `AppFeatureTests`, `LoginDarkModeUITests`, `OnboardingGuideUITests`를 실행하고 `rg -n 'nonMemberTapped|loginNonMemberSelected|loginClosed|moveOnboardingGuide|closeTapped' Fiilsa` 결과가 비었는지 확인한다.
- [ ] **Step 5 — 커밋:** UI에서 보이던 회원 버튼·문구의 위치가 바뀌지 않았는지 런타임 캡처로 확인하고 별도 커밋한다.

### Task 3: 세션 만료와 이전 요청의 지연 이벤트 처리

**Files:** `AppFeature.swift`, `SessionExpirationEvent.swift`, `FillsaRequestInterceptor.swift`, `SessionExpirationClient.swift`, `docs/session-expiration-flow.md`; create or extend `SessionExpirationTests.swift`, `AppFeatureTests.swift`.

**Interfaces:** `SessionExpirationEvent.failedAccessTokenFingerprint: String?`는 실패한 요청의 Bearer 토큰 SHA-256 지문이다. 인터셉터가 이벤트 생성 시 넣고 `NotificationCenter` 브리지에서 보존한다. `AppFeature`는 `sessionClient.getAccessToken()`의 현재 지문과 비교한다. 다른 지문이거나 이벤트 지문은 없는데 새 토큰이 있으면 이전 세션 이벤트로 무시한다. 같은 지문이거나 현재 토큰 조회에 실패하면 기존 `sessionClient.logout()`을 실행하고 Task 1의 공통 로그인 이동을 사용한다. `.unknown`·`.loginRequired` 상태에서는 만료 이벤트를 무시한다.

- [ ] **Step 1 — 실패 테스트:** 동일 토큰의 만료는 로그인으로 이동, 토큰 정리 오류에도 로그인 유지, 처리 중 중복 이벤트는 로그아웃 한 번, 현재 토큰이 바뀐 뒤 이전 이벤트는 새 토큰 보존, 로그인 화면에서 도착한 이벤트는 무시, 인터셉터→이벤트 브리지에서 지문 보존을 검증한다.
- [ ] **Step 2 — 실패 확인:** `SessionExpirationTests`와 새 `AppFeatureTests`를 실행해 비회원 Home 이동 및 지연 이벤트 처리의 실패를 확인한다.
- [ ] **Step 3 — 구현:** 요청의 Authorization 값에서 토큰을 추출해 원문을 기록하거나 이벤트에 실어 보내지 않고 지문만 전달한다. `AppFeature`는 현재 토큰과 비교한 뒤 유효한 만료만 처리한다. 만료 정리가 끝나면 성공·오류 모두 `routeToLoginAndClearMemberState()`를 호출하고 처리 플래그를 해제한다.
- [ ] **Step 4 — 통과 확인:** 관련 reducer·인터셉터 테스트와 로그인 재시도 테스트를 실행한다. 시뮬레이터에서 만료 fixture를 사용해 회원 화면→로그인 화면 캡처를 QA 기록에 남긴다.
- [ ] **Step 5 — 커밋:** `docs/session-expiration-flow.md`의 현재 흐름을 갱신하고 별도 커밋한다.

### Task 4: 회원 탈퇴 완료를 로그인 화면으로 연결

**Files:** `MyPageFeature.swift`, `AppFeature.swift`, `docs/screens/5_mypage.md`; tests `MyPageFeatureTests.swift`, `AppFeatureTests.swift`, `MyPageUITests.swift`.

**Interfaces:** `MyPageFeature.Action.Delegate.resignCompleted`는 서버 삭제 성공 또는 이미 탈퇴된 계정을 확정한 뒤에만 발생한다. 이 이벤트를 받은 `AppFeature`는 Task 1의 `routeToLoginAndClearMemberState()`를 사용한다. 서버 삭제 실패·삭제 전 취소는 현재 My Page와 회원 상태를 유지한다.

- [ ] **Step 1 — 실패 테스트:** 일반 탈퇴 성공, 이미 탈퇴된 계정, 서버 성공 후 로컬 로그아웃 오류·취소에서 로그인으로 이동하는 테스트를 작성한다. 서버 오류와 삭제 전 취소는 My Page에 남고 토큰을 보존하는 테스트를 추가한다.
- [ ] **Step 2 — 실패 확인:** `MyPageFeatureTests`와 `AppFeatureTests`를 실행해 성공 후 비회원 Home 이동 및 정리 취소 문제를 확인한다.
- [ ] **Step 3 — 구현:** 서버 삭제가 확정된 뒤에는 로컬 정리의 결과를 실패로 되돌리지 않고 `resignCompleted`를 반드시 전달한다. 필요하면 서버 확정 액션과 로컬 정리 액션을 나눠 취소 경계를 명확히 한다. 루트에서는 공통 로그인 이동을 사용한다.
- [ ] **Step 4 — 통과 확인:** 관련 단위 테스트와 회원 My Page UI fixture의 탈퇴 확인→로그인 화면 테스트를 실행한다. 카카오·Apple 버튼 표시 및 My Page 소멸 캡처를 QA 기록에 남긴다.
- [ ] **Step 5 — 커밋:** `5_mypage.md`의 실제 결과를 갱신하고 별도 커밋한다.

### Task 5: 회원 화면 접근 전수 점검

**Files:** `AppFeatureTests.swift`, affected UI tests, `docs/screens/1_login.md`; create `docs/screens/1_login_member_only_followup_qa_<date>.md`.

**Interfaces:** 앱의 `.main`, `.typing`, `.memoInsert`, `.quoteDetail`, `.notice`, `.alert` 진입은 Task 1의 회원 접근 상태를 따른다. Figma 회원 화면의 표시 상태는 그대로 둔다.

- [ ] **Step 1 — 테스트:** 미로그인 첫 실행·재실행, 정상 로그인, 수동 로그아웃, 만료, 탈퇴, 늦은 화면 액션의 경로 매트릭스를 단위/UI 테스트로 고정한다.
- [ ] **Step 2 — 경로 감사:** `rg -n 'state.screen = \.main|state.screen = \.typing|state.screen = \.memoInsert|state.screen = \.quoteDetail|state.screen = \.notice|state.screen = \.alert' Fiilsa/App`의 각 경로가 회원 접근 검사에 포함되는지 확인한다.
- [ ] **Step 3 — 검증:** 변경 대상 테스트를 실행한 뒤 전체 `xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,name=iPhone 17e,OS=26.4'`를 실행한다. 기존 홈 툴팁 좌표 실패와 새 실패를 구분한다.
- [ ] **Step 4 — 기록:** QA 문서에 목적지별 테스트 결과, 로그인 화면 캡처, Figma 생략 근거, 남은 비회원 내부 분기와 다음 계획 링크를 남긴다.
- [ ] **Step 5 — 커밋:** 코드·테스트·화면 계획을 검토해 이 단계만 커밋한다.

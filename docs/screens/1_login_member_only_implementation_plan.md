# iOS 회원 전용 시작 및 로그아웃 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 로그아웃 직후와 미로그인 상태의 앱 재시작에서 로그인 화면을 보여주고, 유효한 회원 세션에서만 Home에 진입한다.

**Architecture:** `SplashFeature`가 첫 실행 여부와 세션 상태를 읽어 목적지를 정한다. `MyPageFeature`는 로그아웃 완료를 delegate action으로 `AppFeature`에 전달하고, 화면 전환은 앱 reducer 한곳에서 수행한다. 로그아웃 시 영속적인 차단 표시를 먼저 기록해 Keychain 삭제 오류가 나도 재시작 시 Home에 진입하지 않게 한다.

**Tech Stack:** Swift, TCA, SwiftUI, Keychain, UserDefaults, XCTest, XCUITest.

**Spec:** [스플래시](0_onboarding.md), [로그인](1_login.md), [My Page](5_mypage.md).

**QA:** [2026-10-09 실행 기록 및 화면 캡처](1_login_member_only_qa_2026-10-09.md).

## Global Constraints

- iOS는 로그인한 회원만 Home에 진입한다. 첫 실행 여부는 인증 여부를 대신하지 않는다.
- 로그아웃 후에는 항상 로그인 화면으로 이동한다. 기존 비회원 My Page를 목적지로 사용하지 않는다.
- 현재 앱 진입에 쓰는 `.login(isOnboarding: false)`를 사용한다. 첫 진입 전용 UI를 새로 만들지 않는다.
- 사용자가 2026-10-09에 이번 회원 전용 화면 이동 변경도 Figma 없이 진행하도록 명시적으로 요청했다. 이번 범위의 내비게이션은 동작 테스트와 시뮬레이터 실행으로 검증하며, Figma 시각 일치 판정은 하지 않는다.

## File Map

| 파일 | 책임 |
|---|---|
| `Fiilsa/Data/Local/UserDefaultsLocalSettingsStore.swift` | 로그아웃 의사 영속화 |
| `Fiilsa/Domain/Repositories/LocalRepository.swift`, `Fiilsa/Data/Repositories/DefaultLocalRepository.swift` | 차단 표시를 세션 판정에 반영 |
| `Fiilsa/Domain/UseCases/Common/SessionUseCases.swift`, `Fiilsa/Core/Dependencies/AuthUseCasesDependency.swift` | 로그아웃 전에 표시 설정, 정상 로그인 후 해제 |
| `Fiilsa/Presentation/Splash/SplashFeature.swift` | 시작 시 첫 실행 및 로그인 상태 분기 |
| `Fiilsa/Presentation/MyPage/MyPageFeature.swift`, `Fiilsa/Presentation/MyPage/MyPageBottomButtonSection.swift`, `Fiilsa/App/AppFeature.swift` | 로그아웃 완료 이벤트, 버튼 행 터치 영역, 로그인 화면 이동 |
| `FiilsaTests/SessionPersistenceTests.swift`, `FiilsaTests/SplashFeatureTests.swift`, `FiilsaTests/MyPageFeatureTests.swift`, `FiilsaTests/AppFeatureTests.swift`, `FiilsaUITests/MyPageUITests.swift` | 세션·분기·내비게이션 검증 |

## Review Focus

1. Keychain 삭제가 실패하고 토큰이 남아도 재실행 시 Home이 열리지 않는가? Task 1의 영속성 테스트.
2. 새 로그인에 성공하면 로그아웃 차단 표시가 해제되는가? Task 1의 로그인 테스트.
3. 로그인 상태 조회가 실패해도 Home이 열리지 않는가? Task 2의 오류 테스트.
4. 권한 확인과 애니메이션 완료 이벤트가 근접해도 목적지를 한 번만 결정하는가? Task 2의 중복 이벤트 테스트.
5. 로그아웃 뒤 이전 회원의 화면 데이터가 앱 상태에 남지 않는가? Task 3의 앱 reducer 테스트.

---

### Task 1: 로그아웃 상태를 재시작 후에도 안전하게 판정

**Files:** `UserDefaultsLocalSettingsStore.swift`, `LocalRepository.swift`, `DefaultLocalRepository.swift`, `SessionUseCases.swift`, `AuthUseCasesDependency.swift`; create `FiilsaTests/SessionPersistenceTests.swift`.

**Interfaces:** `UserDefaultsLocalSettingsStore.setLogoutRequested(_:)` / `isLogoutRequested()`, `LocalRepository.setLogoutRequested(_:) async throws`. `DefaultLocalRepository.isLoggedIn()`은 차단 표시가 있으면 토큰 값과 관계없이 `false`를 반환한다.

- [x] **Step 1:** 격리된 UserDefaults suite·Keychain service·임시 SQLite 경로를 쓰는 테스트를 작성한다. 유효한 두 토큰이 있는 상태에서 로그아웃 표시를 설정한 뒤 저장소를 새로 만들어도 `isLoggedIn() == false`인지 확인한다. 가짜 `AuthRepository`로 `LoginUseCase.callAsFunction(user:)`을 실행한 뒤에는 `isLoggedIn() == true`인지 확인한다.
- [x] **Step 2:** `xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,name=iPhone 17e,OS=26.4' -only-testing:FiilsaTests/SessionPersistenceTests`를 실행해 두 검사가 기대한 이유로 실패하는지 확인한다.
- [x] **Step 3:** `LogoutUseCase.callAsFunction()`에서 Keychain 삭제 **전에** 차단 표시를 기록하고, `LoginUseCase`를 테스트할 수 있는 모듈 내부 범위로 두어 `callAsFunction(user:)`에서 토큰과 회원 정보 저장이 끝난 **후** 표시를 해제한다. `DefaultLocalRepository.isLoggedIn()`에 표시 검사를 추가한다.
- [x] **Step 4:** 같은 테스트를 다시 실행해 통과를 확인하고, `FiilsaTests/LoginFeatureTests`도 실행한다.
- [x] **Step 5:** 이 작업의 코드와 테스트만 검토해 별도 커밋한다.

### Task 2: 스플래시에서 첫 실행 여부와 로그인 여부를 함께 확인

**Files:** `Fiilsa/Presentation/Splash/SplashFeature.swift`; create `FiilsaTests/SplashFeatureTests.swift`.

**Interfaces:** 기존 `SessionClient.isFirstOpen()`과 `SessionClient.isLoggedIn()`을 사용한다. 비로그인 또는 로그인 상태 조회 오류는 `.ready(.login(isOnboarding: false))`, 로그인은 `.ready(.home)`를 보낸다.

- [x] **Step 1:** 첫 실행 × 로그인 상태의 네 조합을 테스트로 작성한다. 첫 실행일 때 `setFirstOpen(false)`가 호출되고, 비로그인 재실행에는 Home이 선택되지 않음을 확인한다. 로그인 상태 조회 오류는 로그인으로 이동하는 테스트를 추가한다.
- [x] **Step 2:** 권한 확인과 애니메이션 완료 순서를 바꿔도 목적지 delegate가 한 번만 나오는 테스트를 추가한다. 대상 파일의 테스트를 실행해 분기 및 중복 이벤트 검사가 실패하는지 확인한다.
- [x] **Step 3:** 두 완료 액션이 공유하는 목적지 결정 로직을 한곳으로 모으고, 비동기 조회 시작 전에 중복 실행을 차단한다. 첫 실행 기록과 로그인 상태를 모두 읽되 Home 여부는 로그인 상태로만 결정한다.
- [x] **Step 4:** `xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,name=iPhone 17e,OS=26.4' -only-testing:FiilsaTests/SplashFeatureTests`로 통과를 확인한다.
- [x] **Step 5:** 이 작업의 코드와 테스트만 검토해 별도 커밋한다.

### Task 3: 로그아웃 완료를 앱 라우터에 전달

**Files:** `Fiilsa/Presentation/MyPage/MyPageFeature.swift`, `Fiilsa/App/AppFeature.swift`, `FiilsaTests/MyPageFeatureTests.swift`, `FiilsaTests/AppFeatureTests.swift`, `FiilsaUITests/MyPageUITests.swift`; `docs/screens/0_onboarding.md`, `docs/screens/1_login.md`, `docs/screens/5_mypage.md`.

**Interfaces:** `MyPageFeature.Action.Delegate.loggedOut`을 추가한다. `AppFeature`는 `.myPage(.delegate(.loggedOut))`을 받아 `.login(isOnboarding: false)`로 이동한다.

- [x] **Step 1:** 로컬 로그아웃 성공·오류 모두에서 `MyPageFeature`가 `.delegate(.loggedOut)`을 내보내는 테스트를 작성한다. `AppFeature` 테스트에는 화면이 로그인으로 바뀌고 `selectedTab`, `login`, `home`, `quoteList`, `calendar`, `myPage`, `notice`, `alert`, `memoInsert`, `typing`, `share`, `generalPopup` 상태가 초기화되는 검사를 추가한다. 선택한 테마는 유지한다.
- [x] **Step 2:** 회원 My Page UI fixture에서 로그아웃 버튼을 누른 뒤 `login.kakao`와 `login.apple`이 나타나고 `myPage.screen`이 사라지는 UI 테스트를 추가한다. 변경 전 실패를 확인한다.
- [x] **Step 3:** `loggedOut`에서 delegate를 보내고 `AppFeature`에서 로그인 상태와 Step 1에 적은 화면 상태를 초기화한다. 로그인 성공 후 기존 `.moveHome` 경로가 계속 동작하도록 한다.
- [x] **Step 4:** 관련 단위/UI 테스트를 먼저 실행하고 `xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,name=iPhone 17e,OS=26.4'`로 전체 테스트를 확인한다. 회원 My Page에서 로그아웃 후 로그인 화면으로 이동하는 런타임 캡처를 보관하고 문서에 검증 결과를 기록한다. 전체 결과는 [QA 기록](1_login_member_only_qa_2026-10-09.md)에 남긴 홈 툴팁 UI 테스트 1건 실패를 포함한다.
- [x] **Step 5:** 화면 문서의 **구현 예정** 표시를 실제 결과에 맞게 갱신하고, 코드·테스트·QA 기록을 검토한 뒤 별도 커밋한다.

## 후속 범위

이 계획은 합의된 수동 로그아웃과 스플래시 진입 분기를 구현한다. 현재 별도로 남아 있는 로그인 닫기, 세션 만료, 회원 탈퇴, 비회원 액션의 Home 진입 경로는 [로그인 화면 계획](1_login.md)에 따라 다음 결정과 계획에서 다룬다. 따라서 이 계획의 완료만으로 앱 전체의 회원 전용 경로가 모두 닫혔다고 선언하지 않는다.

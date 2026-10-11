# iOS 비회원 화면·저장 분기 정리 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 회원 화면 진입 경로를 닫은 뒤 Home·Calendar·List·Typing·My Page의 비회원 표시와 로컬 저장 분기를 제거한다. 기존 기기에 남은 비회원 필사도 서버로 동기화하지 않는다.

**Architecture:** [회원 화면 진입 계획](1_login_member_only_followup_implementation_plan.md)의 루트 인증 문지기를 먼저 완료한다. `LoginUseCase`가 기존 로컬 필사를 읽거나 지우지 않도록 바꾸고, 현재 API 요청 필드인 `syncData`에는 항상 빈 배열을 보낸다. 각 feature는 회원 API와 회원 화면 상태만 사용한다.

**Tech Stack:** Swift, TCA, SwiftUI, SQLite, XCTest, XCUITest.

**Spec:** [로그인](1_login.md), [Home](2_home.md), [Calendar](3_calendar.md), [List](4_list.md), [My Page](5_mypage.md), [필사 화면](2_home.md), [온보딩 가이드](0_onboarding_guide.md).

## Global Constraints

- 첫 계획이 완료되기 전에는 이 계획의 guest fallback을 제거하지 않는다. 먼저 화면 접근을 닫아 미로그인 사용자가 회원 API 화면에 머물지 않게 한다.
- 기존 로컬 필사는 로그인 성공·실패·취소, 로그아웃, 앱 시작 시 모두 자동 삭제하지 않는다. 로그인 요청에는 기존 데이터와 무관하게 `syncData: []`를 보낸다. 사용자가 저장했던 기기 데이터는 앱에서 접근할 경로가 없어져도 기기에 남는다.
- 회원 화면의 기존 문구, 자산, 배치, 탭 구조는 그대로 둔다. 비회원 전용 상태 제거는 2026-10-09 회원 전용 변경에 대한 사용자 Figma 생략 지시와 각 화면의 기존 회원 프레임을 기록하고 검증한다.
- 기존 기기 데이터를 보존하기 위해 DB 파일·스키마와 자동 삭제를 유발하지 않는 저장소 초기화 코드는 유지한다. 새 비회원 레코드를 읽거나 쓰는 앱 호출은 제거한다.

## File Map

| 파일 | 책임 |
|---|---|
| `Fiilsa/Core/Dependencies/AuthUseCasesDependency.swift`, `Fiilsa/Domain/Requests/AuthRequests.swift`, `FiilsaTests/SessionPersistenceTests.swift` | 로그인 시 로컬 필사 접근·전송·삭제 중단, 빈 `syncData` 계약 검증 |
| `Fiilsa/Domain/UseCases/Home/HomeUseCases.swift`, `Fiilsa/Core/Dependencies/HomeUseCasesDependency.swift`, `Fiilsa/Presentation/Home/HomeFeature.swift`, `Fiilsa/Presentation/Home/HomeView.swift` | 회원 주간·일간 명언, 좋아요, 답변만 사용 |
| `Fiilsa/Domain/UseCases/Calendar/CalendarUseCases.swift`, `Fiilsa/Presentation/Calendar/CalendarFeature.swift`, `Fiilsa/Presentation/Calendar/CalendarView.swift` | 회원 월간 응답·답변만 사용 |
| `Fiilsa/Domain/UseCases/QuoteList/QuoteListUseCases.swift`, `Fiilsa/Presentation/HomeSub/TypingFeature.swift` | 회원 목록·메모·필사 저장만 사용 |
| `Fiilsa/Presentation/MyPage/MyPageFeature.swift`, `Fiilsa/Presentation/MyPage/MyPageView.swift`, `Fiilsa/Presentation/MyPage/MyPageLoginSection.swift` | 회원 카드만 표시하고 인증 소실을 루트로 전달 |
| `Fiilsa/Data/Repositories/DefaultHomeRepository.swift`, `Fiilsa/Data/Repositories/DefaultCalendarRepository.swift`, `Fiilsa/Domain/Repositories/HomeRepository.swift`, `Fiilsa/Domain/Repositories/CalendarRepository.swift`, `Fiilsa/Data/API/APIEndpoint.swift` | 사용하지 않는 비회원 API 계약 제거 |
| `Fiilsa/Data/Local/SQLiteLocalStore.swift`, `Fiilsa/Domain/Repositories/LocalRepository.swift`, `Fiilsa/Core/Dependencies/LocalQuoteClient.swift` | 비회원 필사 호출 정리, 기존 DB 파일·스키마 보존 |
| `FiilsaTests/HomeFeatureTests.swift`, `FiilsaTests/CalendarFeatureTests.swift`, `FiilsaTests/QuoteListFeatureTests.swift`, 새 `FiilsaTests/TypingFeatureTests.swift`, `FiilsaTests/MyPageFeatureTests.swift`, `FiilsaUITests/MyPageUITests.swift` | 회원 동작·비회원 UI 부재 검증 |

## Review Focus

1. 업데이트 전에 저장된 로컬 필사가 로그인 요청에 실리거나 성공·실패 후 지워지는가? Task 1의 무전송·보존 테스트.
2. 로그아웃 뒤 늦은 Home·Calendar·Typing 결과가 로컬 필사에 쓰는가? Task 2·3·5의 무쓰기 테스트.
3. 회원 주간 응답에 선택 날짜가 없을 때 비회원 v1 API로 떨어지는가? Task 2의 v2 일간 대체 테스트.
4. 인증 조회 오류를 비회원 데이터로 성공 처리하는가? Task 2·3·4·5의 오류 테스트.
5. 비회원 카드 제거 뒤 My Page의 회원 카드·로그아웃·탈퇴 배치가 달라지는가? Task 6의 회원 fixture UI 테스트.

---

### Task 1: 로그인 시 기존 비회원 필사 동기화·삭제 중단

**Files:** `AuthUseCasesDependency.swift`, `SessionPersistenceTests.swift`; inspect `AuthRequests.swift`, `LocalRepository.swift`, `SQLiteLocalStore.swift`.

**Interfaces:** `LoginUseCase.callAsFunction(user:)`는 로컬 필사를 조회하지 않고 `LoginRequest.syncData: []`를 보낸다. 현재 요청 타입의 필수 `syncData` 필드는 유지한다. 서버 로그인 성공 후 토큰·프로필 저장과 `setLogoutRequested(false)`는 유지하되 `ClearLocalDataUseCase`를 호출하지 않는다.

- [ ] **Step 1 — 실패 테스트:** 격리된 SQLite에 이전 버전 필사·메모·좋아요를 저장한다. 로그인 성공·서버 실패·토큰 저장 실패 시 요청의 `syncData == []`, 로컬 필사 조회·삭제 호출 0회, 기존 레코드 보존을 검증한다. 정상 로그인 후 토큰·프로필 저장과 로그아웃 표시 해제도 확인한다.
- [ ] **Step 2 — 실패 확인:** `SessionPersistenceTests`를 실행해 기존 데이터 전송·삭제 때문에 새 검사가 실패하는지 확인한다.
- [ ] **Step 3 — 구현:** `LoginUseCase`에서 `GetLocalQuoteListUseCase` 호출, `DailySyncData` 매핑, `ClearLocalDataUseCase` 호출을 제거한다. 필수 요청 필드에는 항상 `syncData: []`를 전달한다. 기존 DB 파일·스키마는 유지한다.
- [ ] **Step 4 — 통과 확인:** `SessionPersistenceTests`와 `LoginFeatureTests`를 실행한다.
- [ ] **Step 5 — 커밋:** 로컬 필사 무전송·보존과 로그인 세션 저장 결과를 검토해 커밋한다.

### Task 2: Home의 비회원 피드·답변·좋아요 분기 제거

**Files:** `HomeUseCases.swift`, `HomeUseCasesDependency.swift`, `HomeFeature.swift`, `HomeView.swift`, `AppFeature.swift`, `docs/screens/2_home.md`; tests `HomeFeatureTests.swift`, `AppFeatureTests.swift`, Home UI fixture tests.

**Interfaces:** `LoadHomeFeedUseCase.callAsFunction(endDate:)`는 `MemberWeeklyQuoteResponse`만 반환한다. 선택 날짜가 주간 응답에 없으면 기존 회원 v2 일간 조회를 사용한다. `UpdateHomeLikeUseCase`는 서버 좋아요만 저장한다. `HomeFeature`의 비회원 세션 답변·로컬 완료 날짜·로그인 요구 모달은 제거한다. 회원 API의 401/403은 기존 전역 세션 만료 이벤트로 처리한다.

- [ ] **Step 1 — 실패 테스트:** 첫 주간 조회, 캐시 내 날짜 이동, 완료 날짜 표시, 누락 날짜의 회원 v2 일간 조회, 서버 답변·좋아요 성공/실패, 인증 오류 시 로컬 필사 무쓰기 검사를 작성한다. 기존 guest 피드·세션 답변 테스트의 기대값을 회원 전용 계약으로 갱신한다.
- [ ] **Step 2 — 실패 확인:** `HomeFeatureTests`와 Home use case 테스트를 실행해 현재 비회원 fallback이 새 계약과 다름을 확인한다.
- [ ] **Step 3 — 구현:** `HomeFeedResult.guest`와 v1 일간 fallback, 로컬 좋아요·답변 저장 경로, 비회원 로그인 요구 모달을 제거한다. `AppFeature`의 Home↔Calendar 비회원 답변 복원도 제거한다. 인증 실패는 성공 데이터로 바꾸지 않고 앞선 [화면 진입 계획](1_login_member_only_followup_implementation_plan.md)의 루트 로그인 상태로 이어지게 한다.
- [ ] **Step 4 — 통과 확인:** `HomeFeatureTests`, `AppFeatureTests`, Home UI fixture 테스트에서 기존 회원 날짜·이미지·답변 동작이 유지되는지 확인한다.
- [ ] **Step 5 — 커밋:** `2_home.md`에 구현 결과와 QA 링크를 남기고 커밋한다.

### Task 3: Calendar의 비회원 월간 조회·답변 분기 제거

**Files:** `CalendarUseCases.swift`, `CalendarFeature.swift`, `CalendarView.swift`, `CalendarResponses.swift`, `docs/screens/3_calendar.md`; tests `CalendarFeatureTests.swift`, Calendar UI tests.

**Interfaces:** `LoadCalendarMonthUseCase.callAsFunction(yearMonth:)`는 회원 월간 API만 사용한다. 날짜별 답변은 회원 월간 응답의 `answer`와 서버 저장 결과에서만 읽는다. 사진 액션의 인증 확인이 실패하면 로그인 요구 모달 대신 `CalendarFeature.Action.delegate(.memberAccessLost)`를 보내고 `AppFeature`가 `.memberAccessLost`로 연결한다.

- [ ] **Step 1 — 실패 테스트:** 월 이동·완료 카드·서버 답변·좋아요·이미지, 인증 오류 시 비회원 API와 로컬 DB 호출 0회를 검증한다.
- [ ] **Step 2 — 실패 확인:** `CalendarFeatureTests`와 Calendar use case 테스트를 실행해 현재 로컬 fallback이 새 계약과 다름을 확인한다.
- [ ] **Step 3 — 구현:** 비회원 월간 병합, `CalendarFeature.State.sessionAnswers`, 비회원 답변 저장·이미지 로그인 요구 모달을 제거한다. 회원 응답과 서버 오류 처리는 보존한다.
- [ ] **Step 4 — 통과 확인:** Calendar 단위·UI 테스트에서 월 이동, 완료 카드, 답변 재진입을 확인한다.
- [ ] **Step 5 — 커밋:** `3_calendar.md`의 회원 전용 경로와 QA 링크를 갱신하고 커밋한다.

### Task 4: List의 로컬 목록·메모 저장 제거

**Files:** `QuoteListUseCases.swift`, `docs/screens/4_list.md`; tests `QuoteListFeatureTests.swift`, List·메모 UI tests.

**Interfaces:** `LoadQuoteListUseCase`와 `SaveQuoteMemoUseCase`는 회원 API만 사용한다. 인증 오류는 로컬 목록·메모 저장으로 대체하지 않는다.

- [ ] **Step 1 — 실패 테스트:** 회원 목록의 기간·좋아요 필터·페이징과 메모 저장을 검증한다. 인증 오류에서 로컬 필사 조회·쓰기 0회를 확인한다.
- [ ] **Step 2 — 실패 확인:** `QuoteListFeatureTests`와 use case 테스트를 실행해 현재 로컬 fallback이 새 계약과 다름을 확인한다.
- [ ] **Step 3 — 구현:** 로컬 페이징·로컬 메모 저장 분기를 제거하고 회원 API 결과만 사용한다.
- [ ] **Step 4 — 통과 확인:** List·메모 단위/UI 테스트에서 검색 기간, 상세, 메모 재진입을 확인한다.
- [ ] **Step 5 — 커밋:** `4_list.md`의 회원 전용 경로와 QA 링크를 갱신하고 커밋한다.

### Task 5: Typing의 로컬 필사 경로 제거

**Files:** `TypingFeature.swift`; create `FiilsaTests/TypingFeatureTests.swift`; reuse typing cases in `FiilsaUITests/HomeUITests.swift`.

**Interfaces:** `TypingFeature`의 조회·저장은 `TypingClient.getTyping`·`postTyping`만 사용한다. 인증 오류는 로컬 조회·저장 성공으로 바꾸지 않는다. 인증 소실을 직접 확인한 경우 `TypingFeature.Action.delegate(.memberAccessLost)`를 보내고 `AppFeature`가 `.memberAccessLost`로 연결한다.

- [ ] **Step 1 — 실패 테스트:** 회원 필사 조회·수정·좋아요·저장과 인증 조회 오류 시 로컬 DB 호출 0회를 검증한다.
- [ ] **Step 2 — 실패 확인:** Typing feature 테스트를 실행해 현재 로컬 fallback이 새 계약과 다름을 확인한다.
- [ ] **Step 3 — 구현:** `localQuoteClient` 분기, `localTypingLoaded`, 로컬 필사 저장·삭제를 제거한다. 취소와 서버 실패는 성공으로 취급하지 않는다.
- [ ] **Step 4 — 통과 확인:** Typing 단위/UI 테스트에서 회원 기존 필사 로드·저장·뒤로가기를 확인한다.
- [ ] **Step 5 — 커밋:** 필사 화면 QA 기록과 함께 별도 커밋한다.

### Task 6: My Page의 비회원 카드 제거

**Files:** `MyPageFeature.swift`, `MyPageView.swift`, `MyPageLoginSection.swift`, `MyPageLayout.swift`, `MyPageAccessibilityIdentifier.swift`, `FiilsaApp.swift`, `docs/screens/5_mypage.md`; tests `MyPageFeatureTests.swift`, `MyPageLayoutTests.swift`, `MyPageUITests.swift`.

**Interfaces:** `MyPageFeature.onAppear`가 인증 소실을 확인하면 `MyPageFeature.Action.delegate(.memberAccessLost)`를 보내고 `AppFeature`가 `.memberAccessLost`로 연결한다. 비회원 카드와 로그인 버튼은 렌더링하지 않는다.

- [ ] **Step 1 — 실패 테스트:** 미로그인 `onAppear`→로그인 이동, 회원 카드·로그아웃·탈퇴 표시, 비회원 카드 부재를 검증한다.
- [ ] **Step 2 — 실패 확인:** `MyPageFeatureTests`와 `MyPageUITests`에서 새 검사가 기대한 이유로 실패하는지 확인한다.
- [ ] **Step 3 — 구현:** guest 카드, `loginTapped`·`loginSelected` delegate, guest 전용 레이아웃·fixture를 제거하고 인증 소실을 루트로 전달한다. 회원 카드의 문구·크기·순서는 유지한다.
- [ ] **Step 4 — 통과 확인:** My Page 단위 테스트와 회원 라이트/다크 UI fixture를 실행하고 기존 회원 캡처와 배치를 비교한다.
- [ ] **Step 5 — 커밋:** `5_mypage.md`와 QA 기록을 갱신하고 커밋한다.

### Task 7: 사용하지 않는 비회원 계약만 정리하고 전수 검증

**Files:** `DefaultHomeRepository.swift`, `DefaultCalendarRepository.swift`, `HomeRepository.swift`, `CalendarRepository.swift`, `APIEndpoint.swift`, `LocalRepository.swift`, `LocalQuoteClient.swift`, `LoginButton.swift`; tests and screen planning docs affected by deleted calls.

**Interfaces:** 회원 API만 사용한다. 비회원 필사 읽기·쓰기·삭제 호출을 제거하되 기존 DB 파일·스키마는 삭제하거나 앱 시작 시 자동 초기화하지 않는다.

- [ ] **Step 1 — 사용처 감사:** `rg -n -i 'guest|non.?member|비회원|localQuote|dailyQuoteNoToken|monthlyQuotes' Fiilsa FiilsaTests FiilsaUITests` 결과를 호출 경로별로 분류한다. 기존 DB 보존에 필요한 저장소 코드와 삭제 가능한 비회원 호출을 구분한다.
- [ ] **Step 2 — 삭제:** 비회원 v1 API, 사용하지 않는 repository 메서드·클라이언트·쓰기 use case, 로그인 연필 아이콘 분기를 호출자부터 순서대로 제거한다. `LoginUseCase`의 빈 `syncData`는 현행 서버 요청 계약을 위해 유지하고 로컬 데이터 삭제 경로를 다시 만들지 않는다.
- [ ] **Step 3 — 테스트:** 회원 로그인 전에는 Home 접근 불가, 로그인 후 회원 API만 사용, 과거 로컬 필사는 요청에 포함되지 않고 기기에 남음, 로그아웃/만료/탈퇴 뒤에는 로그인으로 복귀하는 통합 테스트를 실행한다.
- [ ] **Step 4 — 전체 검증:** `xcodebuild test -project Fiilsa.xcodeproj -scheme Fiilsa -destination 'platform=iOS Simulator,name=iPhone 17e,OS=26.4'`를 실행한다. 기존 홈 툴팁 UI 테스트 실패와 새 회귀를 분리해 QA에 기록한다.
- [ ] **Step 5 — 커밋:** 변경된 화면 계획·QA·삭제 사용처를 검토하고 커밋한다.

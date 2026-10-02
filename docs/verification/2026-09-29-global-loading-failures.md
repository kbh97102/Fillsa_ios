# 전역 로딩 검증 실패 기록

전체 앱 테스트는 생략하고 변경 관련 suite만 실행한다. 의도한 TDD RED도 예상하지 못한 실패와 구분해 보존한다.

최종 재검증: 관련 유닛 테스트 66/66 통과(`/tmp/fiilsa-loading-focused-final-02.xcresult`), 기존 Home UI 시작 테스트 1/1 통과(`/tmp/fiilsa-loading-host-ui-01.xcresult`). 아래 실패 10건은 원인과 조치·재검증 이력을 보존했으며 모두 해결됐다. 전역 스피너의 Figma 시각 QA는 URL/node-id 미확보로 별도 대기 중이다.

## F-01: 시뮬레이터 상태 조회 권한 제한

- 상태 / 분류: 해결 / 빌드·환경 문제.
- 작업 / 테스트: 사전 환경 확인, `xcrun simctl list devices booted`.
- 관측 위치 / 원인 위치: CoreSimulatorService 연결 및 `~/Library/Logs/CoreSimulator` 로그 접근 / 실행 sandbox 권한.
- 기대값 / 실제값: booted device 목록 / Operation not permitted, connection invalid, connection refused.
- 재현 명령 / 환경: 위 명령을 기본 sandbox에서 실행. macOS, 프로젝트 Fiilsa.
- 원인 / 확인 근거: 권한 승인 후 같은 명령이 성공했으므로 앱 코드 결함이 아닌 실행 환경 접근 제한.
- 오류 로그 / 화면 증거: `CoreSimulatorService connection became invalid`, `Operation not permitted`.
- 수정 내용: 프로젝트 변경 없이 시뮬레이터 접근 권한을 승인받아 재실행.
- 재검증 결과: exit 0. iPhone 17 Pro iOS 26.5 (`89410CC6-A661-4252-B810-0E54DE5FB620`) 및 iOS 26.4 기기 확인.

## F-02: 신규 로딩 인터페이스 미구현 (TDD RED)

- 상태 / 분류: 해결 / 의도한 TDD RED, 추가 테스트 코드 컴파일 문제.
- 작업 / 테스트: Task 1, LoadingClientTests 및 LoadingEffectTests.
- 관측 위치 / 원인 위치: `FiilsaTests/LoadingClientTests.swift:83`의 LoadingClient/LoadingRegistry 없음, LoadingEffectTests Probe의 private 접근 제한.
- 기대값 / 실제값: 로딩 수명 계약 검증 / 신규 타입·dependency·wrapper 미구현으로 빌드 실패(exit 65). 런타임 assertion RED는 아직 확인하지 못함.
- 재현 명령 / 환경: 계획의 focused xcodebuild 명령, iPhone 17 Pro iOS 26.5; cache는 `/tmp/fiilsa-home-responsive-derived` 재사용.
- 원인 / 확인 근거: 테스트를 구현보다 먼저 작성해 인터페이스가 없음. Probe의 `@Reducer` 생성 코드도 private 접근을 요구하므로 별도로 수정 필요.
- 오류 로그 / xcresult: `/tmp/fiilsa-loading-red-01.log`, `/tmp/fiilsa-loading-red-01.xcresult`.
- 수정 내용: 승인된 인터페이스 구현, 테스트 Probe private 제한 제거.
- 재검증: `/tmp/fiilsa-loading-green-02.xcresult`의 관련 테스트 7/7 통과, 실패 0. 온전한 패키지 캐시로 실행.

## F-03: `/tmp` Swift 패키지 checkout 손실

- 상태 / 분류: 해결 / 빌드·환경 문제.
- 작업 / 테스트: Task 1 GREEN 실행, LoadingClientTests 및 LoadingEffectTests.
- 관측 위치 / 원인 위치: `/tmp/fiilsa-firebase-packages/checkouts/*/Package.swift` 누락 / 해당 checkout 경로.
- 기대값 / 실제값: 컴파일 후 테스트 / 패키지 manifest 접근 실패로 exit 74.
- 재현 명령 / 환경: focused xcodebuild 명령에 `-clonedSourcePackagesDirPath /tmp/fiilsa-firebase-packages`를 지정. Xcode 26.6, iOS 26.5 시뮬레이터.
- 원인 / 확인 근거: checkout 디렉터리는 있지만 `swift-composable-architecture/Package.swift` 등 실제 manifest가 없음을 `ls`로 확인. 별도 DerivedData의 Fiilsa SourcePackages에는 파일이 존재함.
- 오류 로그 / xcresult: `/tmp/fiilsa-loading-green-01.log`; 패키지 해석 실패라 xcresult 생성 전 종료.
- 수정 내용: 프로젝트/패키지 파일을 수정하지 않고 온전한 기존 DerivedData SourcePackages를 사용해 재시도.
- 재검증 명령 / 결과: `/tmp/fiilsa-loading-green-02.log`, xcresult 관련 테스트 7/7 통과, 실패 0.

## F-04: App 로딩 상태 연결 전 컴파일 실패 (TDD RED)

- 상태 / 분류: 해결 / 의도한 TDD RED와 테스트 코드 오류.
- 작업 / 테스트: Task 2, AppFeatureTests.
- 관측 위치 / 원인 위치: `FiilsaTests/AppFeatureTests.swift:11–46` / AppFeature.State에 표시 상태 및 Action 없음. 테스트 43행의 `XCTAssertEqual` autoclosure에서 async 호출한 것도 별도 테스트 오류.
- 기대값 / 실제값: 0/2/1/0에 따라 false/true/true/false / 해당 상태·Action 부재로 exit 65.
- 재현 명령 / 환경: `/tmp/fiilsa-app-red-01.log`의 focused xcodebuild, iOS 26.5.
- 원인 / 확인 근거: 컴파일 오류가 누락된 인터페이스 및 XCTest autoclosure 위치를 명시.
- 오류 로그 / xcresult: `/tmp/fiilsa-app-red-01.log`, `/tmp/fiilsa-app-red-01.xcresult`.
- 수정 내용: AppFeature의 count 구독·상태·Action 추가, async 값을 assertion 전에 지역 변수로 읽도록 테스트 수정.
- 재검증: `/tmp/fiilsa-app-green-06.xcresult`의 App·Loading 관련 13/13 통과, 실패 0. 중간의 취소 ID 컴파일 실패 원인은 아래 추가 발견에 보존.

### 재검증 중 추가 발견

첫 GREEN 시도(`/tmp/fiilsa-app-green-01.log`)는 `AppFeature.swift:130`의 cancellable ID에 Hashable이 아닌 enum 메타타입을 넘겨 컴파일 실패했다. token 값으로 수정했지만 두 번째 시도(`/tmp/fiilsa-app-green-02.log`)에서는 프로젝트의 기본 MainActor 격리 때문에 enum의 Hashable conformance가 Sendable 요구를 만족하지 못했다. ID enum을 `nonisolated`로 선언하고 동일 suite를 재실행한다.

## F-05: 테스트 host 앱의 중복 시작

- 상태 / 분류: 해결 / 테스트 host 앱 실행 문제.
- 작업 / 테스트: Task 2 GREEN 시도, `test_accountDeletionFromMyPageReturnsToFreshHomeState`, `test_homeTypingUsesTheExistingQuoteRouteWithAnEmptyTranscript`.
- 관측 위치 / 원인 위치: xcresult의 SplashFeature.swift:25–26 dependency 접근 / `FiilsaApp.swift`의 app entry point가 테스트 host에서 별도로 실행되어 앱 Store를 생성.
- 기대값 / 실제값: 두 기존 App 라우팅 테스트 통과 / TCA가 테스트 컨텍스트에서 live dependency 접근을 경고·실패 처리. 전체 관련 묶음 11 통과, 2 실패.
- 재현 명령 / 환경: `/tmp/fiilsa-app-green-03.log`, iOS 26.5 / Xcode 26.6.
- 원인 / 확인 근거: `/tmp/fiilsa-app-green-03.xcresult` 실패 메시지가 host app 방출을 명시한다. 기존 테스트에 전체 의존성을 주입해도 동일했고, 관련 두 신규 테스트만 선택한 `/tmp/fiilsa-app-targeted-01.xcresult`에서도 신규 테스트 2개에 같은 오류가 귀속됐다. 저장소에 설치된 `swift-dependencies` 공식 `Testing.md`의 “Testing host application”은 실제 앱 entry point가 테스트 중 실행되는 현상과 `isTesting`으로 root view를 생략하는 해결책을 설명한다.
- 오류 로그 / xcresult: 위 경로의 test-results summary/tests.
- 수정 내용: 테스트에서 부분 변경(`/tmp/fiilsa-app-green-04.xcresult`: 12 통과, 1 실패) 및 전체 의존성 교체(`/tmp/fiilsa-app-green-05.xcresult`: 11 통과, 2 실패)를 시도했지만 같은 경고가 지속되어 되돌렸다. `FiilsaApp`의 `WindowGroup`에서 IssueReporting `isTesting`일 때만 root view/appStore 생성을 건너뛴다. 실제 사용자 앱 경로는 변경하지 않는다.
- 재검증: `/tmp/fiilsa-app-green-06.xcresult`에서 같은 AppFeatureTests 6/6 포함 관련 테스트 13/13 통과, 실패 0.

## F-06: Home 진입 작업이 전역 scope를 등록하지 않음 (TDD RED)

- 상태 / 분류: 해결 / 의도한 TDD RED.
- 작업 / 테스트: Task 3, `homeEntryWaitsForQuoteAndCompletionState`.
- 관측 위치 / 원인 위치: `FiilsaTests/HomeFeatureTests.swift`의 count 기대식 / `HomeFeature.swift:onAppear`가 명언·연속필사 상태를 별도 `.merge` Effect로 실행하고 loading scope를 등록하지 않음.
- 기대값 / 실제값: 명언 또는 연속필사 작업 한쪽이 끝난 뒤 활성 scope 1 / 0.
- 재현 명령 / 환경: `/tmp/fiilsa-home-loading-red-02.log`; Xcode 26.6, iOS 26.5. 함수별 `-only-testing`을 사용한 첫 시도는 실제 실행 0건이라 무효로 기록(`/tmp/fiilsa-home-loading-red-01.xcresult`).
- 원인 / 확인 근거: `/tmp/fiilsa-home-loading-red-02.xcresult`: 19건 중 18 통과, Home 신규 테스트 1 실패. Home 기존 코드에 begin/end가 없음.
- 오류 로그 / xcresult: 위 RED 결과 묶음.
- 수정 내용: Home 진입을 단일 `.run`의 begin/두 `async let`/모두 await/end로 묶고, 단일 호출은 wrapper로 변경.
- 재검증: `/tmp/fiilsa-home-loading-green-02.xcresult`에서 Home 및 LoadingEffect 21/21 통과, 실패 0.

## F-07: Calendar·팝업·탈퇴 작업에 scope 없음 (TDD RED)

- 상태 / 분류: 해결 / 의도한 TDD RED.
- 작업 / 테스트: Task 4, `FeatureLoadingIntegrationTests`의 Calendar 월 조회, 일반 팝업 실패 후 버전 조회, 회원탈퇴 뒤 세션 정리.
- 관측 위치 / 원인 위치: 각 통합 테스트의 `loadingCount(registry) == 1` / 해당 Feature의 기존 `.run`이 LoadingClient를 사용하지 않음.
- 기대값 / 실제값: API 대기 중 활성 scope 1 / 0. 세 테스트 모두 다른 Action 결과는 기존대로 실행.
- 재현 명령 / 환경: `/tmp/fiilsa-features-red-01.log`, Xcode 26.6 / iOS 26.5.
- 원인 / 확인 근거: `/tmp/fiilsa-features-red-01.xcresult`의 3/3 실패 메시지가 같은 count 기대식.
- 오류 로그 / xcresult: 위 경로.
- 수정 내용: 단일 API는 wrapper로, 순차 팝업 조회는 명시적 begin/await/end로 연결. 취소 일반 실패 변환 차단.
- 재검증: `/tmp/fiilsa-features-green-01.xcresult`에서 관련 기능 21/21 통과, `/tmp/fiilsa-features-integration-04.xcresult`에서 Alert 포함 통합 기능 10/10 통과, 실패 0.

## F-08: Alert 통합 테스트의 프레임워크 import 누락

- 상태 / 분류: 해결 / 테스트 코드 컴파일 오류.
- 작업 / 테스트: Task 4, `alertPermissionWaitIsUnscopedButServerSyncIsScoped`.
- 관측 위치 / 원인 위치: `FiilsaTests/FeatureLoadingIntegrationTests.swift:49`의 `.authorized` / 테스트 파일이 enum 정의 모듈 `UserNotifications`를 import하지 않음.
- 기대값 / 실제값: 권한→서버 동기화 경계 검증 / 빌드 exit 65.
- 재현 명령 / 환경: `/tmp/fiilsa-features-integration-03.log`, Xcode 26.6 / iOS 26.5.
- 원인 / 확인 근거: 컴파일러가 “missing import of defining module 'UserNotifications'”를 명시.
- 오류 로그 / xcresult: 위 로그; 테스트 실행 전에 컴파일 실패.
- 수정 내용: 테스트 파일에 UserNotifications import.
- 재검증: `/tmp/fiilsa-features-integration-04.xcresult`에서 Alert 포함 통합 기능 10/10 통과, 실패 0.

## F-09: API의 독립적인 취소 예외가 실패/후속 작업으로 이어짐

- 상태 / 분류: 해결 / 코드 리뷰 후 추가한 TDD RED.
- 작업 / 테스트: Task 4 보강, 팝업 일반 조회·회원탈퇴·Typing 저장의 `CancellationError` 재현 세 건.
- 관측 위치 / 원인 위치: `FeatureLoadingIntegrationTests.swift:24,40,60`의 신규 취소 Action 부재 / `GeneralPopupFeature.swift`의 `try?`, `MyPageFeature.swift`의 포괄적 catch, `TypingFeature.swift`의 세션 조회 `try?`.
- 기대값 / 실제값: 취소 뒤 다음 API/로컬 쓰기/실패 토스트 없이 해당 로딩 flag만 재설정 / 기존 코드는 후속 API·로컬 분기·실패 처리로 진행 가능. RED는 신규 Action 미구현으로 빌드 exit 65.
- 재현 명령 / 환경: `/tmp/fiilsa-cancel-red-01.log`, Xcode 26.6 / iOS 26.5; 해당 의존성 클로저가 부모 Task 취소 없이 `CancellationError`를 던지도록 제어.
- 원인 / 확인 근거: 코드 리뷰에서 세 포괄적 catch 경로 식별, RED 컴파일러가 누락 Action 세 건을 명시.
- 오류 로그 / xcresult: 위 RED 로그. 실제 사용자 환경의 독립적인 CancellationError 발생 경로는 확인되지 않았으나 동작 계약과 다른 경로다.
- 수정 내용: 취소 예외를 일반 오류보다 먼저 구분하고 로딩 flag 재설정 Action을 보내며, 팝업의 남은 조회를 시작하지 않게 수정.
- 재검증: `/tmp/fiilsa-cancel-green-01.xcresult`에서 새 세 테스트 및 관련 25/25 통과, 실패 0.

## F-10: 결과 순서 테스트의 MainActor 격리 충돌

- 상태 / 분류: 해결 / 테스트 코드 컴파일 오류.
- 작업 / 테스트: 코드 리뷰 후 `scopeEndsAfterResultActionIsReduced` 강화.
- 관측 위치 / 원인 위치: `LoadingEffectTests.swift:93` / TCA Reducer의 동기 클로저에서 MainActor 전용 테스트 marker를 직접 수정.
- 기대값 / 실제값: 결과 Action 처리 전 scope 종료 감지 / Swift 동시성 컴파일 오류, exit 65.
- 재현 명령 / 환경: `/tmp/fiilsa-contract-tests-01.log`, Xcode 26.6 / iOS 26.5.
- 원인 / 확인 근거: 컴파일러가 main actor-isolated property를 nonisolated context에서 수정할 수 없다고 명시.
- 오류 로그 / xcresult: 위 로그; 테스트 실행 전 컴파일 실패.
- 수정 내용: marker를 테스트 전용 NSLock 보호 값으로 바꾸어 Reducer 동기 처리와 비동기 end 클로저가 같은 상태를 안전하게 관찰하도록 변경.
- 재검증: `/tmp/fiilsa-contract-tests-03.xcresult`에서 로딩 계약 10/10 통과, 실패 0.

# 전역 로딩 검증 실패 기록

전체 앱 테스트는 생략하고 변경 관련 suite만 실행한다. 의도한 TDD RED도 예상하지 못한 실패와 구분해 보존한다.

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

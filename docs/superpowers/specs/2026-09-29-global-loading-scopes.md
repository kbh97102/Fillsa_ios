# 전역 로딩과 API 작업 묶음 설계

## 요청

Feature(ViewModel 역할)에서 API를 사용할 때 공통 wrapper로 로딩을 시작하고 종료한다. 화면 진입에 A/B/C처럼 여러 API가 필요하면 하나의 작업으로 묶고, 모두 종료된 후 로딩을 내린다.

### 논의 반영: 단일 호출과 여러 호출의 진입점

단일 API는 `.runWithLoading`으로 자동 관리한다. 여러 API를 함께 기다리는 화면은 Feature에서 `loadingClient.begin()` → A/B/C 실행 → 모두 await → `loadingClient.end(token)`을 직접 선언한다. 별도 `runGroup`, 배열 기반 API 실행기, 그룹 wrapper는 만들지 않는다.

## 동작 계약

- 단일 Feature 비동기 작업은 `Effect.runWithLoading`으로 감싼다. 여러 작업 묶음은 Feature에서 시작/종료를 선언한다. APIClient/Repository/UseCase는 UI 로딩을 알지 않는다.
- 하나의 단일 wrapper 또는 명시적 작업 묶음이 하나의 로딩 범위(scope)다. 내부의 순차·병렬 API 수와 무관하게 시작/종료는 각각 한 번이다.
- 전역 로딩은 활성 scope가 하나 이상일 때 표시한다. 겹친 작업 중 하나가 끝나도 나머지가 실행 중이면 유지한다.
- 활성 scope는 `Set<UUID>`로 관리한다. 자신의 token만 종료하며 같은 token을 두 번 종료해도 다른 작업을 건드리지 않는다.
- 시작 등록, 작업 실행, 결과 Action 처리, 종료 등록을 순서대로 await한다. 결과를 Reducer에 반영한 다음 scope를 종료한다.
- A/B/C의 일반 오류는 각 Feature가 기존 결과 Action으로 처리한다. B가 실패해도 A/C를 계속 기다리는 것을 기본으로 한다. 하나라도 실패하면 전부 취소하는 정책은 이번 기본 동작이 아니다.
- 작업 취소 시에도 자신의 scope를 정리한다. 취소는 일반 실패 Action/토스트로 바꾸지 않는다. 취소에 협조하지 않는 API는 실제 종료 전까지 scope가 살아 있을 수 있다.
- 새 token 등록과 stream 초기 snapshot 생성은 같은 actor에서 직렬화한다. 구독 시작 시 현재 활성 수를 즉시 전달한다.
- 화면 이동만으로 활성 scope를 일괄 초기화하지 않는다. 기존 `.cancellable` 정책은 유지한다.
- `isLoading`, `isSaving`, `isProcessing` 같은 Feature 상태는 중복 요청 방지와 화면별 상태에 계속 사용한다. 전역 표시 수의 대체재가 아니다.

## 공통 인터페이스

```swift
struct LoadingClient: Sendable {
    var begin: @Sendable () async -> UUID
    var end: @Sendable (UUID) async -> Void
    var counts: @Sendable () async -> AsyncStream<Int>

    func withLoading(_ operation: @Sendable () async -> Void) async
}

extension Effect {
    static func runWithLoading(
        operation: @escaping @Sendable (Send<Action>) async -> Void
    ) -> Self
}
```

`withLoading`은 시작 → operation → 종료의 공통 수명 관리다. operation이 오류를 밖으로 던지지 않도록 타입을 제한하므로 Feature는 기존 do/catch와 성공/실패 Action을 그대로 소유한다. 호출 전 취소됐으면 등록하지 않으며, 등록 직후 취소됐다면 operation 실행을 건너뛰고 token을 종료한다. 종료를 `defer { Task { ... } }`로 미루지 않는다.

`runWithLoading`은 단일 작업을 TCA `.run`에서 사용하기 위한 얇은 진입점이다. 여러 API를 묶는 Feature만 begin/end를 직접 호출한다. Default MainActor 프로젝트 설정과 충돌하지 않게 registry는 명시적인 actor, dependency closures는 `@Sendable`로 만든다.

## 여러 API 묶기

- Feature의 동일 `.run` 안에서 begin을 한 번 호출하고, `async let`으로 작업을 시작해 모두 await한 뒤 end를 한 번 호출한다.
- 각각의 helper는 `async -> Void`이며, 일반 실패를 결과 Action으로 바꾼다. 따라서 첫 오류 때문에 scope가 조기 종료되지 않는다.
- begin 후 부모 closure에서 end를 건너뛰는 early return/throw를 만들지 않는다. 취소 처리는 자식 helper가 반환하고 부모는 모든 helper 종료 후 end까지 실행하는 방식으로 한다.
- `Task { ... }`로 분리한 작업은 부모가 완료를 기다리지 않으므로 사용하지 않는다.
- `await send(.loadA)`는 그 Action이 만드는 API Effect까지 기다리지 않는다. 그룹은 Action 전송이 아니라 실제 비동기 API 작업을 묶는다.
- `.merge`는 여러 Effect를 병렬 실행하지만 모든 Effect를 기다리는 await 표현은 아니다. 묶음이 필요한 기존 `.merge`는 하나의 `.run`과 명시적인 begin/async let/await/end로 옮긴다.

예: A 성공 100ms → B 실패 300ms → C 성공 700ms라면 전역 로딩은 700ms까지 유지한다. 다른 scope D가 900ms까지 실행된다면 전역 로딩은 D가 끝날 때까지 유지한다.

## 적용 범위

| 위치 | 로딩 범위 |
|---|---|
| Home 진입 | Feature에서 명언 조회 + 연속필사 로컬 상태 조회의 시작/종료를 명시 |
| Home 날짜 변경/좋아요/이미지 업로드·삭제 | 사용자 작업별 한 scope |
| Calendar | 월 조회 전체 |
| QuoteList | 첫 조회, 필터 변경, 새로고침, 다음 페이지 조회 각각 |
| Notice | 공지 목록 조회 |
| Login | 소셜 SDK 인증 완료 후 서버 로그인·후속 저장 전체 |
| Typing | 기존 조회·좋아요·저장 작업 전체; 서버/로컬 분기 모두 같은 wrapper |
| MemoInsert | 메모 저장 전체 |
| MyPage | 회원탈퇴 API와 후속 세션 정리 전체 |
| GeneralPopup | Feature에서 일반 팝업 + 버전 팝업 조회·숨김 조건 확인의 시작/종료를 명시 |
| Alert | OS 권한 요청 이후 푸시 서버 동기화 구간만 `loadingClient.withLoading` 적용 |

App의 FCM 자동 동기화, 이벤트 stream, 소셜 SDK/OS 권한 대기, 단순 설정 읽기·쓰기에는 전역 로딩을 자동 적용하지 않는 안을 제안한다. 백그라운드 요청까지 포함하려면 적용 정책만 조정한다. HTTP 토큰 재발급과 재시도는 이미 감싼 foreground 요청의 scope 안에 포함된다.

## 전역 상태와 표시

- `AppFeature.State.activeLoadingCount: Int = 0`
- `AppFeature.State.isGlobalLoading: Bool { activeLoadingCount > 0 }`
- `AppFeature.Action.loadingCountChanged(Int)`
- App의 `.task`에서 counts를 구독하고 Action을 보낸다. 구독 Effect 자체는 wrapper로 감싸지 않는다.
- UI fixture에서는 기존 startup 작업을 건너뛰되 loading 구독은 유지할 수 있도록 분리한다.
- 최종 UI는 AppView 최상위에 한 번만 조립한다. 크기·색·배경·문구·터치 차단·모달과의 층 순서는 Figma의 대상 상태를 확인한 후 확정한다.

현재 로딩스피너 Figma URL/node-id는 미확보 상태다. 동작 계층 계획은 작성하되, 시각 구현과 최종 UI QA는 `AGENTS.md` 및 `docs/ui-redesign-workflow.md` 게이트를 충족한 뒤 진행한다.

## 검증과 범위

단일 성공/실패, A/B/C 종료 순서, B만 실패, scope 중첩·중복 종료, 취소, 이미 실행 중인 scope에 늦게 구독, 결과 Action 반영 후 종료를 검증한다. 실시간 sleep 대신 제어 가능한 AsyncStream/continuation으로 종료 시점을 고정한다. 전체 앱 테스트는 사용자의 기존 요청에 따라 생략하고 관련 suite만 실행한다.

검증에서 실패가 발생하면 `docs/verification/<검증일>-global-loading-failures.md`를 작성하고 사용자에게 링크와 요약을 제공한다. 실패한 테스트/단계, 코드 위치, 기대값·실제값, 재현 명령·환경, 원인과 근거, 수정 내용·재검증 결과를 남긴다. 원인을 모르면 미확인으로 표시하고 가설을 사실과 구분한다. 의도한 TDD RED와 예상하지 못한 실패, 제품 코드 문제와 빌드/시뮬레이터 환경 문제를 구분한다. 이후 통과해도 최초 실패와 해결 이력을 유지한다. UI 실패의 시각 증거는 Figma QA 기록과 연결한다.

표시 지연, 최소 표시 시간, 자동 재시도, 새 오류 문구, 새 내비게이션 취소 정책은 요구되지 않았으므로 추가하지 않는다. 시스템 권한창 위에 임의 overlay를 만들지 않는다.

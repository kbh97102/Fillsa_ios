# Swift Concurrency Learning Roadmap

이 문서는 Swift의 비동기 처리와 동시성 개념을 Android 개발자 기준으로 순차적으로 학습하기 위한 가이드다.

TCA의 `Effect.run`, `@Dependency`, `@Sendable`을 제대로 이해하려면 먼저 Swift의 `async/await`, `Task`, cancellation, actor, `Sendable`을 알아야 한다.

기초 내용을 더 자세히 보고 싶다면 `basics.md`를 먼저 읽는다. 면접 질문과 심화 주제는 `interview.md`에서 따로 정리한다.

## 먼저 결론

이 프로젝트에서 비동기 흐름은 다음 구조로 이해한다.

```text
SwiftUI View
-> Action 전송
-> TCA Reducer
-> Effect.run 안에서 async 작업 시작
-> @Dependency로 UseCase 호출
-> UseCase가 Repository/API/DB 호출
-> 결과를 Action으로 다시 send
-> Reducer가 State 변경
```

Android로 보면 대략 다음과 같다.

```text
Compose UI
-> Intent/Action 전달
-> ViewModel
-> viewModelScope.launch
-> UseCase 호출
-> Repository/API/DB 호출
-> UiState 업데이트
-> Compose recomposition
```

## 읽는 순서

### 0. 기초 자세히 보기

먼저 `basics.md`를 읽는다.

목표:

- Swift 비동기 처리가 왜 필요한지 이해한다.
- `async`, `await`, `async throws`, `Task`를 Android coroutine과 비교할 수 있다.
- TCA의 `Effect.run`과 `await send`가 어떤 흐름인지 이해한다.
- `MainActor`, `actor`, `Sendable`, `@Sendable`의 기본 의미를 이해한다.

### 1. 동기 함수와 비동기 함수

목표:

- `func`와 `async func`의 차이를 이해한다.
- `await`가 "결과를 기다리는 지점"이라는 것을 이해한다.
- Android의 일반 함수와 `suspend fun`을 비교할 수 있다.

핵심 문법:

```swift
func loadSync() -> String

func loadAsync() async throws -> String

let value = try await loadAsync()
```

Android 비교:

```kotlin
fun loadSync(): String

suspend fun loadAsync(): String

val value = loadAsync()
```

### 2. Task

목표:

- `Task`가 Swift의 비동기 작업 단위라는 것을 이해한다.
- Android의 `launch {}`와 비슷하지만, SwiftUI/TCA에서는 직접 남발하지 않는다는 것을 이해한다.

핵심 문법:

```swift
Task {
    let value = try await loadAsync()
}
```

Android 비교:

```kotlin
viewModelScope.launch {
    val value = loadAsync()
}
```

프로젝트 기준:

- SwiftUI View 안에서 직접 `Task {}`를 많이 만들지 않는다.
- 화면 이벤트는 Action으로 보내고, Reducer의 `Effect.run`에서 비동기 작업을 시작한다.

### 3. async throws

목표:

- Swift의 에러 처리가 `throws`, `try`, `do/catch`로 이뤄진다는 것을 이해한다.
- `async throws`는 "비동기이고 실패할 수 있는 함수"라는 뜻임을 이해한다.

핵심 문법:

```swift
func login(_ request: LoginRequest) async throws -> LoginResponse

do {
    let response = try await login(request)
} catch {
    // error handling
}
```

Android 비교:

```kotlin
suspend fun login(request: LoginRequest): LoginResponse

try {
    val response = login(request)
} catch (e: Exception) {
    // error handling
}
```

### 4. cancellation

목표:

- Swift 비동기 작업도 취소될 수 있다는 것을 이해한다.
- TCA의 `.cancellable(id:)`, `.cancel(id:)`가 Android의 `Job.cancel()`과 비슷한 목적이라는 것을 이해한다.

핵심 문법:

```swift
while !Task.isCancelled {
    try await clock.sleep(for: .seconds(1))
}
```

Android 비교:

```kotlin
while (isActive) {
    delay(1000)
}
```

프로젝트 기준:

- 검색, 타이머, 반복 polling, 화면 이탈 시 중단되어야 하는 작업은 cancellation을 설계한다.
- 단순 API 요청은 대부분 Action 결과를 받고 끝난다.

### 5. MainActor

목표:

- UI 상태는 main actor에서 다뤄야 한다는 것을 이해한다.
- Android의 main thread와 비슷하게 생각하되, Swift는 actor 격리 규칙을 컴파일러가 더 강하게 검사한다는 것을 이해한다.

핵심 문법:

```swift
@MainActor
func updateUI() {
}

await MainActor.run {
    // UI 관련 작업
}
```

Android 비교:

```kotlin
withContext(Dispatchers.Main) {
    // UI 관련 작업
}
```

프로젝트 기준:

- SwiftUI View와 TCA State 변경은 UI 흐름과 연결된다.
- Repository, UseCase, APIClient는 UI와 분리된 비동기 작업으로 둔다.

### 6. actor

목표:

- `actor`가 여러 비동기 작업이 같은 mutable state를 동시에 건드리지 못하게 보호하는 타입임을 이해한다.
- Android의 `Mutex`, single-thread dispatcher, synchronized 저장소와 목적이 비슷하다는 것을 이해한다.

핵심 문법:

```swift
actor TokenStore {
    private var token = ""

    func setToken(_ value: String) {
        token = value
    }

    func getToken() -> String {
        token
    }
}
```

호출:

```swift
let token = await tokenStore.getToken()
```

### 7. Sendable

목표:

- `Sendable`은 "동시성 경계를 넘어가도 안전한 값"이라는 뜻임을 이해한다.
- `@Sendable`은 "동시성 환경에서 안전하게 실행될 수 있는 클로저"라는 뜻임을 이해한다.
- TCA dependency 함수에 `@Sendable`이 자주 붙는 이유를 이해한다.

핵심 문법:

```swift
struct HomeClient {
    var getDailyQuoteNoToken: @Sendable (String) async throws -> DailyQuote
}
```

뜻:

```text
이 클로저는 async Task나 actor 경계를 넘어서 전달되어도 안전해야 한다.
```

주의할 예:

```swift
var count = 0

let load: @Sendable () async -> Void = {
    count += 1
}
```

이런 코드는 여러 작업이 동시에 `count`를 바꿀 수 있어서 문제가 될 수 있다.

프로젝트 기준:

- Dependency client의 함수 타입에는 `@Sendable`을 붙인다.
- 클로저 안에서는 가능한 한 immutable 값, thread-safe 저장소, repository/usecase 호출만 캡처한다.
- mutable 공유 상태가 필요하면 actor, repository 내부 저장소, TCA State 같은 명확한 소유 위치를 둔다.

### 8. TCA Effect.run

목표:

- TCA에서 `Effect.run`이 Android의 `viewModelScope.launch` 역할에 가깝다는 것을 이해한다.
- 비동기 결과는 직접 State를 바꾸지 않고 Action으로 다시 보내야 한다는 것을 이해한다.

핵심 문법:

```swift
return .run { send in
    do {
        let response = try await homeUseCase.getDailyQuote(date)
        await send(.dailyQuoteLoaded(.success(response)))
    } catch {
        await send(.dailyQuoteLoaded(.failure(.defaultError)))
    }
}
```

Android 비교:

```kotlin
viewModelScope.launch {
    try {
        val response = homeUseCase.getDailyQuote(date)
        updateState { copy(quote = response) }
    } catch (e: Exception) {
        updateState { copy(error = e) }
    }
}
```

TCA에서는 `Effect` 안에서 직접 State를 바꾸지 않는다. 결과를 Action으로 보내고, Reducer가 그 Action을 받아 State를 바꾼다.

## 이 프로젝트에서 외워둘 기준

| 상황 | 기준 |
|---|---|
| 서버/API 호출 | `async throws` 함수로 표현 |
| API/DB 호출 위치 | Domain UseCase 또는 Repository |
| Reducer에서 비동기 실행 | `Effect.run` |
| 비동기 결과 처리 | 결과 Action으로 `send` |
| 취소 가능한 작업 | `.cancellable(id:)` |
| UI/main thread 경계 | `MainActor` |
| 공유 mutable state 보호 | actor 또는 명확한 저장소 |
| Dependency closure | `@Sendable` |

## 학습 후 읽을 문서

이 문서를 읽은 뒤에는 다음 순서로 보면 된다.

1. `basics.md`
2. `interview.md`
3. `../tca-basic-guide.md`
4. `../tca-advanced-guide.md`
5. `../tca-guide.md`

TCA 문서에서 `Effect.run`, `await send`, `@Dependency`, `@Sendable`이 나오면 이 문서의 7-8장을 다시 보면 된다.

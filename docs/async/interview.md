# Swift Concurrency Interview Guide

이 문서는 Swift 비동기 처리와 동시성에 대해 면접에서 자주 나오는 질문을 정리한다. 기본 질문은 짧고 정확하게 답할 수 있게, 심화 질문은 왜 그런 설계가 필요한지까지 설명할 수 있게 구성한다.

Android 개발자 기준 비교도 함께 적는다.

## 답변할 때의 기본 프레임

면접 답변은 보통 이 순서로 말하면 안정적이다.

1. 개념 정의
2. Android coroutine과의 유사점 또는 차이
3. 실제 코드에서 어디에 쓰는지
4. 주의할 점

예:

```text
async는 비동기 함수임을 표시하고, await는 그 비동기 결과를 기다리는 지점입니다.
Android의 suspend fun 호출과 비슷합니다.
저희 앱에서는 UseCase나 Repository의 API/DB 호출을 async throws로 표현합니다.
단, await 지점에서는 작업이 suspend될 수 있고 actor reentrancy 같은 동시성 이슈를 고려해야 합니다.
```

## 1. 기본 질문

### Q. `async`와 `await`는 무엇인가?

`async`는 함수가 비동기적으로 실행될 수 있음을 나타내고, `await`는 비동기 함수의 결과를 기다리는 지점이다.

```swift
func fetchQuote() async throws -> DailyQuote

let quote = try await fetchQuote()
```

Android의 `suspend fun`과 호출 지점에서 suspend되는 개념이 비슷하다.

주의할 점:

- `await`는 thread를 block한다는 뜻이 아니다.
- 현재 작업이 suspend되고, 시스템이 다른 작업을 실행할 수 있게 양보한다.
- `await` 이후에는 다른 actor/thread 문맥에서 이어질 수 있다.

### Q. `async throws`는 무엇인가?

비동기적으로 실행되고 실패할 수 있는 함수다.

```swift
func login(_ request: LoginRequest) async throws -> LoginResponse
```

호출할 때는 `try await`가 필요하다.

```swift
do {
    let response = try await login(request)
} catch {
    // error handling
}
```

Android의 `suspend fun` + `try/catch`와 비슷하다.

### Q. `Task`는 무엇인가?

`Task`는 Swift concurrency에서 비동기 작업을 실행하는 단위다.

```swift
Task {
    let quote = try await fetchQuote()
}
```

Android의 `launch {}`와 비슷하게 볼 수 있다.

프로젝트 기준:

- SwiftUI View에서 직접 `Task {}`를 많이 만들기보다 Action을 Reducer로 보내고 TCA `Effect.run`에서 비동기 작업을 실행한다.
- View에서 직접 Task를 만들면 생명주기, 취소, 테스트가 흩어지기 쉽다.

### Q. structured concurrency란 무엇인가?

비동기 작업의 부모-자식 관계를 구조적으로 관리하는 모델이다. 부모 작업이 취소되면 자식 작업도 취소되고, 자식 작업의 완료를 부모가 추적할 수 있다.

예:

```swift
async let quote = quoteRepository.getDailyQuote()
async let streak = streakRepository.getStreak()

let result = try await (quote, streak)
```

Android의 structured concurrency와 같은 방향이다. `viewModelScope` 안에서 시작한 coroutine이 scope 생명주기에 묶이는 것과 유사하다.

### Q. unstructured task는 무엇인가?

부모 작업의 구조에서 벗어나 독립적으로 실행되는 작업이다.

```swift
Task {
    await sync()
}
```

주의할 점:

- 누가 취소하는지 불명확해질 수 있다.
- View나 Feature 생명주기와 분리되어 예상보다 오래 살아남을 수 있다.
- 테스트가 어려워질 수 있다.

TCA에서는 대부분 `Effect.run`과 cancellation id를 사용해 생명주기를 명확히 한다.

## 2. Cancellation 질문

### Q. Swift cancellation은 강제 종료인가?

아니다. Swift cancellation은 협력적 cancellation이다. 작업이 취소 상태를 확인하거나 cancellation을 던지는 suspension point에 도달해야 중단된다.

```swift
while !Task.isCancelled {
    try await clock.sleep(for: .seconds(1))
}
```

Android coroutine의 cooperative cancellation과 비슷하다.

### Q. 취소를 설계해야 하는 작업은 무엇인가?

다음 작업은 취소 설계가 필요하다.

- 검색어 입력마다 새 요청이 나가는 검색
- 타이머
- polling
- 화면이 사라지면 중단되어야 하는 다운로드/업로드
- 이전 요청 결과가 최신 화면 상태를 덮으면 안 되는 작업

TCA에서는 보통 이렇게 처리한다.

```swift
return .run { send in
    let result = try await searchUseCase(query)
    await send(.searchResponse(result))
}
.cancellable(id: CancelID.search, cancelInFlight: true)
```

### Q. cancellation과 error handling은 어떻게 다루나?

`CancellationError`는 일반 실패와 다르게 취급하는 것이 좋다. 사용자가 화면을 나갔거나 새 요청이 기존 요청을 대체한 경우일 수 있기 때문이다.

```swift
do {
    let result = try await load()
    await send(.loaded(result))
} catch is CancellationError {
    // 보통 사용자-facing 에러로 표시하지 않는다.
} catch {
    await send(.failed)
}
```

## 3. MainActor 질문

### Q. `MainActor`는 무엇인가?

UI 관련 작업을 main actor에서 실행하도록 보장하는 전역 actor다.

```swift
@MainActor
func updateUI() {
}
```

Android의 main thread와 비슷하지만, Swift는 actor isolation을 컴파일러가 검사한다.

### Q. `DispatchQueue.main.async`와 `MainActor.run`은 어떻게 다른가?

`DispatchQueue.main.async`는 GCD 기반으로 main queue에 작업을 넣는다. `MainActor.run`은 Swift concurrency의 actor isolation 모델 안에서 main actor로 이동한다.

Swift concurrency 코드에서는 `MainActor.run` 또는 `@MainActor`가 더 자연스럽다.

```swift
await MainActor.run {
    stateText = "완료"
}
```

### Q. 모든 ViewModel/Feature를 `@MainActor`로 만들면 되나?

무조건은 아니다.

SwiftUI View와 UI state는 main actor와 강하게 연결되지만, Repository/API/DB 작업은 main actor에 묶으면 안 된다. 느린 작업이 UI actor를 불필요하게 점유할 수 있기 때문이다.

프로젝트 기준:

- View와 UI state 변경: TCA Reducer 흐름에 맡긴다.
- UseCase/Repository/APIClient: main actor에 묶지 않는다.
- UI 프레임워크 접근이 필요한 코드만 `MainActor` 경계를 둔다.

## 4. Actor 질문

### Q. actor는 무엇인가?

`actor`는 내부 mutable state를 동시 접근으로부터 보호하는 reference type이다.

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

actor 밖에서 접근할 때는 보통 `await`가 필요하다.

```swift
let token = await tokenStore.getToken()
```

Android로 보면 `Mutex`로 보호하는 저장소나 single-thread dispatcher에 가까운 역할이다.

### Q. actor와 class의 차이는 무엇인가?

`class`는 여러 thread/task가 동시에 mutable property를 바꿀 수 있다. `actor`는 actor isolation을 통해 한 번에 하나의 작업만 actor-isolated state에 접근하도록 보장한다.

단, actor가 모든 문제를 자동으로 해결하는 것은 아니다. `await` 지점에서 actor reentrancy가 발생할 수 있다.

### Q. actor reentrancy란 무엇인가?

actor 메서드 안에서 `await`를 만나면 actor는 다른 작업이 들어와 실행될 수 있게 허용한다. 그래서 `await` 전후로 actor 내부 상태가 바뀌었을 수 있다.

위험한 예:

```swift
actor SessionManager {
    private var token: String?

    func refreshIfNeeded() async throws -> String {
        if let token {
            return token
        }

        let newToken = try await requestNewToken()
        token = newToken
        return newToken
    }
}
```

여러 작업이 동시에 `refreshIfNeeded()`를 호출하면 `requestNewToken()`이 중복 실행될 수 있다. `await` 중 actor가 다른 호출을 받아들일 수 있기 때문이다.

대응:

- in-flight task를 저장해서 공유한다.
- await 전에 필요한 상태를 캡처하고 await 후 다시 검증한다.
- 상태 변경 순서를 작게 유지한다.

예:

```swift
actor SessionManager {
    private var token: String?
    private var refreshTask: Task<String, Error>?

    func refreshIfNeeded() async throws -> String {
        if let token {
            return token
        }

        if let refreshTask {
            return try await refreshTask.value
        }

        let task = Task {
            try await requestNewToken()
        }
        refreshTask = task

        do {
            let newToken = try await task.value
            token = newToken
            refreshTask = nil
            return newToken
        } catch {
            refreshTask = nil
            throw error
        }
    }
}
```

## 5. Sendable 질문

### Q. `Sendable`은 무엇인가?

`Sendable`은 값이 동시성 경계를 넘어 다른 task나 actor로 전달되어도 안전하다는 표시다.

대체로 다음 타입은 안전하다.

- `Int`, `String`, `Bool` 같은 value type
- immutable 값만 가진 struct
- 직접 `Sendable`을 만족하도록 설계된 타입

주의가 필요한 타입:

- mutable class
- thread-safe하지 않은 reference type
- 캡처된 mutable 변수

### Q. `@Sendable`은 무엇인가?

`@Sendable`은 클로저가 동시성 환경에서 안전하게 전달되고 실행될 수 있어야 한다는 표시다.

```swift
var load: @Sendable () async throws -> DailyQuote
```

TCA dependency 함수 타입에 자주 붙는다. `Effect.run` 안에서 dependency를 호출할 때 task 경계를 넘을 수 있기 때문이다.

### Q. `@Sendable` 클로저에서 조심해야 하는 코드는?

공유 mutable state를 캡처해서 변경하는 코드가 위험하다.

```swift
var count = 0

let work: @Sendable () async -> Void = {
    count += 1
}
```

여러 task가 동시에 실행하면 data race가 생길 수 있다.

대응:

- mutable state를 actor 안에 둔다.
- TCA State처럼 한 곳에서만 변경한다.
- thread-safe한 저장소나 repository를 통해 접근한다.
- 가능하면 immutable value만 캡처한다.

### Q. `@unchecked Sendable`은 무엇인가?

컴파일러가 Sendable 안전성을 증명하지 못하지만 개발자가 직접 안전하다고 약속하는 것이다.

```swift
final class SafeBox: @unchecked Sendable {
}
```

매우 신중하게 사용해야 한다. 내부 동기화가 없는데 붙이면 data race를 컴파일러가 막아주지 못한다.

면접 답변에서는 "`@unchecked Sendable`은 마지막 수단이고, 내부 lock/actor/불변성 등으로 thread-safety를 직접 보장해야 한다"고 말하면 된다.

## 6. TaskGroup, async let 질문

### Q. `async let`은 언제 쓰나?

서로 독립적인 비동기 작업 몇 개를 병렬로 실행하고, 모두 결과가 필요할 때 쓴다.

```swift
async let quote = quoteRepository.getDailyQuote()
async let streak = streakRepository.getStreak()

let result = try await (quote, streak)
```

작업 수가 고정적이고 단순할 때 적합하다.

### Q. `TaskGroup`은 언제 쓰나?

동적으로 여러 작업을 병렬 실행해야 할 때 쓴다.

```swift
try await withThrowingTaskGroup(of: Image.self) { group in
    for url in urls {
        group.addTask {
            try await imageRepository.load(url)
        }
    }

    var images: [Image] = []
    for try await image in group {
        images.append(image)
    }
    return images
}
```

`async let`은 고정 개수, `TaskGroup`은 동적 개수라고 기억하면 쉽다.

### Q. `Task.detached`는 언제 쓰나?

현재 task의 priority, cancellation, task-local value, actor context를 상속하지 않는 독립 task를 만들 때 쓴다.

대부분의 앱 코드에서는 필요하지 않다.

주의할 점:

- 부모 cancellation을 자동으로 따르지 않는다.
- actor context를 벗어난다.
- 생명주기가 불명확해질 수 있다.

면접에서는 "일반적인 UI 앱에서는 structured concurrency나 TCA Effect를 우선 사용하고, detached는 의도적으로 부모 context와 분리해야 할 때만 제한적으로 쓴다"고 답하면 된다.

## 7. Swift Concurrency와 GCD 질문

### Q. Swift concurrency와 GCD의 차이는?

GCD는 queue에 block을 제출하는 저수준 동시성 API다. Swift concurrency는 `async/await`, `Task`, actor, cancellation, priority 같은 언어 수준 모델을 제공한다.

비교:

| GCD | Swift concurrency |
|---|---|
| `DispatchQueue.async` | `Task`, `async/await` |
| queue 중심 | task/actor 중심 |
| cancellation 직접 설계 | structured cancellation 지원 |
| thread-safety 수동 관리 | actor/Sendable 검사 |

기존 GCD API와 섞어 쓸 수는 있지만, 새 비동기 코드는 Swift concurrency 모델을 우선한다.

### Q. async/await가 thread를 새로 만드는가?

반드시 그렇지 않다. `async/await`는 비동기 작업을 표현하는 언어 모델이고, 실제 thread 관리는 런타임이 한다.

중요한 점:

- `await`는 thread block이 아니다.
- task는 suspension point에서 실행을 양보할 수 있다.
- thread와 task는 1:1 관계가 아니다.

## 8. TCA와 연결된 면접 질문

### Q. TCA에서 왜 비동기 결과를 직접 State에 넣지 않고 Action으로 보내나?

State 변경 경로를 Reducer 하나로 모으기 위해서다.

```swift
return .run { send in
    let quote = try await homeUseCase.getDailyQuote(date)
    await send(.dailyQuoteLoaded(.success(quote)))
}
```

이 구조의 장점:

- 버튼 입력, API 결과, 생명주기 이벤트가 모두 Action 흐름으로 정리된다.
- 테스트에서 어떤 Action 후 어떤 State 변경이 생기는지 검증하기 쉽다.
- 비동기 작업과 State 변경 책임이 분리된다.

### Q. TCA dependency에 `@Sendable`을 붙이는 이유는?

TCA Effect는 Swift concurrency task 안에서 실행된다. dependency closure가 task 경계로 전달될 수 있으므로, 동시성 안전한 클로저라는 계약을 타입에 표시한다.

```swift
struct HomeClient {
    var getDailyQuote: @Sendable (String) async throws -> DailyQuote
}
```

실무적으로는 fake dependency를 테스트에서 주입하기도 쉽고, live dependency도 동시성 경계에서 안전하게 호출하도록 설계할 수 있다.

### Q. Reducer에서 Repository를 직접 호출하지 않는 이유는?

Reducer가 화면 상태 변경과 이벤트 처리에 집중하도록 하기 위해서다. API 호출, 로컬 저장, 로그인 후 토큰 저장 같은 비즈니스 흐름은 Domain UseCase에 둔다.

프로젝트 기준 구조:

```text
Reducer
-> @Dependency use case client
-> Domain UseCase
-> Repository protocol
-> Data Repository implementation
```

이 구조는 Android의 `ViewModel -> UseCase -> Repository`와 가장 비슷하다.

## 9. 깊은 영역 체크리스트

면접에서 깊게 물어보면 아래 키워드까지 설명할 수 있으면 좋다.

| 키워드 | 핵심 답변 |
|---|---|
| Suspension point | `await`에서 작업이 일시 중단될 수 있는 지점 |
| Cooperative cancellation | 취소는 강제 종료가 아니라 작업이 협력적으로 반응해야 함 |
| Structured concurrency | 부모-자식 task 관계로 생명주기와 취소를 관리 |
| Unstructured task | 구조 밖에서 실행되어 취소/생명주기 관리가 어려울 수 있음 |
| Actor isolation | actor 내부 mutable state 접근을 컴파일러가 제한 |
| Actor reentrancy | actor 메서드의 `await` 중 다른 호출이 들어와 상태가 바뀔 수 있음 |
| Sendable | 동시성 경계를 넘어 안전하게 전달 가능한 타입 |
| @Sendable | 동시성 경계를 넘어 안전하게 실행 가능한 closure |
| @unchecked Sendable | 개발자가 직접 thread-safety를 보장한다고 컴파일러에 약속 |
| MainActor | UI/main thread 성격의 global actor |
| TaskGroup | 동적 개수의 child task 병렬 실행 |
| Task.detached | 부모 task context를 상속하지 않는 독립 task |

## 10. 짧은 모범 답변 모음

### `await`는 무엇인가?

`await`는 비동기 함수의 결과를 기다리는 suspension point입니다. thread를 block하는 것이 아니라 현재 task가 일시 중단될 수 있고, 런타임이 다른 작업을 실행할 수 있습니다.

### `Task`와 thread의 차이는?

Task는 Swift concurrency의 작업 단위이고, thread는 OS 실행 자원입니다. task와 thread는 1:1 관계가 아니며, task는 suspension point에서 thread를 점유하지 않을 수 있습니다.

### actor를 쓰는 이유는?

여러 task가 같은 mutable state에 동시에 접근할 때 data race를 막기 위해 씁니다. actor는 내부 state 접근을 격리하고, 외부에서 접근할 때 actor 경계를 `await`로 넘게 합니다.

### Sendable을 쓰는 이유는?

값이나 클로저가 task/actor 경계를 넘어 전달될 때 data race 위험이 없는지 컴파일러가 확인하도록 하기 위해 씁니다. TCA dependency closure에 `@Sendable`을 붙이는 것도 Effect의 task 경계에서 안전하게 호출되도록 하기 위한 설계입니다.

### MainActor는 언제 쓰나?

UI 프레임워크 접근이나 UI 상태와 직접 관련된 작업이 main actor에서 실행되어야 할 때 씁니다. 반대로 API, DB, parsing 같은 작업을 무조건 MainActor에 묶으면 UI responsiveness에 좋지 않습니다.

### async let과 TaskGroup의 차이는?

`async let`은 고정된 소수의 독립 작업을 병렬 실행할 때 간단하고, `TaskGroup`은 런타임에 개수가 정해지는 여러 작업을 병렬 처리할 때 적합합니다.

### Task.detached는 왜 조심해야 하나?

부모 task의 cancellation, priority, actor context를 상속하지 않아서 생명주기 관리가 어려워질 수 있습니다. 일반 앱 코드에서는 structured concurrency나 TCA Effect를 우선 사용합니다.

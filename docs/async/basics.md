# Swift Concurrency Basics

이 문서는 Swift 비동기 처리의 기초를 Android 개발자 기준으로 자세히 설명한다.

먼저 이 문서를 읽고, 전체 순서는 `README.md`, 면접/심화 질문은 `interview.md`에서 확인한다.

## 1. 왜 비동기 처리가 필요한가

앱은 UI를 계속 부드럽게 그리면서 네트워크, DB, 파일, 권한 요청 같은 느린 작업을 처리해야 한다.

Android에서는 보통 이렇게 한다.

```kotlin
viewModelScope.launch {
    val response = useCase()
    updateState { copy(data = response) }
}
```

Swift에서는 보통 이렇게 표현한다.

```swift
let response = try await useCase()
```

TCA 안에서는 이 비동기 호출을 `Effect.run` 안에서 실행한다.

```swift
return .run { send in
    let response = try await useCase()
    await send(.response(.success(response)))
}
```

중요한 기준:

- 느린 작업은 UI 흐름을 막으면 안 된다.
- 비동기 결과는 화면 상태를 바꾸기 전에 명확한 경로로 돌아와야 한다.
- 이 프로젝트에서는 그 경로를 TCA `Action`으로 통일한다.

## 2. 동기 함수와 비동기 함수

동기 함수는 호출하면 바로 결과를 돌려주거나, 끝날 때까지 현재 흐름을 붙잡는다.

```swift
func makeTitle() -> String {
    "오늘의 문장"
}

let title = makeTitle()
```

비동기 함수는 시간이 걸릴 수 있는 작업을 표현한다. Swift에서는 함수 선언에 `async`를 붙인다.

```swift
func loadQuote() async -> DailyQuote {
    DailyQuote()
}
```

호출할 때는 `await`가 필요하다.

```swift
let quote = await loadQuote()
```

Android 비교:

```kotlin
suspend fun loadQuote(): DailyQuote {
    return DailyQuote()
}

val quote = loadQuote()
```

Swift에서 `await`가 붙는 이유는 이 호출 지점에서 현재 작업이 잠시 멈출 수 있기 때문이다.

주의할 점:

- `await`는 thread를 block한다는 뜻이 아니다.
- `await`는 "여기서 비동기 결과를 기다리는 동안 현재 task가 suspend될 수 있다"는 표시다.
- `await` 뒤에는 다른 작업이 먼저 실행될 수 있다.

## 3. `async throws`

네트워크나 DB 작업은 실패할 수 있다. Swift는 실패 가능성을 `throws`로 표현한다.

```swift
func loadQuote() async throws -> DailyQuote {
    try await repository.getDailyQuote()
}
```

호출할 때는 `try await`를 같이 쓴다.

```swift
do {
    let quote = try await loadQuote()
} catch {
    // 실패 처리
}
```

Android 비교:

```kotlin
try {
    val quote = loadQuote()
} catch (e: Exception) {
    // 실패 처리
}
```

이 프로젝트의 Repository와 UseCase는 대부분 다음 모양을 가진다.

```swift
func login(_ request: LoginRequest) async throws -> LoginResponse
func getDailyQuote(_ date: String) async throws -> DailyQuote
func saveMemo(_ memo: String, seq: Int) async throws
```

읽는 법:

```text
async throws -> LoginResponse
= 비동기로 실행되고, 실패할 수 있고, 성공하면 LoginResponse를 반환한다.
```

## 4. Task

`Task`는 Swift concurrency에서 비동기 작업을 실행하는 단위다.

```swift
Task {
    let quote = try await loadQuote()
}
```

Android의 `launch {}`와 비슷하게 볼 수 있다.

```kotlin
viewModelScope.launch {
    val quote = loadQuote()
}
```

하지만 이 프로젝트에서는 SwiftUI View에서 직접 `Task {}`를 남발하지 않는다.

선호 흐름:

```text
View
-> Action 전송
-> Reducer
-> Effect.run
-> UseCase 호출
-> 결과 Action 전송
-> Reducer에서 State 변경
```

TCA 코드:

```swift
case .onAppear:
    return .run { send in
        do {
            let quote = try await homeUseCase.getDailyQuote("2026-06-21")
            await send(.dailyQuoteLoaded(.success(quote)))
        } catch {
            await send(.dailyQuoteLoaded(.failure(.defaultError)))
        }
    }
```

이렇게 하면 비동기 작업도 테스트하기 쉽고, 화면 상태 변경 경로가 Reducer로 모인다.

## 5. `await send`

TCA의 `Effect.run` 안에서는 비동기 작업 결과를 Action으로 다시 보낸다.

```swift
await send(.dailyQuoteLoaded(.success(quote)))
```

Android에서는 ViewModel 안에서 바로 state를 업데이트하는 경우가 많다.

```kotlin
updateState { copy(quote = quote) }
```

TCA에서는 Effect가 직접 State를 바꾸지 않는다.

```text
Effect
-> await send(Action)
-> Reducer가 Action 처리
-> State 변경
```

이 규칙의 장점:

- 상태 변경 위치가 Reducer 한 곳으로 모인다.
- 테스트에서 Action 순서를 검증하기 쉽다.
- API 성공/실패, 버튼 클릭, 화면 진입이 모두 같은 흐름으로 처리된다.

## 6. Cancellation

비동기 작업은 취소될 수 있다.

Android:

```kotlin
val job = viewModelScope.launch {
    search(query)
}
job.cancel()
```

Swift/TCA:

```swift
return .run { send in
    let result = try await searchUseCase(query)
    await send(.searchResponse(result))
}
.cancellable(id: CancelID.search, cancelInFlight: true)
```

`cancelInFlight: true`는 같은 id의 이전 작업이 있으면 취소하고 새 작업을 시작한다는 뜻이다.

취소가 필요한 대표 상황:

- 검색어 입력이 바뀔 때 이전 검색 요청 취소
- 화면이 사라질 때 진행 중인 작업 취소
- 타이머 또는 polling 중단
- 업로드/다운로드 중단

Swift cancellation은 강제 종료가 아니라 협력적이다.

```swift
while !Task.isCancelled {
    try await clock.sleep(for: .seconds(1))
}
```

작업이 취소되면 `CancellationError`가 발생할 수 있다.

```swift
do {
    let result = try await load()
    await send(.loaded(result))
} catch is CancellationError {
    // 보통 화면 에러로 표시하지 않는다.
} catch {
    await send(.failed)
}
```

## 7. MainActor

iOS UI 작업은 main thread 성격의 실행 문맥에서 처리되어야 한다. Swift concurrency에서는 이를 `MainActor`로 표현한다.

```swift
@MainActor
func updateUI() {
}
```

필요하면 특정 코드만 main actor에서 실행할 수 있다.

```swift
await MainActor.run {
    // UI 프레임워크 접근
}
```

Android 비교:

```kotlin
withContext(Dispatchers.Main) {
    // UI 관련 작업
}
```

이 프로젝트 기준:

- SwiftUI View는 UI를 그린다.
- TCA Reducer는 State 변경 흐름을 관리한다.
- UseCase, Repository, APIClient는 UI와 분리되어야 하므로 기본적으로 `MainActor`에 묶지 않는다.

흔한 실수:

```swift
@MainActor
final class APIClient {
    func send() async throws -> Response {
        ...
    }
}
```

APIClient 전체를 `MainActor`에 묶으면 네트워크/파싱 작업까지 UI actor와 연결될 수 있다. UI가 아닌 레이어는 main actor에 묶지 않는 편이 좋다.

## 8. actor

`actor`는 여러 비동기 작업이 같은 mutable state를 동시에 건드리지 못하게 보호하는 타입이다.

```swift
actor TokenMemoryStore {
    private var token: String?

    func setToken(_ value: String) {
        token = value
    }

    func getToken() -> String? {
        token
    }
}
```

actor 밖에서 actor 메서드를 호출하면 보통 `await`가 필요하다.

```swift
let token = await tokenStore.getToken()
```

Android 비교:

- `Mutex`로 보호하는 저장소
- single-thread dispatcher
- synchronized 접근

차이점:

- Swift actor는 언어 차원에서 isolation을 제공한다.
- actor 내부 state는 외부에서 직접 접근할 수 없다.
- 컴파일러가 일부 잘못된 접근을 막아준다.

주의할 점:

actor 안에서도 `await`를 만나면 다른 호출이 끼어들 수 있다. 이것을 actor reentrancy라고 한다. 심화 내용은 `interview.md`에서 다룬다.

## 9. Sendable

`Sendable`은 어떤 값이 task나 actor 경계를 넘어 전달되어도 안전하다는 뜻이다.

안전한 예:

```swift
struct User: Sendable {
    let id: Int
    let name: String
}
```

`Int`, `String`, `Bool` 같은 기본 value type은 대부분 안전하게 볼 수 있다.

주의가 필요한 예:

```swift
final class Counter {
    var value = 0
}
```

`Counter`는 여러 task가 동시에 `value`를 바꾸면 data race가 생길 수 있다.

## 10. @Sendable

`@Sendable`은 클로저가 동시성 경계를 넘어 안전하게 전달되고 실행될 수 있어야 한다는 표시다.

TCA dependency에서 자주 본다.

```swift
struct HomeClient {
    var getDailyQuote: @Sendable (String) async throws -> DailyQuote
}
```

읽는 법:

```text
String을 받아서
비동기로 실행되고
실패할 수 있고
DailyQuote를 반환하는
동시성 안전 클로저
```

좋은 예:

```swift
let useCase = GetDailyQuoteUseCase(homeRepository: repository)

return HomeClient(
    getDailyQuote: { date in
        try await useCase(quoteDate: date)
    }
)
```

위 코드는 dependency 클로저가 외부 mutable 변수를 직접 바꾸지 않고 UseCase를 호출한다.

나쁜 예:

```swift
var count = 0

let load: @Sendable () async -> Void = {
    count += 1
}
```

여러 task가 동시에 실행되면 `count`가 꼬일 수 있다.

해결 방법:

- mutable state는 actor 안에 둔다.
- TCA State처럼 Reducer 한 곳에서만 바꾼다.
- 클로저는 immutable 값과 UseCase/Repository 호출만 캡처하게 한다.

## 11. UseCase와 비동기

이 프로젝트의 목표 구조는 다음과 같다.

```text
Reducer
-> @Dependency use case client
-> Domain UseCase
-> Repository protocol
-> Data Repository implementation
-> API / DB / UserDefaults / Keychain
```

로그인 예:

```swift
struct LoginUseCase {
    let authRepository: AuthRepository
    let localRepository: LocalRepository

    func callAsFunction(_ request: LoginRequest) async throws -> LoginResponse {
        let response = try await authRepository.login(request)

        try await localRepository.setAccessToken(response.accessToken)
        try await localRepository.setRefreshToken(response.refreshToken)

        return response
    }
}
```

Android 비교:

```kotlin
class LoginUseCase @Inject constructor(
    private val authRepository: AuthRepository,
    private val localRepository: LocalRepository,
) {
    suspend operator fun invoke(request: LoginRequest): LoginResponse {
        val response = authRepository.login(request)
        localRepository.setAccessToken(response.accessToken)
        localRepository.setRefreshToken(response.refreshToken)
        return response
    }
}
```

Reducer는 로그인 후 토큰 저장 같은 세부 흐름을 몰라도 된다.

```swift
let response = try await loginUseCase.login(request)
```

## 12. 자주 하는 실수

### View에서 직접 API 호출

피해야 할 형태:

```swift
.task {
    let quote = try await apiClient.getQuote()
}
```

프로젝트 기준:

```text
View -> Action -> Reducer -> Effect.run -> UseCase
```

### Reducer에서 APIClient 직접 생성

피해야 할 형태:

```swift
let apiClient = APIClient()
let quote = try await apiClient.send(...)
```

Reducer는 concrete API 구현을 몰라야 한다.

### 모든 것을 MainActor에 올리기

UI가 아닌 API/DB 작업까지 main actor에 묶으면 좋지 않다.

### `@Sendable` 경고를 무시하기

`@Sendable` 경고는 data race 가능성을 알려주는 신호일 수 있다. 단순히 경고를 없애기보다 mutable state 소유권을 다시 봐야 한다.

## 13. 다음에 읽을 문서

1. `README.md`로 전체 학습 순서를 확인한다.
2. `interview.md`로 면접 질문과 심화 개념을 점검한다.
3. `../tca-basic-guide.md`에서 TCA의 `Effect.run`과 연결해서 본다.

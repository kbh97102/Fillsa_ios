# TCA Advanced Guide

이 문서는 TCA의 심화 개념을 설명한다.

기초 문서 `docs/tca-basic-guide.md`를 먼저 읽는 것을 전제로 한다.

## 1. SwiftUI 생명주기와 TCA

SwiftUI View는 Android Activity나 Fragment처럼 오래 살아 있는 객체라고 생각하면 안 된다.

SwiftUI View는 값 타입이고, State 변화에 따라 자주 다시 만들어질 수 있다.

그래서 생명주기 이벤트도 Android와 다르게 이해해야 한다.

| SwiftUI | Android 느낌 | 주의점 |
|---|---|---|
| `.onAppear` | `onStart`, `onResume` 느낌 | 여러 번 호출될 수 있음 |
| `.onDisappear` | `onStop` 느낌 | 화면 구조에 따라 자주 호출될 수 있음 |
| `.task` | `LaunchedEffect` 느낌 | View가 사라지면 task 취소 가능 |
| `scenePhase` | 앱 foreground/background | 앱 전체 상태 |

TCA에서는 생명주기 이벤트를 View에서 직접 처리하지 않고 Action으로 보낸다.

```swift
.onAppear {
    viewStore.send(.onAppear)
}
```

Reducer:

```swift
case .onAppear:
    guard !state.hasLoaded, !state.isLoading else { return .none }
    return load(state: &state)
```

## 2. onAppear가 여러 번 호출되는 이유

`.onAppear`는 다음 상황에서 여러 번 호출될 수 있다.

- 탭을 바꾸고 다시 돌아온다.
- Navigation으로 이동했다가 뒤로 온다.
- 조건부 View가 다시 나타난다.
- 부모 View의 상태가 바뀌면서 하위 View가 재구성된다.
- 리스트 셀이 화면에 다시 들어온다.

그래서 API 호출을 View에 직접 넣으면 중복 요청이 생긴다.

나쁜 예:

```swift
.onAppear {
    Task {
        let quote = try await api.getQuote()
        self.quote = quote
    }
}
```

좋은 예:

```swift
.onAppear {
    viewStore.send(.onAppear)
}
```

Reducer에서 중복 방지:

```swift
case .onAppear:
    guard !state.hasLoaded, !state.isLoading else { return .none }
    state.isLoading = true
    return .run { send in
        ...
    }
```

## 3. .task를 쓰는 경우

`.task`는 async 작업과 View 생명주기를 연결한다.

TCA에서는 보통 Action만 보낸다.

```swift
.task {
    await viewStore.send(.task).finish()
}
```

Reducer:

```swift
case .task:
    return .run { send in
        let data = try await client.load()
        await send(.loaded(data))
    }
```

선택 기준:

| 상황 | 추천 |
|---|---|
| 화면 표시 시 단순 로드 | `.onAppear` Action |
| task 완료를 기다리는 테스트가 중요 | `.task` Action |
| View가 사라질 때 자동 취소가 중요 | `.task` + cancellable Effect |
| 검색/입력 debounce | Action + `.cancellable` |

## 4. Effect cancellation

복잡한 화면에서는 이전 작업을 취소해야 한다.

예: 검색어 입력

```text
"a" 입력 -> 검색 요청
"ab" 입력 -> 이전 요청 취소, 새 요청
"abc" 입력 -> 이전 요청 취소, 새 요청
```

TCA에서는 cancellation ID를 만든다.

```swift
enum CancelID {
    case search
}
```

Effect에 ID를 붙인다.

```swift
return .run { send in
    try await clock.sleep(for: .milliseconds(300))
    let result = try await searchClient.search(text)
    await send(.searchResponse(result))
}
.cancellable(id: CancelID.search, cancelInFlight: true)
```

`cancelInFlight: true`는 같은 ID의 이전 Effect를 취소하고 새 Effect를 시작한다.

Android로 보면:

```kotlin
searchJob?.cancel()
searchJob = viewModelScope.launch {
    delay(300)
    val result = repository.search(text)
    updateState { copy(result = result) }
}
```

## 5. onDisappear에서 취소하기

화면이 사라질 때 진행 중인 작업을 멈추고 싶으면 `.onDisappear` Action을 보낸다.

View:

```swift
.onDisappear {
    viewStore.send(.onDisappear)
}
```

Reducer:

```swift
case .onDisappear:
    return .cancel(id: CancelID.load)
```

이 패턴은 다음에 유용하다.

- 긴 API 요청
- polling
- 타이머
- 음성 녹음
- 위치 추적
- 검색 debounce

## 6. Timer와 long-running Effect

타이머처럼 계속 Action을 보내는 Effect도 있다.

```swift
enum CancelID {
    case timer
}

case .timerStarted:
    return .run { send in
        while !Task.isCancelled {
            try await clock.sleep(for: .seconds(1))
            await send(.timerTicked)
        }
    }
    .cancellable(id: CancelID.timer)

case .timerStopped:
    return .cancel(id: CancelID.timer)
```

Android의 `while(isActive)` coroutine과 비슷하다.

```kotlin
timerJob = viewModelScope.launch {
    while (isActive) {
        delay(1000)
        dispatch(TimerTicked)
    }
}
```

## 7. Clock dependency

테스트 가능한 시간 처리를 위해 TCA는 clock dependency를 쓸 수 있다.

```swift
@Dependency(\.continuousClock) var clock
```

Effect:

```swift
try await clock.sleep(for: .milliseconds(300))
```

테스트에서는 clock을 가짜로 바꾸고 시간을 직접 진행시킬 수 있다.

Android에서 `TestCoroutineScheduler`로 delay를 제어하는 것과 비슷하다.

## 8. MainActor와 Reducer

SwiftUI 상태 변경은 main thread, 즉 `MainActor`와 관련이 있다.

TCA에서는 State 변경을 Reducer 안에서 처리하면 대부분 안전하다.

```swift
case let .loaded(data):
    state.data = data
    return .none
```

Effect 안에서는 State를 직접 만지지 않고 Action을 보낸다.

```swift
await send(.loaded(data))
```

`MainActor-isolated` 에러가 나면 보통 다음 문제다.

- main actor에서만 호출 가능한 함수를 다른 actor context에서 호출했다.
- 동기 함수에서 actor-isolated 함수를 호출했다.
- UI 관련 객체를 background 작업에서 접근했다.

해결 방향:

- Effect 결과를 Action으로 보내 Reducer에서 처리한다.
- UI 관련 코드는 View 또는 MainActor 영역으로 보낸다.
- DB/API 유틸 함수가 불필요하게 `@MainActor`에 묶이지 않았는지 확인한다.

## 9. 부모/자식 Feature 조합

부모 Feature는 자식 Feature의 State와 Action을 가진다.

```swift
@ObservableState
struct State: Equatable {
    var home = HomeFeature.State()
    var calendar = CalendarFeature.State()
}

enum Action: Equatable {
    case home(HomeFeature.Action)
    case calendar(CalendarFeature.Action)
}
```

Reducer body에서 `Scope`로 연결한다.

```swift
var body: some Reducer<State, Action> {
    Scope(state: \.home, action: \.home) {
        HomeFeature()
    }

    Scope(state: \.calendar, action: \.calendar) {
        CalendarFeature()
    }

    Reduce { state, action in
        ...
    }
}
```

부모가 할 일:

- 화면 이동
- 탭 선택
- 자식 간 데이터 전달
- 앱 전체 공통 상태 관리

자식이 할 일:

- 자기 화면의 입력 처리
- 자기 화면의 API/DB 작업
- 자기 화면 State 관리

## 10. 부모가 자식 Action을 감시하는 경우

자식의 특정 Action에 부모가 반응해야 할 수 있다.

예:

```swift
case .typing(.delegate(.back)):
    state.screen = .main
    state.selectedTab = .home
    state.home = HomeFeature.State()
    return .none
```

이 뜻:

```text
TypingFeature가 back 이벤트를 부모에게 올림
-> AppFeature가 화면을 main으로 변경
-> home tab 선택
-> home state 재생성
```

Android에서는 navigation event를 상위 Composable이 받고 navController로 이동하는 것과 비슷하다.

## 11. Optional child state

항상 존재하지 않는 화면은 optional state로 둘 수 있다.

예:

```swift
@ObservableState
struct State: Equatable {
    var detail: DetailFeature.State?
}

enum Action: Equatable {
    case detail(DetailFeature.Action)
}
```

상세 화면 열기:

```swift
case let .detailButtonTapped(item):
    state.detail = DetailFeature.State(item: item)
    return .none
```

상세 화면 닫기:

```swift
case .detail(.delegate(.close)):
    state.detail = nil
    return .none
```

이 방식은 sheet, fullScreenCover, dialog 상태에 유용하다.

## 12. Navigation stack

여러 단계로 push되는 화면은 stack 상태로 관리할 수 있다.

개념:

```text
Root
-> Detail
-> MemoEdit
-> Share
```

TCA에는 stack navigation을 위한 타입들이 있지만, 현재 프로젝트는 Android parity를 우선하고 화면 구조가 단순해서 `AppFeature.State.screen` enum 기반 라우팅을 사용하고 있다.

현재 구조:

```swift
var screen: AppScreen = .splash
```

화면 변경:

```swift
state.screen = .typing
```

나중에 push stack이 복잡해지면 TCA stack navigation으로 바꿀 수 있다.

## 13. Tab 상태

탭은 보통 부모 Feature가 관리한다.

```swift
var selectedTab: AppTab = .home
```

Action:

```swift
case selectedTabChanged(AppTab)
```

Reducer:

```swift
case let .selectedTabChanged(tab):
    state.selectedTab = tab
    return .none
```

탭별 State를 유지할지 초기화할지는 제품 동작에 따라 결정한다.

이 프로젝트는 Android 앱 동작을 기준으로 맞춰야 한다.

## 14. Alert, Dialog, Sheet

TCA에서는 alert, dialog, sheet도 State로 다룬다.

단순한 방식:

```swift
@ObservableState
struct State: Equatable {
    var isLoginDialogPresented = false
}

enum Action: Equatable {
    case imageTapped
    case loginDialogDismissed
}
```

Reducer:

```swift
case .imageTapped:
    state.isLoginDialogPresented = true
    return .none

case .loginDialogDismissed:
    state.isLoginDialogPresented = false
    return .none
```

View:

```swift
.alert(
    "로그인이 필요합니다",
    isPresented: viewStore.binding(
        get: \.isLoginDialogPresented,
        send: { _ in .loginDialogDismissed }
    )
) {
    ...
}
```

더 복잡한 alert/sheet는 별도 child Feature로 분리할 수 있다.

## 15. Presentation state

TCA에는 sheet, alert, navigation destination을 더 구조적으로 다루는 presentation 기능이 있다.

개념적으로는 다음과 같다.

```swift
@Presents var destination: Destination.State?

enum Destination {
    case alert(AlertState<AlertAction>)
    case detail(DetailFeature)
}
```

이 방식의 장점:

- sheet/alert/destination lifecycle을 TCA가 더 잘 관리한다.
- child reducer와 연결하기 쉽다.
- 테스트에서 presentation 상태를 검증하기 좋다.

다만 초보 단계에서는 `isPresented`, optional child state, `screen` enum 방식이 이해하기 쉽다. 프로젝트가 복잡해지면 presentation 방식으로 전환할 수 있다.

## 16. Dependency override

TCA dependency는 실행 환경에 따라 바꿀 수 있다.

실제 앱:

```swift
static let liveValue = HomeClient(...)
```

테스트:

```swift
let store = TestStore(initialState: HomeFeature.State()) {
    HomeFeature()
} withDependencies: {
    $0.homeClient.getDailyQuoteNoToken = { _ in
        DailyQuote(korQuote: "테스트")
    }
}
```

preview:

```swift
HomeView(
    store: Store(initialState: HomeFeature.State()) {
        HomeFeature()
    } withDependencies: {
        $0.homeClient.getDailyQuoteNoToken = { _ in
            DailyQuote(korQuote: "프리뷰 명언")
        }
    }
)
```

Android의 Hilt test module, fake repository와 같은 목적이다.

## 17. TestStore

TCA 테스트는 `TestStore`를 사용한다.

기본 형태:

```swift
let store = TestStore(initialState: CounterFeature.State()) {
    CounterFeature()
}

await store.send(.plusButtonTapped) {
    $0.count = 1
}
```

Effect 결과 테스트:

```swift
await store.send(.onAppear) {
    $0.isLoading = true
}

await store.receive(.dailyQuoteLoaded(.success(expectedQuote))) {
    $0.quote = expectedQuote
    $0.isLoading = false
    $0.hasLoaded = true
}
```

중요한 점:

```text
send = 테스트가 Action을 보냄
receive = Effect가 보낸 Action을 기다림
```

Android ViewModel 테스트에서 Action을 넣고 StateFlow 값을 검증하는 것과 비슷하다.

## 18. Equatable이 필요한 이유

TCA State와 Action은 보통 `Equatable`을 붙인다.

```swift
struct State: Equatable { ... }
enum Action: Equatable { ... }
```

이유:

- 테스트에서 상태 변화 비교
- View update 최적화
- Action receive 검증

만약 어떤 타입이 `Equatable`이 아니면 State나 Action에 넣기 어렵다.

이때 선택지는 다음이다.

- 해당 타입에 `Equatable` 추가
- 화면에 필요한 값만 별도 model로 변환
- 비교할 필요 없는 객체는 State에 넣지 않기
- dependency로 빼기

## 19. Sendable이 필요한 이유

Swift concurrency에서는 async 작업이 thread/actor 경계를 넘을 수 있다.

TCA dependency closure에는 `@Sendable`이 붙는 경우가 많다.

```swift
var getDailyQuoteNoToken: @Sendable (String) async throws -> DailyQuote
```

의미:

```text
이 closure는 concurrency 환경에서 안전하게 전달될 수 있어야 한다.
```

처음에는 "async 작업에서 안전하게 쓸 함수"라고 이해해도 충분하다.

## 20. Shared state

여러 화면이 같은 값을 써야 할 수 있다.

예:

- 로그인 상태
- 테마
- 알림 설정
- 사용자 정보

선택지는 여러 가지다.

| 방식 | 설명 |
|---|---|
| 부모 State에 두고 자식에게 전달 | 가장 명확함 |
| use case dependency로 읽기/쓰기 | 저장소 기준 값을 Feature에서 필요할 때 조회 |
| TCA shared state 기능 | 여러 Feature가 같은 state를 공유 |

이 프로젝트에서는 초반에는 부모 `AppFeature`와 use case dependency 조합을 우선 사용한다.

로그인 여부처럼 저장소가 기준인 값은 `sessionClient`로 읽는다.

## 21. Derived state

State에 모든 값을 저장할 필요는 없다.

예:

```swift
var isNextEnabled: Bool {
    date < Date()
}
```

계산 가능한 값은 computed property로 만들 수 있다.

단, 현재 시간이 들어가는 계산은 테스트와 일관성을 위해 dependency를 쓰는 편이 좋다.

좋은 State:

```swift
var date: Date
```

View 또는 helper에서 계산:

```swift
let title = DateFormatter.fillsaYearMonth.string(from: date)
```

## 22. Fat Reducer 피하기

Reducer가 너무 커지면 읽기 어렵다.

분리 기준:

- 화면 단위로 Feature 분리
- 반복 UI가 독립 로직을 가지면 child Feature 고려
- API/DB 변환 로직은 Repository 또는 mapper로 이동
- 날짜 formatting은 support/helper로 이동
- 디자인만 담당하는 코드는 View component로 이동

하지만 너무 빨리 쪼개면 오히려 복잡하다. Android ViewModel을 옮길 때는 먼저 같은 단위로 Feature를 만들고, 복잡해지는 지점에서 분리한다.

## 23. Reducer 안에서 helper 함수 사용

Reducer body가 길어질 때 helper를 둘 수 있다.

```swift
private func load(state: inout State) -> Effect<Action> {
    state.isLoading = true
    let quoteDate = FillsaCalendarDateSupport.quoteDateString(for: state.date)

    return .run { send in
        ...
    }
}
```

주의:

- helper가 State를 바꾸면 `inout State`로 명확히 받는다.
- helper가 Effect를 만들면 `Effect<Action>`을 반환한다.
- helper 안에서도 외부 작업은 Effect 안에 넣는다.

## 24. Optimistic update

좋아요 버튼처럼 먼저 UI를 바꾸고 나중에 API 결과를 받는 방식을 optimistic update라고 한다.

현재 홈 좋아요 로직이 이 방식에 가깝다.

```swift
case let .likeTapped(isLike):
    state.quote = DailyQuote(
        likeYn: isLike ? "Y" : "N",
        ...
    )

    return .run { send in
        let response = try await homeClient.postLike(...)
        await send(.likeUpdated(.success(response)))
    }
```

장점:

- UI 반응이 빠르다.

단점:

- API 실패 시 되돌리는 로직이 필요할 수 있다.

Android에서도 좋아요 토글에서 자주 쓰는 방식이다.

## 25. 실패 시 rollback

optimistic update를 했는데 실패하면 이전 값으로 되돌려야 할 수 있다.

패턴:

```swift
case let .likeTapped(isLike):
    let previous = state.quote.likeYn
    state.quote.likeYn = isLike ? "Y" : "N"

    return .run { send in
        do {
            try await client.like(isLike)
            await send(.likeResponse(.success(())))
        } catch {
            await send(.likeResponse(.failure(previous)))
        }
    }

case let .likeResponse(.failure(previous)):
    state.quote.likeYn = previous
    return .none
```

실제 프로젝트에서는 model이 struct라 값 복사가 필요할 수 있다.

## 26. Local DB와 TCA

DB 작업은 Effect에서 dependency를 통해 수행한다.

```swift
@Dependency(\.localQuoteClient) var localQuoteClient
```

읽기:

```swift
return .run { send in
    let quote = try await localQuoteClient.findById(id)
    await send(.localQuoteLoaded(quote))
}
```

쓰기:

```swift
return .run { send in
    try await localQuoteClient.updateMemo(memo, id)
    await send(.memoSaved(.success(id)))
}
```

DB 결과도 Action으로 돌아와야 한다.

## 27. API와 TCA

API 호출도 같은 방식이다.

```swift
return .run { send in
    do {
        let response = try await quoteListClient.getMemberQuotes(...)
        await send(.quoteListLoaded(.success(response)))
    } catch let error as ErrorResponse {
        await send(.quoteListLoaded(.failure(error)))
    }
}
```

API client 자체는 Feature에서 만들지 않는다.

```text
Feature
-> @Dependency client
-> Domain UseCase
-> Repository
-> APIClient / Alamofire
```

이 구조를 지켜야 Reducer가 API/DB 세부 구현을 모르고, 로그인 후 로컬 저장처럼 여러 작업을 묶는 흐름을 UseCase에 둘 수 있다.

## 28. 앱 생명주기 scenePhase

앱 전체 foreground/background는 `scenePhase`로 볼 수 있다.

View:

```swift
@Environment(\.scenePhase) private var scenePhase
```

변화 전달:

```swift
.onChange(of: scenePhase) { _, newPhase in
    viewStore.send(.scenePhaseChanged(newPhase))
}
```

Reducer:

```swift
case let .scenePhaseChanged(phase):
    switch phase {
    case .active:
        return refreshIfNeeded(state: &state)
    case .background:
        return saveIfNeeded(state: &state)
    default:
        return .none
    }
```

주의:

Android에 없는 동작을 임의로 추가하면 안 된다. 이 프로젝트에서는 Android 동작 확인 후 필요한 경우에만 적용한다.

## 29. 화면 이동 설계 기준

화면 이동은 가능하면 부모 Feature가 담당한다.

이유:

- 자식 Feature가 앱 전체 navigation을 몰라도 된다.
- 화면 이동 테스트가 쉬워진다.
- Android NavHost처럼 중앙에서 route를 볼 수 있다.

예:

```swift
case .homeTypingSelected:
    state.screen = .typing
    state.typing = TypingFeature.State(...)
    return .none
```

자식 Feature가 직접 "어느 화면으로 갈지"를 많이 알게 되면 결합도가 커진다.

## 30. TCA에서 자주 하는 실수

자주 하는 실수:

- View에서 API 호출
- Effect 안에서 State 변경 시도
- Reducer에서 실제 APIClient 직접 생성
- `.onAppear`마다 API 중복 호출
- 성공 케이스에서만 `isLoading = false`
- 실패 Action을 만들지 않음
- 부모/자식 Action을 무분별하게 섞음
- 화면 이동을 여러 View에 흩뿌림
- 테스트 불가능한 현재 시간/랜덤값 직접 사용
- State에 거대한 UIKit 객체나 reference type 저장

## 31. 복잡한 화면 설계 순서

복잡한 화면은 다음 순서로 설계한다.

1. 화면에 보이는 데이터 목록을 적는다.
2. 사용자가 할 수 있는 행동을 모두 적는다.
3. Android ViewModel의 action/effect를 확인한다.
4. API/DB 호출을 구분한다.
5. State를 최소 단위로 만든다.
6. Action을 사용자 입력과 결과 Action으로 나눈다.
7. 로딩/에러/empty 상태를 명시한다.
8. 중복 호출과 취소가 필요한 Effect를 표시한다.
9. 화면 이동은 delegate 또는 부모 Action으로 뺀다.
10. View는 작은 컴포넌트로 쪼갠다.

## 32. 이 프로젝트에서 적용할 원칙

이 프로젝트는 Android 앱을 iOS로 옮기는 작업이다.

따라서 TCA를 쓰더라도 제품 동작은 Android가 기준이다.

원칙:

- Android ViewModel의 책임은 iOS Feature로 옮긴다.
- Android UseCase는 Domain UseCase로 옮기고, `Core/Dependencies`에서 TCA dependency로 노출한다.
- Android Repository는 Domain protocol과 Data implementation으로 나눈다.
- Android local DB 동작은 LocalRepository와 local use case로 옮긴다.
- Android navigation 흐름은 `AppFeature`에서 재현한다.
- Android에 없는 UI/기능은 추가하지 않는다.
- 화면 구현 전 `docs/screens/` 기획서를 확인한다.

## 33. 심화 체크리스트

복잡한 Feature를 구현한 뒤 아래를 확인한다.

- 화면 진입 Effect가 중복 호출되지 않는가?
- 화면 이탈 시 취소해야 하는 Effect가 취소되는가?
- 검색/입력처럼 이전 요청을 취소해야 하는 로직에 cancellation ID가 있는가?
- 부모/자식 Feature 책임이 분리되어 있는가?
- 자식이 부모에게 알릴 이벤트는 delegate Action으로 올라가는가?
- alert/sheet/navigation 상태가 State로 관리되는가?
- API/DB 실패가 Action으로 들어오는가?
- 테스트에서 dependency를 fake로 바꿀 수 있는가?
- `State`와 `Action`이 지나치게 거대하지 않은가?
- Android parity를 깨는 임의 동작이 없는가?

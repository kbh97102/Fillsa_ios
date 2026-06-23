# TCA Guide for Android Developers

이 문서는 Swift/iOS를 처음 보는 Android 개발자를 기준으로, 이 프로젝트에서 사용하는 TCA(The Composable Architecture)를 단계별로 설명한다.

더 체계적으로 학습할 때는 `docs/tca-learning-roadmap.md`를 먼저 보고, `docs/tca-basic-guide.md`, `docs/tca-advanced-guide.md` 순서로 읽는다.

Swift 비동기 처리 자체가 낯설다면 TCA 문서보다 먼저 `docs/async/README.md`를 읽는다. 더 자세한 기초 설명은 `docs/async/basics.md`, 면접/심화 질문은 `docs/async/interview.md`에 정리한다.

이 프로젝트의 기준은 다음과 같다.

- Android의 ViewModel + MVI 구조를 iOS에서는 TCA Feature로 옮긴다.
- SwiftUI View는 화면만 그린다.
- Reducer는 상태 변경과 비즈니스 흐름을 담당한다.
- API, DB, 설정 저장소 같은 외부 작업은 Domain UseCase 뒤에 숨기고, Feature는 `@Dependency`로 use case dependency를 가져온다.
- 화면 이동은 상위 Feature인 `AppFeature`에서 관리한다.

## 1. TCA를 한 문장으로 이해하기

TCA는 SwiftUI에서 MVI를 안정적으로 쓰기 위한 구조다.

Android식으로 말하면 아래를 하나의 규칙으로 묶어둔 것이다.

| Android | iOS TCA |
|---|---|
| `ViewModel` | `Feature` + `Reducer` |
| `UiState` | `State` |
| `Intent`, `Action`, `Event` | `Action` |
| `viewModelScope.launch` | `Effect`, `.run` |
| Hilt로 주입받는 UseCase | `@Dependency`로 등록한 use case dependency |
| Compose UI | SwiftUI `View` |
| Navigation state | `AppFeature.State.screen` 같은 상태 |

즉 TCA에서 핵심 흐름은 항상 같다.

```text
View에서 사용자가 뭔가 함
-> Action 전송
-> Reducer가 Action 처리
-> State 변경
-> View가 State를 보고 다시 그림
-> 필요하면 Effect로 API/DB 작업 실행
-> Effect 결과를 다시 Action으로 보냄
```

Android MVI와 거의 같은 흐름이다.

## 2. Feature는 Android ViewModel에 가장 가깝다

우리 프로젝트의 홈 화면은 `HomeFeature`가 담당한다.

```swift
@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var quote = DailyQuote()
        var date = Date()
        var isLoggedIn = false
        var hasLoaded = false
        var isLoading = false
    }

    enum Action: Equatable {
        case onAppear
        case beforeTapped
        case nextTapped
        case dailyQuoteLoaded(Result<DailyQuote, ErrorResponse>)
    }
}
```

Android로 바꾸면 대략 이런 느낌이다.

```kotlin
data class HomeState(
    val quote: DailyQuote = DailyQuote(),
    val date: LocalDate = LocalDate.now(),
    val isLoggedIn: Boolean = false,
    val hasLoaded: Boolean = false,
    val isLoading: Boolean = false,
)

sealed interface HomeAction {
    data object OnAppear : HomeAction
    data object BeforeTapped : HomeAction
    data object NextTapped : HomeAction
    data class DailyQuoteLoaded(
        val result: Result<DailyQuote>
    ) : HomeAction
}
```

차이는 `ViewModel`이라는 클래스가 직접 있는 것이 아니라, `Feature` 안에 `State`, `Action`, `Reducer`가 같이 들어간다는 점이다.

## 3. State는 화면의 현재 값이다

`State`는 화면이 그려질 때 필요한 값의 모음이다.

홈 화면에서는 다음 값들이 상태다.

```swift
var quote = DailyQuote()
var date = Date()
var isLoggedIn = false
var hasLoaded = false
var isLoading = false
```

Android에서 `StateFlow<HomeUiState>`로 들고 있던 값과 비슷하다.

중요한 규칙은 다음과 같다.

- View는 `State`를 읽어서 UI를 그린다.
- View가 직접 `State`를 고치지 않는다.
- `State` 변경은 Reducer 안에서만 한다.
- 화면에 표시되지 않더라도 화면 로직에 필요한 값이면 `State`에 둔다.

예를 들어 `hasLoaded`는 UI에 직접 보이지 않을 수 있지만, `onAppear`가 여러 번 불리는 것을 막기 위해 필요하다.

## 4. Action은 사용자의 의도와 비동기 결과다

`Action`은 화면에서 발생하는 모든 사건이다.

```swift
enum Action: Equatable {
    case onAppear
    case beforeTapped
    case nextTapped
    case loginStatusLoaded(Bool)
    case dailyQuoteLoaded(Result<DailyQuote, ErrorResponse>)
    case likeTapped(Bool)
    case likeUpdated(Result<Int, ErrorResponse>)
    case localLikeUpdated(Result<Int, ErrorResponse>)
}
```

Android MVI에서 `Intent` 또는 `Action`으로 부르던 것과 같다.

Action은 크게 두 종류로 나눌 수 있다.

| 종류 | 예시 | 의미 |
|---|---|---|
| 사용자 입력 | `beforeTapped`, `nextTapped`, `likeTapped` | 버튼 클릭, 탭, 입력 |
| 작업 결과 | `dailyQuoteLoaded`, `likeUpdated` | API/DB 작업이 끝난 결과 |

TCA에서는 API 결과도 Action으로 다시 들어온다. 이게 중요하다.

```text
버튼 클릭 Action
-> Reducer
-> API Effect 실행
-> API 결과 Action
-> Reducer
-> State 변경
```

그래서 상태 변경 경로가 한 군데로 모인다.

## 5. Reducer는 Android ViewModel의 action 처리부다

Reducer는 `Action`을 받아서 `State`를 바꾸고, 필요하면 `Effect`를 반환한다.

```swift
var body: some Reducer<State, Action> {
    Reduce { state, action in
        switch action {
        case .onAppear:
            guard !state.hasLoaded, !state.isLoading else { return .none }
            return load(state: &state)

        case .beforeTapped:
            state.date = ...
            state.hasLoaded = false
            return load(state: &state)

        case let .dailyQuoteLoaded(.success(quote)):
            state.quote = quote
            state.hasLoaded = true
            state.isLoading = false
            return .none
        }
    }
}
```

Android ViewModel로 생각하면 아래와 비슷하다.

```kotlin
fun handleAction(action: HomeAction) {
    when (action) {
        HomeAction.OnAppear -> {
            if (state.hasLoaded || state.isLoading) return
            load()
        }

        HomeAction.BeforeTapped -> {
            updateState { copy(date = date.minusDays(1), hasLoaded = false) }
            load()
        }

        is HomeAction.DailyQuoteLoaded -> {
            updateState {
                copy(
                    quote = action.quote,
                    hasLoaded = true,
                    isLoading = false
                )
            }
        }
    }
}
```

TCA에서는 `state`를 직접 바꾼다.

```swift
state.isLoading = true
```

Swift에서는 Reducer 안에서 `state`가 `inout`처럼 들어온다. Android처럼 `copy()`를 직접 호출하지 않아도, TCA가 변경을 감지해서 View를 다시 그리게 해준다.

## 6. Effect는 coroutine 작업이다

API 호출, DB 읽기, UserDefaults/Keychain 접근, 알림 권한 요청처럼 시간이 걸리거나 외부 시스템과 통신하는 작업은 Reducer에서 바로 끝나지 않는다.

TCA에서는 이런 작업을 `Effect`라고 부른다.

```swift
return .run { send in
    do {
        let response = try await homeClient.getDailyQuoteNoToken(quoteDate)
        await send(.dailyQuoteLoaded(.success(response)))
    } catch {
        await send(.dailyQuoteLoaded(.failure(.defaultError)))
    }
}
```

Android로 보면 아래와 비슷하다.

```kotlin
viewModelScope.launch {
    try {
        val response = homeRepository.getDailyQuoteNoToken(quoteDate)
        handleAction(HomeAction.DailyQuoteLoaded(Result.success(response)))
    } catch (e: Throwable) {
        handleAction(HomeAction.DailyQuoteLoaded(Result.failure(e)))
    }
}
```

핵심은 `Effect` 안에서 직접 `state`를 바꾸지 않는다는 것이다.

비동기 작업이 끝나면 `send(...)`로 Action을 다시 보낸다. 그러면 Reducer가 그 Action을 받고 State를 바꾼다.

## 7. 왜 Effect 안에서 State를 직접 안 바꾸나

Android ViewModel에서는 coroutine 안에서 바로 `_state.update { ... }`를 해도 된다.

TCA는 더 엄격하다.

```text
State 변경은 Reducer에서만 한다.
Effect는 결과 Action만 보낸다.
```

이 규칙 덕분에 얻는 장점이 있다.

- 상태가 어디서 바뀌는지 추적하기 쉽다.
- 테스트가 쉬워진다.
- API 결과, 버튼 클릭, 화면 진입이 모두 같은 Action 흐름으로 정리된다.
- 화면이 복잡해져도 상태 변경 순서를 예측하기 쉽다.

처음에는 귀찮게 느껴질 수 있지만, Android에서 MVI를 엄격하게 쓰는 이유와 같다.

## 8. Dependency는 Hilt 주입과 비슷하다

홈 Feature에는 이런 코드가 있다.

```swift
@Dependency(\.homeClient) private var homeClient
@Dependency(\.localQuoteClient) private var localQuoteClient
@Dependency(\.sessionClient) private var sessionClient
```

Android로 보면 대략 이런 생성자 주입과 같다.

```kotlin
@HiltViewModel
class HomeViewModel @Inject constructor(
    private val homeUseCase: HomeUseCase,
    private val localQuoteUseCase: LocalQuoteUseCase,
    private val sessionUseCase: SessionUseCase,
) : ViewModel()
```

차이는 iOS에는 Hilt 같은 공식 DI 프레임워크가 기본으로 없다는 점이다. TCA는 `DependencyValues`라는 저장소를 제공하고, Feature는 `@Dependency`로 그 값을 꺼내 쓴다.

이 프로젝트의 목표 구조에서 dependency는 다음 역할을 한다.

```text
HomeFeature
-> @Dependency(\.homeClient)
-> HomeClient.liveValue
-> Domain UseCase
-> Repository protocol
-> Data Repository/API/DB 구현
```

`HomeClient` 같은 이름은 TCA가 테스트 가능한 함수 묶음을 주입하기 위한 어댑터다. Android의 UseCase 자체와 1:1로 같은 개념은 아니며, `liveValue`에서 Domain UseCase를 만들어 호출한다. 새 코드에서는 Reducer가 최종적으로 use case dependency를 호출하도록 설계한다.

테스트할 때는 `homeClient`를 가짜 구현으로 바꿀 수 있다.

```swift
let store = TestStore(initialState: HomeFeature.State()) {
    HomeFeature()
} withDependencies: {
    $0.homeClient.getDailyQuoteNoToken = { _ in
        DailyQuote(korQuote: "테스트 명언")
    }
}
```

Android에서 fake repository를 Hilt test module로 갈아끼우는 것과 목적이 같다.

## 9. Store는 ViewModel 인스턴스처럼 생각하면 된다

SwiftUI View는 TCA의 `Store`를 받는다.

```swift
HomeView(
    store: Store(initialState: HomeFeature.State()) {
        HomeFeature()
    }
)
```

`Store`는 다음을 들고 있다.

- 현재 `State`
- `Action`을 처리할 `Reducer`
- `Effect` 실행과 결과 전달 시스템

Android식으로 아주 단순화하면 `HomeViewModel` 인스턴스와 비슷하다.

```text
HomeViewModel
  - uiState
  - handleAction()
  - viewModelScope
```

TCA Store도 비슷하게 아래를 담당한다.

```text
Store
  - State 보관
  - Action 전달
  - Reducer 실행
  - Effect 실행
```

## 10. ViewStore는 SwiftUI View가 Store를 읽는 방법이다

SwiftUI View는 Store를 직접 다루기보다, 보통 `WithViewStore` 또는 `@Bindable` 같은 도구를 통해 State를 읽고 Action을 보낸다.

개념만 보면 아래와 같다.

```swift
WithViewStore(store, observe: { $0 }) { viewStore in
    Text(viewStore.quote.korQuote ?? "")

    Button("다음") {
        viewStore.send(.nextTapped)
    }
}
```

Android Compose와 비교하면 다음과 비슷하다.

```kotlin
val state by viewModel.state.collectAsState()

Text(state.quote.korQuote)

Button(
    onClick = { viewModel.handleAction(HomeAction.NextTapped) }
) {
    Text("다음")
}
```

중요한 점은 View가 로직을 갖지 않는다는 것이다.

View는 다음만 한다.

- State를 화면에 표시한다.
- 사용자 입력을 Action으로 보낸다.

## 11. SwiftUI 생명주기와 TCA

iOS SwiftUI에는 Android의 `onCreate`, `onStart`, `onResume`처럼 명확한 Activity 생명주기가 보이지 않는다.

SwiftUI는 View를 값처럼 자주 만들고 버린다. 그래서 Android처럼 "View 객체가 한 번 만들어지고 오래 산다"고 생각하면 헷갈린다.

SwiftUI에서 자주 쓰는 생명주기 진입점은 다음이다.

| SwiftUI | Android 느낌 | 설명 |
|---|---|---|
| `.onAppear` | `onStart`, `onResume`에 가까움 | View가 화면에 나타날 때 호출 |
| `.onDisappear` | `onStop`에 가까움 | View가 화면에서 사라질 때 호출 |
| `.task` | `LaunchedEffect`, `viewModelScope.launch` 느낌 | View 표시와 함께 async 작업 시작 |
| `scenePhase` | App foreground/background 상태 | 앱 전체가 활성/비활성/백그라운드인지 확인 |

하지만 TCA에서는 View 안에서 직접 API를 호출하지 않는다.

보통 이렇게 한다.

```swift
.onAppear {
    viewStore.send(.onAppear)
}
```

그 다음 실제 로직은 Reducer에서 처리한다.

```swift
case .onAppear:
    guard !state.hasLoaded, !state.isLoading else { return .none }
    return load(state: &state)
```

이 구조를 Android로 보면 다음과 같다.

```kotlin
LaunchedEffect(Unit) {
    viewModel.handleAction(HomeAction.OnAppear)
}
```

그리고 ViewModel에서 중복 로딩을 막는다.

```kotlin
if (state.hasLoaded || state.isLoading) return
load()
```

## 12. onAppear는 여러 번 불릴 수 있다

SwiftUI 초보자가 가장 많이 헷갈리는 부분이다.

`.onAppear`는 한 번만 호출된다는 보장이 없다.

다음 상황에서 여러 번 불릴 수 있다.

- 탭을 바꿨다가 다시 돌아옴
- Navigation으로 다른 화면에 갔다가 뒤로 옴
- 부모 View의 State가 바뀌면서 하위 View가 다시 구성됨
- 조건부 View가 사라졌다가 다시 나타남
- 리스트 셀처럼 재사용되는 View가 화면에 들어옴

그래서 API 호출을 `.onAppear`에 바로 넣으면 중복 호출이 생길 수 있다.

나쁜 예시는 다음과 같다.

```swift
.onAppear {
    Task {
        let quote = try await api.getQuote()
        self.quote = quote
    }
}
```

우리 프로젝트에서는 Reducer에서 막는다.

```swift
case .onAppear:
    guard !state.hasLoaded, !state.isLoading else { return .none }
    return load(state: &state)
```

`hasLoaded`는 이미 한 번 로드했는지 확인한다.

`isLoading`은 현재 로딩 중인지 확인한다.

둘 중 하나라도 참이면 새 요청을 보내지 않는다.

## 13. .task와 .onAppear의 차이

SwiftUI에는 `.task`도 있다.

```swift
.task {
    await load()
}
```

`.task`는 View가 나타날 때 async 작업을 시작하고, View가 사라지면 작업을 취소할 수 있다.

Android Compose의 `LaunchedEffect`와 조금 비슷하다.

하지만 TCA에서는 `.task` 안에서 직접 API를 호출하기보다, Action을 보내는 식으로 쓴다.

```swift
.task {
    await viewStore.send(.task).finish()
}
```

또는 단순한 화면은 `.onAppear`로 충분하다.

이 프로젝트에서는 현재 홈 화면처럼 명시적 진입 이벤트가 필요할 때 `.onAppear -> .onAppear Action -> Reducer` 흐름을 쓴다.

선택 기준은 다음과 같다.

| 상황 | 추천 |
|---|---|
| 화면이 나타날 때 한 번 로드 | `.onAppear` Action + `hasLoaded` |
| View가 사라지면 async 작업도 취소되어야 함 | `.task` + cancellable Effect |
| 검색어 입력처럼 값이 바뀔 때마다 작업 | Action + debounce/cancel |
| 앱 foreground/background 감지 | `scenePhase`를 Action으로 전달 |

## 14. Effect 취소와 생명주기 컨트롤

복잡한 화면에서는 "이전 요청 취소"가 중요하다.

예를 들어 검색 화면을 생각해보자.

```text
사용자가 "a" 입력
-> API 요청 시작
사용자가 바로 "ab" 입력
-> 이전 "a" 요청은 필요 없어짐
-> "ab" 요청만 남겨야 함
```

TCA에서는 Effect에 ID를 붙이고 취소할 수 있다.

```swift
enum CancelID {
    case search
}

case let .searchTextChanged(text):
    state.searchText = text

    return .run { send in
        try await clock.sleep(for: .milliseconds(300))
        let result = try await searchClient.search(text)
        await send(.searchResultLoaded(result))
    }
    .cancellable(id: CancelID.search, cancelInFlight: true)
```

`cancelInFlight: true`는 같은 ID의 기존 작업이 있으면 취소하고 새 작업을 시작한다는 뜻이다.

Android로 보면 아래와 비슷하다.

```kotlin
private var searchJob: Job? = null

fun onSearchTextChanged(text: String) {
    searchJob?.cancel()
    searchJob = viewModelScope.launch {
        delay(300)
        val result = searchRepository.search(text)
        updateState { copy(result = result) }
    }
}
```

화면이 사라질 때 작업을 취소하고 싶으면 `.onDisappear`에서 Action을 보낸다.

```swift
.onDisappear {
    viewStore.send(.onDisappear)
}
```

Reducer에서는 취소 Effect를 반환한다.

```swift
case .onDisappear:
    return .cancel(id: CancelID.search)
```

이게 TCA에서 생명주기를 제어하는 방식이다.

View 생명주기 이벤트를 Action으로 보내고, Reducer가 어떤 Effect를 시작/취소할지 결정한다.

## 15. 화면 이동 생명주기와 Store 수명

Android에서는 Navigation graph에 따라 ViewModel 수명이 달라진다.

- Activity scope ViewModel
- NavGraph scope ViewModel
- 화면별 ViewModel

iOS TCA에서도 비슷한 문제가 있다.

Store가 어디에 만들어지고 보관되는지에 따라 State 수명이 달라진다.

우리 프로젝트에서는 `AppFeature.State`가 여러 화면의 State를 들고 있다.

```swift
struct State: Equatable {
    var screen: AppScreen = .splash
    var splash = SplashFeature.State()
    var home = HomeFeature.State()
    var quoteList = QuoteListFeature.State()
    var calendar = CalendarFeature.State()
    var typing = TypingFeature.State()
    var selectedTab: AppTab = .home
}
```

이건 Android로 보면 상위 Navigation ViewModel이 각 화면 상태를 들고 있는 구조와 비슷하다.

화면 전환은 `screen` 값을 바꾸면서 처리한다.

```swift
case .homeTypingSelected:
    state.screen = .typing
    state.typing = TypingFeature.State(
        dailyQuoteSeq: state.home.quote.dailyQuoteSeq,
        korQuote: state.home.quote.korQuote ?? "",
        engQuote: state.home.quote.engQuote ?? "",
        korAuthor: state.home.quote.korAuthor ?? "",
        engAuthor: state.home.quote.engAuthor ?? "",
        likeYn: state.home.quote.likeYn
    )
    return .none
```

여기서 중요한 점은 `typing` 화면으로 이동할 때 `TypingFeature.State`를 새로 만든다는 것이다.

즉 이 순간 타이핑 화면의 초기값이 결정된다.

Android Navigation으로 치면 route argument를 넘기면서 새 destination으로 이동하는 것과 비슷하다.

## 16. Scope는 부모 Feature가 자식 Feature를 연결하는 방법이다

`AppFeature` 안에는 이런 코드가 있다.

```swift
Scope(state: \.home, action: \.home) {
    HomeFeature()
}
```

이 뜻은 다음과 같다.

```text
AppFeature.State.home은 HomeFeature.State로 처리한다.
AppFeature.Action.home은 HomeFeature.Action으로 처리한다.
```

Android로 비유하면 상위 Navigation Host가 하위 화면 ViewModel들을 연결하는 느낌이다.

```text
AppFeature
  - HomeFeature
  - QuoteListFeature
  - CalendarFeature
  - TypingFeature
```

자식 Feature에서 처리할 Action은 자식 Reducer로 내려간다.

부모가 처리해야 하는 화면 이동이나 탭 변경은 `AppFeature`가 처리한다.

## 17. 자식 화면에서 부모 화면으로 이벤트 올리기

실제 앱에서는 자식 화면이 부모에게 "뒤로 가기", "상세로 이동", "완료됨" 같은 이벤트를 알려야 한다.

TCA에서는 보통 `delegate` Action을 둔다.

예시는 이런 형태다.

```swift
enum Action: Equatable {
    case saveTapped
    case delegate(Delegate)

    enum Delegate: Equatable {
        case back
        case saved
    }
}
```

자식 Reducer에서 부모에게 알려야 할 때:

```swift
case .saveTapped:
    return .send(.delegate(.saved))
```

부모 Reducer에서 받는다.

```swift
case .memoInsert(.delegate(.back)):
    state.screen = .main
    state.selectedTab = .quoteList
    return .none
```

Android로 보면 `SharedFlow<Effect>`로 navigation event를 보내거나, callback을 부모 composable에 전달하는 것과 비슷하다.

## 18. 앱 생명주기: foreground/background

SwiftUI 앱 전체의 생명주기는 `scenePhase`로 감지한다.

```swift
@Environment(\.scenePhase) var scenePhase
```

값은 보통 세 가지다.

| 값 | 의미 | Android 느낌 |
|---|---|---|
| `.active` | 앱이 foreground에서 사용 중 | resumed |
| `.inactive` | 잠깐 비활성, 전환 중 | paused 전후 |
| `.background` | 백그라운드 | stopped/background |

TCA에서는 이 값도 View에서 직접 처리하지 않고 Action으로 보낸다.

```swift
.onChange(of: scenePhase) { _, newValue in
    viewStore.send(.scenePhaseChanged(newValue))
}
```

Reducer에서 필요한 처리를 한다.

```swift
case let .scenePhaseChanged(.active):
    return refreshIfNeeded(state: &state)

case .scenePhaseChanged(.background):
    return saveDraft(state: &state)
```

우리 앱에서 나중에 쓸 수 있는 예시는 다음과 같다.

- 앱이 다시 foreground로 올 때 오늘 날짜 명언 갱신
- 백그라운드로 갈 때 작성 중인 메모 저장
- 알림 권한 상태 다시 확인
- 토큰 만료 여부 확인

단, Android에 없는 동작을 새로 추가하면 안 되므로 실제 적용 전에는 Android 동작을 먼저 확인해야 한다.

## 19. MainActor와 UI 업데이트

Swift에는 `MainActor`라는 개념이 있다.

Android로 비유하면 UI thread, main thread와 비슷하다.

SwiftUI의 화면 상태는 기본적으로 main thread에서 바뀌어야 한다.

TCA는 Reducer에서 State를 바꾸는 작업을 main actor 쪽에서 안전하게 처리하도록 설계되어 있다.

그래서 우리는 보통 Reducer 안에서 그냥 이렇게 쓴다.

```swift
state.isLoading = false
state.quote = quote
```

비동기 Effect 안에서는 직접 State를 바꾸지 않고 `send`만 한다.

```swift
await send(.dailyQuoteLoaded(.success(response)))
```

이 구조 덕분에 "백그라운드 thread에서 UI state를 건드리는 문제"를 줄일 수 있다.

만약 `MainActor-isolated` 관련 에러가 나면 보통 의미는 다음 중 하나다.

- main actor에서만 호출 가능한 함수를 다른 actor/thread 문맥에서 호출했다.
- Swift가 이 함수가 UI/main thread 전용이라고 판단했다.
- 동기 함수에서 actor 격리된 함수를 직접 호출하려 했다.

해결 방향은 보통 다음이다.

- 해당 함수를 `nonisolated`로 만들 수 있는지 확인한다.
- 호출부를 `await MainActor.run { ... }`로 감싼다.
- 함수 자체를 `async`로 만들고 main actor 경계를 맞춘다.
- UI와 무관한 유틸 함수라면 main actor에 묶이지 않도록 위치를 분리한다.

## 20. TCA에서 테스트가 쉬운 이유

TCA는 모든 일이 Action과 State로 정리되기 때문에 테스트가 쉽다.

예를 들어 홈 화면에서 `nextTapped`를 누르면 날짜가 하루 증가해야 한다.

테스트는 이런 식으로 작성할 수 있다.

```swift
let store = TestStore(initialState: HomeFeature.State()) {
    HomeFeature()
}

await store.send(.nextTapped) {
    $0.date = expectedDate
    $0.hasLoaded = false
    $0.isLoading = true
}
```

API 결과까지 테스트하려면 fake dependency를 넣는다.

```swift
let store = TestStore(initialState: HomeFeature.State()) {
    HomeFeature()
} withDependencies: {
    $0.homeClient.getDailyQuoteNoToken = { _ in
        DailyQuote(korQuote: "테스트 명언")
    }
}
```

Android에서 fake repository를 넣고 ViewModel 테스트를 하는 것과 같다.

## 21. 이 프로젝트에서 Feature를 만들 때 순서

새 화면을 만들 때는 아래 순서로 접근한다.

1. Android 화면과 ViewModel을 먼저 읽는다.
2. 기획서 `docs/screens/`를 확인한다.
3. 화면에 필요한 값을 `State`로 정리한다.
4. 사용자 입력과 비동기 결과를 `Action`으로 정리한다.
5. Android UseCase에 해당하는 Domain UseCase를 만든다.
6. `Core/Dependencies`에서 TCA dependency와 `liveValue`를 만들고, 그 안에서 Domain UseCase를 조립한다.
7. Reducer에서 Action별 State 변경을 구현한다.
8. API/DB 작업은 Effect에서 use case dependency를 호출하고 결과를 Action으로 다시 보낸다.
9. SwiftUI View는 State 표시와 Action 전송만 하게 만든다.
10. 화면 이동은 가능하면 `AppFeature`에서 처리한다.
11. 빌드하고 Android 동작과 비교한다.

## 22. 홈 화면 흐름을 실제로 따라가 보기

홈 화면이 처음 나타나는 흐름은 다음과 같다.

```text
HomeView가 화면에 나타남
-> .onAppear Action 전송
-> HomeFeature Reducer가 받음
-> hasLoaded/isLoading 확인
-> load(state:) 실행
-> isLoading = true
-> sessionClient.isLoggedIn() 확인
-> 비회원이면 homeClient.getDailyQuoteNoToken 호출
-> localQuoteClient.findById로 로컬 좋아요 여부 확인
-> dailyQuoteLoaded(.success(...)) Action 전송
-> Reducer가 quote, hasLoaded, isLoading 변경
-> HomeView가 새 State로 다시 그림
```

Android로 바꾸면 다음 흐름이다.

```text
Composable 진입
-> LaunchedEffect(Unit)
-> viewModel.handleAction(OnAppear)
-> ViewModel에서 중복 로딩 체크
-> viewModelScope.launch
-> 로그인 여부 확인
-> API 호출
-> 로컬 DB 확인
-> state update
-> Compose recomposition
```

## 23. 실무에서 헷갈리지 않기 위한 기준

TCA를 쓸 때 판단 기준은 아래처럼 잡으면 된다.

| 질문 | 답 |
|---|---|
| 화면에 보여야 하는 값인가? | `State` |
| 사용자가 누르거나 입력하는 일인가? | `Action` |
| API/DB 결과인가? | `Action` |
| State를 바꾸는 곳인가? | `Reducer` |
| API/DB/권한/시간/랜덤 같은 외부 작업인가? | `Effect` |
| UseCase가 필요한가? | `@Dependency` |
| Repository/APIClient가 필요한가? | Domain UseCase 또는 Data Repository 안에서만 사용 |
| 화면 이동인가? | 보통 부모 Feature, 현재는 `AppFeature` |
| View가 사라질 때 작업 취소가 필요한가? | `.onDisappear` Action + `.cancel(id:)` |
| 입력이 바뀔 때 이전 요청을 취소해야 하나? | `.cancellable(id:cancelInFlight:)` |

## 24. 지금 코드에서 기억할 파일

| 역할 | 파일 |
|---|---|
| 앱 전체 화면 이동, 탭, 상위 상태 | `Fiilsa/App/AppFeature.swift` |
| 앱 전체 SwiftUI 화면 | `Fiilsa/App/AppView.swift` |
| 홈 화면 Reducer/ViewModel 역할 | `Fiilsa/Presentation/Home/HomeFeature.swift` |
| 홈 SwiftUI 화면 | `Fiilsa/Presentation/Home/HomeView.swift` |
| TCA dependency/liveValue 조립 | `Fiilsa/Core/Dependencies/*.swift` |
| Domain UseCase | `Fiilsa/Domain/UseCases/**/*.swift` |
| Repository protocol | `Fiilsa/Domain/Repositories/*.swift` |
| Repository 구현 | `Fiilsa/Data/Repositories/*.swift` |

## 25. 요약

TCA를 Android식으로 가장 짧게 정리하면 다음이다.

```text
Feature = ViewModel 역할
State = UiState
Action = Intent/Event + 비동기 결과
Reducer = ViewModel의 handleAction
Effect = viewModelScope.launch 작업
@Dependency = Hilt로 주입받던 UseCase를 TCA 방식으로 꺼내 쓰는 방법
Store = ViewModel 인스턴스처럼 State와 Reducer를 들고 있는 객체
Scope = 부모 Feature가 자식 Feature를 연결하는 방식
Delegate Action = 자식 화면이 부모에게 navigation/event를 올리는 방식
```

생명주기 컨트롤은 SwiftUI View에서 발생한 `.onAppear`, `.onDisappear`, `.task`, `scenePhase` 같은 이벤트를 Action으로 보내고, Reducer에서 로딩 시작, 중복 방지, 취소, 저장을 결정하는 방식으로 처리한다.

즉 View는 생명주기 이벤트를 알려주기만 하고, 실제 판단은 Reducer가 한다.

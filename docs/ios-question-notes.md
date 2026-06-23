# iOS Question Notes

Swift, iOS, SwiftUI, TCA를 배우면서 나온 질문을 누적 정리한다.

## 질문: TCA에서 Scope가 정확히 뭐야?

### 짧은 답

`Scope`는 부모 Feature/Store가 가지고 있는 큰 `State`와 `Action` 중에서 특정 자식 화면에 필요한 부분만 잘라서 자식 Feature/View에 연결하는 장치다.

Android식으로 말하면 상위 NavHost/ViewModel이 `HomeViewModel`, `CalendarViewModel` 같은 하위 화면 로직을 연결해주는 느낌이다.

### 왜 필요한가

앱 전체 부모인 `AppFeature`는 여러 화면의 상태를 한 번에 들고 있다.

```swift
struct State: Equatable {
    var splash = SplashFeature.State()
    var home = HomeFeature.State()
    var quoteList = QuoteListFeature.State()
    var calendar = CalendarFeature.State()
    var typing = TypingFeature.State()
}
```

Action도 여러 화면 Action을 감싸고 있다.

```swift
enum Action: Equatable {
    case splash(SplashFeature.Action)
    case home(HomeFeature.Action)
    case quoteList(QuoteListFeature.Action)
    case calendar(CalendarFeature.Action)
    case typing(TypingFeature.Action)
}
```

그런데 `HomeFeature`는 `AppFeature.State` 전체를 알 필요가 없다. 홈 화면은 `HomeFeature.State`와 `HomeFeature.Action`만 알면 된다.

그래서 부모의 일부를 자식에게 연결해주는 `Scope`가 필요하다.

### Reducer에서의 Scope

`AppFeature` 안의 `Scope`는 자식 Reducer를 부모 Reducer에 붙인다.

```swift
Scope(state: \.home, action: \.home) {
    HomeFeature()
}
```

의미는 다음과 같다.

```text
AppFeature.State.home
-> HomeFeature.State로 사용한다.

AppFeature.Action.home
-> HomeFeature.Action으로 사용한다.

home Action이 들어오면
-> HomeFeature Reducer가 처리하게 한다.
```

즉 부모 Reducer 안에 자식 Reducer를 연결하는 코드다.

### View에서의 store.scope

`AppView`에서는 이런 코드가 나온다.

```swift
HomeView(
    store: store.scope(state: \.home, action: \.home)
)
```

이건 부모 Store인 `StoreOf<AppFeature>`에서 홈 화면에 필요한 `StoreOf<HomeFeature>`를 만들어 넘긴다는 뜻이다.

```text
StoreOf<AppFeature>
-> state: AppFeature.State.home만 보여줌
-> action: HomeFeature.Action을 AppFeature.Action.home으로 감싸서 보냄
-> StoreOf<HomeFeature>처럼 사용할 수 있게 만듦
```

### Action 흐름

홈 화면에서 다음 버튼을 눌렀다고 가정한다.

```swift
viewStore.send(.nextTapped)
```

흐름은 다음과 같다.

```text
HomeView
-> HomeFeature.Action.nextTapped 전송
-> store.scope가 AppFeature.Action.home(.nextTapped)으로 감쌈
-> AppFeature로 Action 전달
-> Scope(state: \.home, action: \.home)가 이 Action을 HomeFeature로 내려보냄
-> HomeFeature Reducer가 nextTapped 처리
-> AppFeature.State.home이 변경됨
-> HomeView가 다시 그림
```

### Android 비유

Android로 억지로 비유하면 다음에 가깝다.

```kotlin
class AppViewModel {
    val homeState: HomeState
    val calendarState: CalendarState

    fun dispatch(action: AppAction) {
        when (action) {
            is AppAction.Home -> homeReducer.reduce(homeState, action.homeAction)
            is AppAction.Calendar -> calendarReducer.reduce(calendarState, action.calendarAction)
        }
    }
}
```

Compose 쪽에서는:

```kotlin
HomeScreen(
    state = appState.homeState,
    onAction = { homeAction ->
        appViewModel.dispatch(AppAction.Home(homeAction))
    }
)
```

TCA의 `scope`가 이 연결을 자동화해준다고 보면 된다.

### 이름이 Scope인 이유

영어 `scope`는 "범위"라는 뜻이다.

TCA에서 `scope`는 부모가 가진 큰 범위의 상태와 액션을 자식이 필요한 작은 범위로 좁힌다는 의미다.

```text
App 전체 범위
-> Home 화면 범위로 좁힘

AppFeature.State
-> HomeFeature.State

AppFeature.Action
-> HomeFeature.Action
```

### 핵심 정리

`Scope`는 부모와 자식을 연결한다.

Reducer의 `Scope`:

```text
자식 Reducer를 부모 Reducer에 연결한다.
```

View의 `store.scope`:

```text
부모 Store를 잘라서 자식 Store처럼 넘긴다.
```

둘이 같이 있어야 자식 화면이 정상 동작한다.

## 질문: TCA는 원래 커다란 AppFeature 아래에 화면별 Feature가 있는 구조야?

### 짧은 답

반드시 그런 것은 아니다.

TCA에서 중요한 원칙은 "앱 상태를 트리 구조로 조합할 수 있다"는 것이다. 그래서 앱 루트에 `AppFeature` 같은 부모 Feature를 두고, 그 아래에 `HomeFeature`, `CalendarFeature`, `QuoteListFeature` 같은 화면 Feature를 붙이는 구조를 많이 쓴다.

하지만 모든 화면 상태를 항상 거대한 `AppFeature` 안에 전부 넣어야 한다는 뜻은 아니다.

### TCA의 기본 사고방식

TCA는 앱을 작은 Feature들의 조합으로 본다.

```text
AppFeature
  - SplashFeature
  - HomeFeature
  - QuoteListFeature
  - CalendarFeature
  - TypingFeature
  - NoticeFeature
```

각 Feature는 자기 화면의 `State`, `Action`, `Reducer`를 가진다.

부모 Feature는 자식 Feature들을 조합하고, 화면 이동이나 탭 변경처럼 앱 전체에 가까운 결정을 한다.

### Android MVI + Compose와 다른 점

Android에서는 보통 화면마다 ViewModel이 따로 있다.

```text
NavHost
  - HomeScreen + HomeViewModel
  - CalendarScreen + CalendarViewModel
  - ListScreen + ListViewModel
```

각 화면 ViewModel은 Hilt가 만들어주고, Navigation Compose가 화면 생명주기에 맞춰 ViewModel scope를 관리한다.

TCA는 이보다 명시적이다.

```text
AppFeature.State 안에 home/calendar/list state를 둘 수 있음
AppFeature.Action 안에 home/calendar/list action을 감쌀 수 있음
AppFeature가 Scope로 자식 Feature를 연결함
AppView가 store.scope로 자식 View에 Store를 넘김
```

즉 Android에서는 프레임워크와 Hilt/NavHost가 뒤에서 해주던 연결을 TCA에서는 코드로 더 명확히 드러낸다.

### Android식 구조와 TCA식 구조 비교

Android:

```kotlin
NavHost(...) {
    composable("home") {
        val viewModel: HomeViewModel = hiltViewModel()
        HomeScreen(viewModel)
    }

    composable("calendar") {
        val viewModel: CalendarViewModel = hiltViewModel()
        CalendarScreen(viewModel)
    }
}
```

TCA:

```swift
struct AppFeature {
    struct State {
        var home = HomeFeature.State()
        var calendar = CalendarFeature.State()
    }

    enum Action {
        case home(HomeFeature.Action)
        case calendar(CalendarFeature.Action)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.home, action: \.home) {
            HomeFeature()
        }

        Scope(state: \.calendar, action: \.calendar) {
            CalendarFeature()
        }
    }
}
```

TCA 쪽은 "어떤 부모 State에 어떤 자식 State가 있고, 어떤 부모 Action이 어떤 자식 Action으로 연결되는지"가 코드에 그대로 보인다.

### AppFeature가 하는 일

`AppFeature`는 Android의 단일 ViewModel이라기보다 아래 역할을 합친 것에 가깝다.

```text
NavHost의 route 상태
탭 선택 상태
화면 간 데이터 전달
자식 Feature 연결
앱 전체 이벤트 처리
```

우리 프로젝트의 `AppFeature`는 이런 일을 한다.

```swift
var screen: AppScreen = .splash
var selectedTab: AppTab = .home
var home = HomeFeature.State()
var typing = TypingFeature.State()
```

예를 들어 홈에서 타이핑 화면으로 이동할 때:

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

이건 Android로 보면 NavHost에서 `typing/{quoteId}`로 이동하면서 argument를 넘기는 것과 비슷하다.

### AppFeature가 너무 커지는 문제

`AppFeature`에 모든 걸 넣으면 커질 수 있다.

하지만 TCA의 의도는 `AppFeature`가 모든 비즈니스 로직을 다 가지는 것이 아니다.

좋은 분리:

```text
AppFeature
  - 화면 이동
  - 탭 변경
  - 자식 연결

HomeFeature
  - 홈 명언 로딩
  - 날짜 이동
  - 좋아요

CalendarFeature
  - 월 이동
  - 날짜 선택
  - 달력 데이터 로딩

QuoteListFeature
  - 필터
  - 리스트 로딩
  - 상세 선택
```

나쁜 분리:

```text
AppFeature
  - 홈 API 호출
  - 캘린더 API 호출
  - 리스트 필터 처리
  - 타이핑 저장
  - 모든 화면의 모든 로직
```

부모는 조율만 하고, 실제 화면 로직은 자식 Feature가 가져야 한다.

### 다른 TCA 구조도 가능한가

가능하다.

대표적인 구조는 다음이 있다.

1. 루트 `AppFeature` + 화면별 child Feature
   - 지금 우리 프로젝트 구조
   - 화면 이동과 앱 상태가 명확하다
   - Android 앱 포팅처럼 전체 흐름을 맞출 때 좋다

2. 탭별 Feature를 중간 부모로 둔다
   - 예: `MainTabFeature` 아래 `HomeFeature`, `CalendarFeature`, `QuoteListFeature`
   - 탭이 복잡해지면 좋다

3. Navigation stack 기반 구조
   - push/pop 화면이 많을 때 좋다
   - TCA의 stack navigation 기능을 쓸 수 있다

4. 화면마다 독립 Store를 생성
   - 단순 예제에서는 가능하다
   - 화면 간 상태 공유와 navigation 제어가 흩어질 수 있다

### 왜 우리 프로젝트는 AppFeature에 모았나

우리 프로젝트는 Android 앱을 iOS로 포팅하고 있고, 화면 이동이 현재는 비교적 단순하다.

그래서 아래 이유로 `AppFeature` 중심 구조를 쓰고 있다.

- Splash 이후 Login/Home 분기
- 하단 탭 상태 관리
- 홈에서 타이핑 화면으로 데이터 전달
- 리스트에서 상세/메모 화면 이동
- 마이페이지에서 공지/알림 화면 이동
- Android navigation 흐름을 한 곳에서 비교하기 쉬움

즉 "TCA는 무조건 이렇게 해야 한다"가 아니라, 현재 프로젝트에 맞는 단순하고 명시적인 구조를 선택한 것이다.

### 핵심 차이

Android MVI + Compose는 보통 이런 느낌이다.

```text
화면마다 ViewModel이 독립적으로 있고
NavHost/Hilt가 ViewModel 생명주기를 관리한다.
```

TCA는 이런 느낌이다.

```text
앱 상태를 큰 트리로 보고
부모 Feature가 자식 Feature를 명시적으로 조합한다.
Store를 scope해서 자식 View에 넘긴다.
```

그래서 처음에는 Android보다 연결 코드가 더 많아 보인다.

대신 장점은 다음이다.

- 상태 흐름이 명시적이다.
- 화면 이동도 State로 테스트할 수 있다.
- 자식 화면과 부모 화면의 이벤트 연결이 코드에 보인다.
- dependency 교체와 reducer 테스트가 쉽다.

### 지금 이해해야 할 정도

지금은 이렇게 이해하면 충분하다.

```text
TCA는 앱을 Feature 트리로 만든다.
AppFeature는 루트 Feature다.
화면별 Feature는 자식 Feature다.
Scope는 부모와 자식을 연결한다.
AppFeature가 모든 로직을 가져야 하는 것은 아니다.
화면 내부 로직은 각 화면 Feature가 가진다.
```

## 질문: 자식 Action은 자식 Feature가 처리하는데 왜 AppFeature.Action에서 다시 감싸?

### 짧은 답

부모 Store가 받을 수 있는 Action 타입은 하나뿐이기 때문이다.

`AppView`의 루트 Store는 `StoreOf<AppFeature>`다.

```swift
let store: StoreOf<AppFeature>
```

이 Store는 `AppFeature.Action`만 받을 수 있다.

그런데 홈 화면은 `HomeFeature.Action`을 보내고, 캘린더 화면은 `CalendarFeature.Action`을 보낸다.

서로 타입이 다르다.

```swift
HomeFeature.Action.nextTapped
CalendarFeature.Action.monthNextTapped
```

그래서 부모 Action 안에 자식 Action을 담는 case가 필요하다.

```swift
enum AppFeature.Action {
    case home(HomeFeature.Action)
    case calendar(CalendarFeature.Action)
}
```

이렇게 하면 모든 Action이 최종적으로는 `AppFeature.Action` 하나의 타입으로 통일된다.

### 왜 타입을 통일해야 하나

TCA Store는 이런 구조다.

```text
Store<State, Action>
```

즉 Store 하나는 State 타입 하나, Action 타입 하나를 가진다.

루트 Store가 `StoreOf<AppFeature>`라면:

```text
State = AppFeature.State
Action = AppFeature.Action
```

따라서 루트 Store에 직접 보낼 수 있는 Action은 `AppFeature.Action`뿐이다.

`HomeFeature.Action`을 루트 Store에 직접 보낼 수는 없다.

```swift
// 개념적으로 불가능한 형태
appStore.send(HomeFeature.Action.nextTapped)
```

대신 이렇게 감싸야 한다.

```swift
appStore.send(.home(.nextTapped))
```

### 그럼 자식이 처리한다면서 왜 부모로 들어가?

Action은 일단 부모 Store로 들어간다.

하지만 부모가 직접 처리하는 것은 아니다.

`Scope`가 이 Action을 보고 자식 Reducer로 내려보낸다.

```swift
Scope(state: \.home, action: \.home) {
    HomeFeature()
}
```

이 코드는 다음 의미다.

```text
AppFeature.Action.home(...)이 들어오면
그 안에 들어있는 HomeFeature.Action을 꺼내서
HomeFeature Reducer에게 처리시켜라.
```

흐름:

```text
HomeView에서 .nextTapped 보냄
-> store.scope가 .home(.nextTapped)으로 감쌈
-> AppFeature Store로 전달
-> Scope가 .home 안의 .nextTapped를 꺼냄
-> HomeFeature Reducer가 처리
-> AppFeature.State.home이 변경됨
```

부모는 택배 물류센터처럼 Action을 받지만, `home`이라고 붙은 택배는 `HomeFeature`로 보내는 구조다.

### Android 비유

Android에서는 화면마다 ViewModel이 따로 있으면 이런 감싸기가 눈에 잘 안 보인다.

```kotlin
homeViewModel.handleAction(HomeAction.NextTapped)
calendarViewModel.handleAction(CalendarAction.MonthNextTapped)
```

각 ViewModel이 독립적으로 Action을 받기 때문이다.

하지만 TCA의 루트 Store 하나로 앱을 조합하면, 이런 식으로 타입을 합쳐야 한다.

```kotlin
sealed interface AppAction {
    data class Home(val action: HomeAction) : AppAction
    data class Calendar(val action: CalendarAction) : AppAction
}
```

그리고 부모 dispatch는 이런 식이 된다.

```kotlin
fun dispatch(action: AppAction) {
    when (action) {
        is AppAction.Home -> homeReducer.reduce(homeState, action.action)
        is AppAction.Calendar -> calendarReducer.reduce(calendarState, action.action)
    }
}
```

TCA의 `Scope`가 이 `when` 분기와 자식 reducer 호출을 대신해준다고 보면 된다.

### 왜 그냥 HomeView에 HomeFeature Store를 따로 만들지 않나

그렇게 할 수도 있다.

하지만 화면마다 Store를 완전히 따로 만들면 문제가 생길 수 있다.

- 부모가 자식 상태를 알기 어렵다.
- 홈에서 타이핑 화면으로 데이터를 넘기기 어렵다.
- 탭 상태와 화면 이동을 한 곳에서 관리하기 어렵다.
- 테스트에서 앱 전체 흐름을 검증하기 어렵다.
- 화면 간 이벤트 연결이 흩어진다.

그래서 TCA에서는 루트 Store에서 자식 Store를 `scope`해서 넘기는 방식을 자주 쓴다.

```swift
HomeView(
    store: store.scope(state: \.home, action: \.home)
)
```

이러면 HomeView 입장에서는 `StoreOf<HomeFeature>`를 받은 것처럼 쓰지만, 실제로는 루트 Store와 연결되어 있다.

### 부모가 자식 Action을 감싸는 진짜 이유

이유는 세 가지다.

1. 타입 통일

```text
루트 Store는 AppFeature.Action만 받을 수 있다.
자식 Action을 AppFeature.Action으로 감싸야 한다.
```

2. 상태 위치 연결

```text
HomeFeature가 바꾸는 State는 실제로 AppFeature.State.home이다.
```

3. 부모가 필요한 이벤트만 가로챌 수 있음

예를 들어 자식이 delegate Action을 올리면 부모가 화면 이동을 처리할 수 있다.

```swift
case .typing(.delegate(.back)):
    state.screen = .main
    state.selectedTab = .home
    return .none
```

일반적인 홈 내부 Action은 `HomeFeature`가 처리하지만, 부모가 알아야 하는 Action은 부모가 처리할 수 있다.

### 핵심 정리

```text
자식 Action을 부모 Action으로 감싸는 이유
= 루트 Store의 Action 타입을 하나로 통일하기 위해서다.
```

```text
부모가 감싼다고 해서 부모가 모든 로직을 처리하는 것은 아니다.
Scope가 자식 Action을 자식 Reducer로 내려보낸다.
```

```text
부모는 화면 이동이나 자식 간 연결이 필요한 Action만 처리한다.
화면 내부 로직은 자식 Feature가 처리한다.
```

## 질문: `case memoChanged(String)`과 `case let .memoChanged(text)`는 바인딩이야? iOS에서 어떤 문법이야?

### 짧은 답

이 코드는 바인딩 그 자체라기보다, TCA에서 입력값 변경을 처리하는 수동 바인딩 패턴이다.

Swift 문법으로 보면 두 가지가 들어 있다.

```swift
enum Action: Equatable {
    case memoChanged(String)
}
```

이건 Swift의 `enum associated value` 문법이다.

```swift
case let .memoChanged(text):
    state.memo = text
    return .none
```

이건 Swift의 `switch pattern matching` 문법이다.

### `case memoChanged(String)`의 의미

Swift enum은 Kotlin enum보다 더 강력하다.

Kotlin의 sealed class/interface처럼 case마다 값을 담을 수 있다.

Swift:

```swift
enum Action: Equatable {
    case memoChanged(String)
}
```

Android/Kotlin으로 비유하면:

```kotlin
sealed interface Action {
    data class MemoChanged(val text: String) : Action
}
```

즉 `memoChanged(String)`은 "메모 텍스트가 바뀌었고, 바뀐 문자열을 같이 들고 있는 Action"이다.

사용 예:

```swift
viewStore.send(.memoChanged("새 메모"))
```

이 Action 안에는 `"새 메모"`라는 값이 들어 있다.

### `case let .memoChanged(text)`의 의미

Reducer에서는 switch로 Action을 분기한다.

```swift
switch action {
case let .memoChanged(text):
    state.memo = text
    return .none
}
```

이 뜻은:

```text
action이 .memoChanged라면
그 안에 들어있는 String 값을 꺼내서
text라는 이름으로 사용하겠다.
```

Kotlin으로 보면:

```kotlin
when (action) {
    is Action.MemoChanged -> {
        val text = action.text
        state = state.copy(memo = text)
    }
}
```

Swift의 `let`은 값을 꺼내서 상수 이름을 붙이는 문법이다.

그래서 아래 두 코드는 거의 같은 의미다.

```swift
case let .memoChanged(text):
```

```swift
case .memoChanged(let text):
```

둘 다 `.memoChanged` 안의 String을 `text`라는 상수로 꺼낸다.

### 그럼 이게 바인딩인가

엄밀히 말하면 이 코드 자체는 바인딩이 아니다.

이건 "텍스트 변경 Action"이다.

하지만 TextField와 연결하면 수동 바인딩처럼 사용된다.

예:

```swift
TextField(
    "",
    text: viewStore.binding(
        get: \.memo,
        send: Action.memoChanged
    )
)
```

이 흐름은 다음과 같다.

```text
사용자가 TextField 입력
-> SwiftUI Binding이 새 문자열을 받음
-> Action.memoChanged("입력값") 전송
-> Reducer에서 case let .memoChanged(text) 처리
-> state.memo = text
-> View가 새 state.memo로 다시 그림
```

즉 `memoChanged(String)`은 바인딩을 만들기 위해 사용하는 Action이다.

### SwiftUI Binding이란

SwiftUI의 `Binding`은 "값을 읽고 쓰는 연결 통로"다.

아주 단순하게 말하면:

```text
get: 현재 값을 읽는 방법
set: 새 값을 저장하는 방법
```

TextField는 문자열을 직접 저장하지 않는다. 대신 `Binding<String>`을 받는다.

SwiftUI 기본 방식:

```swift
@State private var memo = ""

TextField("", text: $memo)
```

여기서 `$memo`가 `Binding<String>`이다.

TCA 방식:

```swift
TextField(
    "",
    text: viewStore.binding(
        get: \.memo,
        send: Action.memoChanged
    )
)
```

TCA에서는 State를 View가 직접 바꾸면 안 되기 때문에, set 시점에 Action을 보내도록 만든다.

### 왜 직접 `state.memo = text`를 View에서 안 하나

TCA 규칙 때문이다.

```text
View는 State를 직접 바꾸지 않는다.
View는 Action만 보낸다.
State 변경은 Reducer에서만 한다.
```

그래서 TextField 입력도 결국 Action으로 보낸다.

### 더 자동화된 TCA Binding도 있다

입력 필드가 많으면 매번 `memoChanged`, `titleChanged`, `contentChanged`를 만들기 귀찮다.

TCA에는 더 자동화된 binding 방식도 있다.

개념 예:

```swift
@BindingState var memo = ""

enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
}

var body: some Reducer<State, Action> {
    BindingReducer()
}
```

이 방식은 TCA가 binding Action 처리를 자동으로 해준다.

하지만 처음 배울 때는 명시적인 방식이 더 이해하기 쉽다.

```swift
case memoChanged(String)
```

우리 프로젝트에서는 초반에 이 수동 방식을 쓰는 게 흐름을 이해하기 좋다.

### 핵심 정리

```text
case memoChanged(String)
= Swift enum associated value
= Kotlin sealed class data class MemoChanged(val text: String) 느낌
```

```text
case let .memoChanged(text)
= Swift switch pattern matching
= Action 안의 String 값을 text로 꺼내는 문법
```

```text
이 코드 자체는 Binding이 아니다.
하지만 TextField의 Binding과 연결해서 수동 바인딩 패턴으로 쓴다.
```

## 질문: TCA에서 에러 처리는 어떻게 해? API 결과 Action에 Result를 넣는 방식이 맞아?

### 짧은 답

맞다. API 호출처럼 성공/실패가 모두 가능한 작업은 Effect에서 실행하고, 그 결과를 `Result<성공값, 실패값>`로 감싼 Action으로 다시 보내는 패턴을 많이 쓴다.

예:

```swift
enum Action: Equatable {
    case onAppear
    case dailyQuoteLoaded(Result<DailyQuote, ErrorResponse>)
}
```

흐름:

```text
onAppear
-> Effect에서 API 호출
-> 성공하면 dailyQuoteLoaded(.success(quote))
-> 실패하면 dailyQuoteLoaded(.failure(error))
-> Reducer에서 성공/실패별로 State 변경
```

### 왜 Result를 Action에 넣나

TCA의 원칙은 다음이다.

```text
State 변경은 Reducer에서만 한다.
Effect는 외부 작업을 하고 결과 Action만 보낸다.
```

API 호출은 Effect 안에서 한다.

하지만 API 성공/실패에 따라 `state.quote`, `state.isLoading`, `state.errorMessage`를 바꾸는 일은 Reducer에서 해야 한다.

그래서 Effect가 결과를 Action으로 다시 보내야 한다.

```swift
await send(.dailyQuoteLoaded(.success(response)))
```

또는:

```swift
await send(.dailyQuoteLoaded(.failure(error)))
```

### 기본 패턴

Action:

```swift
enum Action: Equatable {
    case loadButtonTapped
    case quoteResponse(Result<DailyQuote, ErrorResponse>)
}
```

Reducer:

```swift
case .loadButtonTapped:
    state.isLoading = true
    state.errorMessage = nil

    return .run { send in
        do {
            let quote = try await homeClient.getDailyQuoteNoToken("2026-06-21")
            await send(.quoteResponse(.success(quote)))
        } catch let error as ErrorResponse {
            await send(.quoteResponse(.failure(error)))
        } catch {
            await send(.quoteResponse(.failure(.defaultError)))
        }
    }

case let .quoteResponse(.success(quote)):
    state.quote = quote
    state.isLoading = false
    state.errorMessage = nil
    return .none

case let .quoteResponse(.failure(error)):
    state.isLoading = false
    state.errorMessage = error.message
    return .none
```

Android ViewModel로 보면:

```kotlin
fun load() {
    updateState { copy(isLoading = true, errorMessage = null) }

    viewModelScope.launch {
        runCatching {
            repository.getDailyQuote()
        }.onSuccess { quote ->
            updateState {
                copy(
                    quote = quote,
                    isLoading = false,
                    errorMessage = null
                )
            }
        }.onFailure { error ->
            updateState {
                copy(
                    isLoading = false,
                    errorMessage = error.message
                )
            }
        }
    }
}
```

TCA는 이 성공/실패 결과를 Action으로 한 번 더 통과시킨다고 보면 된다.

### 우리 프로젝트의 홈 예시

`HomeFeature`에는 이런 Action이 있다.

```swift
case dailyQuoteLoaded(Result<DailyQuote, ErrorResponse>)
```

API 호출:

```swift
return .run { send in
    do {
        let response = try await homeClient.getDailyQuoteNoToken(quoteDate)
        await send(.dailyQuoteLoaded(.success(response)))
    } catch let error as ErrorResponse {
        await send(.dailyQuoteLoaded(.failure(error)))
    } catch {
        await send(.dailyQuoteLoaded(.failure(.defaultError)))
    }
}
```

성공 처리:

```swift
case let .dailyQuoteLoaded(.success(quote)):
    state.quote = quote
    state.hasLoaded = true
    state.isLoading = false
    return .none
```

실패 처리:

```swift
case .dailyQuoteLoaded(.failure):
    state.hasLoaded = true
    state.isLoading = false
    return .none
```

현재 홈에서는 실패 메시지를 화면에 표시하지 않고 로딩만 종료한다. Android 앱이 실패 UI를 따로 보여주지 않는다면 이 정도가 맞고, Android에 토스트/다이얼로그가 있다면 그 동작에 맞춰 State나 delegate Action을 추가해야 한다.

### 실패 처리를 할 때 꼭 챙길 것

API 실패 처리에서 자주 빠지는 것:

```swift
state.isLoading = false
```

성공 케이스에서는 로딩을 끄고, 실패 케이스에서 빼먹으면 화면이 계속 로딩 상태로 남는다.

기본적으로 성공/실패 양쪽에서 다음을 확인한다.

- `isLoading = false`
- error message 저장 또는 제거
- empty state 처리
- 기존 데이터 유지 여부
- 재시도 가능 여부
- optimistic update rollback 여부

### Result를 쓰면 좋은 경우

`Result`가 좋은 경우:

```text
하나의 요청에 성공/실패 결과가 명확히 대응될 때
```

예:

```swift
case dailyQuoteLoaded(Result<DailyQuote, ErrorResponse>)
case memoSaved(Result<Int, ErrorResponse>)
case noticeListLoaded(Result<[NoticeResponse], ErrorResponse>)
case likeUpdated(Result<Int, ErrorResponse>)
```

장점:

- 성공과 실패가 한 Action에 묶인다.
- 요청 결과라는 의미가 명확하다.
- switch에서 success/failure 처리가 한 곳에 모인다.

### Result 대신 별도 Action을 써도 되는 경우

항상 `Result`만 써야 하는 것은 아니다.

이렇게 나눌 수도 있다.

```swift
enum Action: Equatable {
    case quoteLoaded(DailyQuote)
    case quoteLoadFailed(ErrorResponse)
}
```

이 방식이 좋은 경우:

- 성공과 실패에서 후속 흐름이 매우 다르다.
- 실패 종류마다 Action 이름을 명확히 하고 싶다.
- `Equatable` 처리나 타입 표현이 더 단순해진다.
- 에러가 화면 이동, 로그인 만료, 권한 요청처럼 전혀 다른 이벤트가 된다.

예:

```swift
case tokenExpired
case networkUnavailable
case loginRequired
```

### 어떤 방식을 고르면 되나

우리 프로젝트에서는 기본적으로 API/DB 요청 결과는 `Result` Action을 우선 사용한다.

```swift
case dailyQuoteLoaded(Result<DailyQuote, ErrorResponse>)
```

다만 실패가 단순 실패가 아니라 앱 흐름을 바꿔야 하면 별도 Action이 더 좋다.

예:

```swift
case dailyQuoteLoaded(Result<DailyQuote, ErrorResponse>)
case delegate(Delegate)

enum Delegate: Equatable {
    case loginRequired
}
```

또는:

```swift
case loginRequired
case tokenRefreshFailed
```

### Error 타입은 무엇을 쓰나

Swift의 기본 `Error`는 `Equatable`이 아니다.

TCA Action은 보통 `Equatable`을 붙이기 때문에, Action 안에 일반 `Error`를 그대로 넣기 어렵다.

그래서 우리 프로젝트는 API 에러를 `ErrorResponse`처럼 비교 가능한 모델로 정리해서 쓴다.

```swift
case dailyQuoteLoaded(Result<DailyQuote, ErrorResponse>)
```

`ErrorResponse`가 있으면 화면에 표시할 메시지나 에러 코드를 State에 반영하기 쉽다.

### 에러 표시 방식

실패를 화면에 보여줘야 한다면 State에 표시 상태를 둔다.

```swift
struct State: Equatable {
    var isLoading = false
    var errorMessage: String?
    var isErrorAlertPresented = false
}
```

실패 처리:

```swift
case let .quoteResponse(.failure(error)):
    state.isLoading = false
    state.errorMessage = error.message
    state.isErrorAlertPresented = true
    return .none
```

View는 State만 보고 alert를 띄운다.

```swift
.alert(
    "오류",
    isPresented: viewStore.binding(
        get: \.isErrorAlertPresented,
        send: { _ in .errorAlertDismissed }
    )
) {
    Button("확인") {}
} message: {
    Text(viewStore.errorMessage ?? "")
}
```

단, 이 프로젝트에서는 Android에 없는 에러 UI를 임의로 추가하면 안 된다. Android가 토스트를 쓰는지, 다이얼로그를 쓰는지, 조용히 무시하는지 먼저 확인해야 한다.

### 빈 화면과 에러 화면

API 실패와 빈 데이터는 다르다.

```text
실패
= 서버/네트워크/인증 문제로 데이터를 못 가져옴

빈 데이터
= 요청은 성공했지만 보여줄 데이터가 없음
```

State도 분리하는 것이 좋다.

```swift
var isLoading = false
var errorMessage: String?
var items: [Quote] = []

var isEmpty: Bool {
    !isLoading && errorMessage == nil && items.isEmpty
}
```

### 좋아요처럼 optimistic update가 있는 경우

좋아요는 UI를 먼저 바꾸고 API를 나중에 호출할 수 있다.

```swift
case let .likeTapped(isLike):
    let previousLikeYn = state.quote.likeYn
    state.quote.likeYn = isLike ? "Y" : "N"

    return .run { send in
        do {
            let response = try await homeClient.postLike(...)
            await send(.likeUpdated(.success(response)))
        } catch let error as ErrorResponse {
            await send(.likeUpdated(.failure(error)))
        }
    }
```

실패하면 이전 상태로 되돌릴지 결정해야 한다.

```swift
case .likeUpdated(.failure):
    // Android 동작에 따라 이전 likeYn으로 rollback할지 결정
    return .none
```

현재 프로젝트에서는 Android parity가 기준이므로 Android가 실패 시 되돌리는지 확인해야 한다.

### 핵심 정리

```text
API 호출은 Effect에서 한다.
API 결과는 Action으로 다시 보낸다.
성공/실패가 한 요청의 결과라면 Result를 Action에 담는 패턴이 좋다.
State 변경은 success/failure Action을 받은 Reducer에서 한다.
성공/실패 양쪽에서 isLoading 종료를 잊지 않는다.
화면에 보여줄 에러 UI는 Android 동작을 먼저 확인한다.
```

## 질문: TCA에서 Store와 View의 생명주기는 어떻게 달라?

### 짧은 답

SwiftUI의 `View`는 자주 다시 만들어질 수 있는 값이다.

TCA의 `Store`는 상태를 들고 있는 객체이고, Store가 살아있는 동안 그 안의 `State`가 유지된다.

그래서 이렇게 이해하면 된다.

```text
View
= 화면을 그리는 값
= 상태가 바뀌면 자주 다시 계산/생성될 수 있음

Store
= State와 Reducer를 들고 있는 상태 컨테이너
= Store가 살아있는 동안 State가 유지됨
```

Android로 비유하면:

```text
SwiftUI View
~= Compose 함수

TCA Store
~= ViewModel 인스턴스에 가까움
```

단, 완전히 같은 것은 아니다. Android ViewModel은 Android lifecycle owner가 관리하지만, TCA Store는 어디서 생성하고 보관하느냐에 따라 수명이 결정된다.

### 우리 프로젝트에서 루트 Store는 어디서 만들어지나

현재 `FiilsaApp.swift`에서 루트 Store를 만든다.

```swift
@main
struct FiilsaApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(
                store: Store(initialState: AppFeature.State()) {
                    AppFeature()
                }
            )
        }
    }
}
```

여기서 만들어지는 Store는 `StoreOf<AppFeature>`다.

이 Store 안에 앱 전체 상태가 들어 있다.

```swift
var screen: AppScreen = .splash
var splash = SplashFeature.State()
var home = HomeFeature.State()
var quoteList = QuoteListFeature.State()
var calendar = CalendarFeature.State()
var typing = TypingFeature.State()
var selectedTab: AppTab = .home
```

즉 이 루트 Store가 살아있는 동안 `home`, `calendar`, `quoteList` 같은 자식 State도 같이 유지된다.

### View는 왜 자주 다시 만들어지나

SwiftUI의 `View`는 class 객체가 아니라 struct 값이다.

```swift
struct AppView: View {
    let store: StoreOf<AppFeature>
}
```

SwiftUI는 상태가 바뀌면 `body`를 다시 계산한다.

```swift
var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
        content(for: viewStore.screen, viewStore: viewStore)
    }
}
```

이때 `AppView`, `HomeView` 같은 View 값은 다시 만들어질 수 있다.

하지만 View가 다시 만들어진다고 해서 Store의 State가 초기화되는 것은 아니다.

중요한 차이:

```text
View 재생성
-> 화면을 다시 그리기 위한 계산
-> State가 사라지는 뜻은 아님

Store 재생성
-> State가 새 initialState로 다시 시작될 수 있음
```

### Android Compose와 비교

Compose도 recomposition이 발생하면 Composable 함수가 다시 실행된다.

```kotlin
@Composable
fun HomeScreen(viewModel: HomeViewModel) {
    val state by viewModel.state.collectAsState()
    ...
}
```

Composable 함수가 다시 실행되어도 ViewModel은 유지된다.

SwiftUI + TCA도 비슷하다.

```swift
struct HomeView: View {
    let store: StoreOf<HomeFeature>
}
```

`HomeView` 값이 다시 만들어져도, 같은 Store를 받고 있다면 `HomeFeature.State`는 유지된다.

### Store 수명은 누가 결정하나

Store의 생명주기는 Store를 어디서 만들었는지가 결정한다.

루트에서 만들면 오래 산다.

```swift
AppView(
    store: Store(initialState: AppFeature.State()) {
        AppFeature()
    }
)
```

자식 View 안에서 매번 만들면 짧게 살 수 있다.

나쁜 예:

```swift
var body: some View {
    HomeView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
    )
}
```

이 코드를 상태 변화로 자주 다시 계산되는 곳에 두면, Store가 다시 만들어지고 State가 초기화될 위험이 있다.

그래서 보통 부모 Store에서 `scope`해서 자식 Store를 넘긴다.

```swift
HomeView(
    store: store.scope(state: \.home, action: \.home)
)
```

이러면 `HomeView`는 자식 Store처럼 받지만, 실제 State는 루트 Store의 `AppFeature.State.home`에 저장된다.

### store.scope로 만든 자식 Store의 수명

`store.scope(state: \.home, action: \.home)`는 완전히 독립된 새 저장소를 만드는 것이 아니다.

부모 Store를 홈 화면용으로 좁혀서 보여주는 것이다.

```text
부모 Store: AppFeature
  State: AppFeature.State
  Action: AppFeature.Action

scope 후 자식 Store처럼 보이는 것: HomeFeature
  State: AppFeature.State.home
  Action: AppFeature.Action.home(HomeFeature.Action)
```

따라서 홈 State의 실제 수명은 부모 Store와 `AppFeature.State.home`의 수명에 따른다.

### 화면이 사라지면 State도 사라지나

항상 그렇지 않다.

우리 프로젝트에서는 `AppFeature.State` 안에 `home`, `quoteList`, `calendar`가 일반 property로 들어 있다.

```swift
var home = HomeFeature.State()
var quoteList = QuoteListFeature.State()
var calendar = CalendarFeature.State()
```

이런 State는 화면이 잠시 안 보이더라도 부모 Store가 살아있으면 유지된다.

예:

```text
홈 탭
-> 캘린더 탭 이동
-> 홈 탭으로 돌아옴
-> home State는 유지될 수 있음
```

반대로 화면 이동 시 직접 State를 초기화하면 사라진다.

우리 코드에도 이런 예가 있다.

```swift
case .typing(.delegate(.back)):
    state.screen = .main
    state.selectedTab = .home
    state.home = HomeFeature.State()
    return .none
```

여기서는 타이핑 화면에서 돌아올 때 홈 State를 새로 만들고 있다.

즉 화면 생명주기와 State 생명주기는 자동으로 항상 같은 것이 아니다. Reducer에서 State를 유지할지 초기화할지 결정할 수 있다.

### optional State를 쓰면 수명이 더 명확해진다

항상 존재하지 않는 화면은 optional State로 둘 수 있다.

```swift
var detail: DetailFeature.State?
```

화면 열기:

```swift
state.detail = DetailFeature.State(id: id)
```

화면 닫기:

```swift
state.detail = nil
```

이 경우 `detail` State의 수명은 더 명확하다.

```text
detail != nil
-> 화면 State 존재

detail == nil
-> 화면 State 제거
```

Android Navigation에서 back stack entry가 사라지면 해당 ViewModel이 정리되는 느낌과 비슷하다.

### View 생명주기 이벤트

SwiftUI View는 다음 이벤트를 제공한다.

```swift
.onAppear {
    viewStore.send(.onAppear)
}

.onDisappear {
    viewStore.send(.onDisappear)
}

.task {
    await viewStore.send(.task).finish()
}
```

하지만 이 이벤트가 곧 Store 생성/소멸을 의미하지는 않는다.

```text
onAppear
= View가 화면에 나타남
= Store가 새로 만들어졌다는 뜻 아님

onDisappear
= View가 화면에서 사라짐
= Store가 사라졌다는 뜻 아님
```

예를 들어 탭 전환으로 `HomeView`가 사라져도, `AppFeature.State.home`은 부모 Store 안에 남아 있을 수 있다.

### Effect의 생명주기

Effect는 Store가 실행하는 비동기 작업이다.

화면이 사라진다고 Effect가 무조건 자동 취소되는 것은 아니다.

취소가 필요하면 명시적으로 cancellation을 걸어야 한다.

```swift
enum CancelID {
    case load
}

case .onAppear:
    return .run { send in
        ...
    }
    .cancellable(id: CancelID.load)

case .onDisappear:
    return .cancel(id: CancelID.load)
```

Android로 보면:

```kotlin
private var loadJob: Job? = null

fun onAppear() {
    loadJob = viewModelScope.launch { ... }
}

fun onDisappear() {
    loadJob?.cancel()
}
```

### @State와 Store를 헷갈리지 말기

SwiftUI에는 `@State`도 있다.

```swift
@State private var isPresented = false
```

`@State`는 View가 소유하는 로컬 상태다.

TCA의 `Store` State는 Feature가 소유하는 앱 상태다.

기준:

```text
앱 로직, API 결과, 화면의 핵심 상태
-> TCA State

작고 일시적인 UI 상태
-> 경우에 따라 @State 가능
```

하지만 우리 프로젝트는 MVI/TCA를 기준으로 하므로, 화면 동작에 의미가 있는 상태는 가능한 TCA State에 두는 것이 좋다.

### Store를 View 안에서 만들면 안 되나

Preview나 독립 화면 테스트에서는 괜찮다.

```swift
#Preview {
    HomeView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
    )
}
```

하지만 실제 앱 화면에서는 보통 부모가 만든 Store를 받아야 한다.

```swift
struct HomeView: View {
    let store: StoreOf<HomeFeature>
}
```

이유:

- State가 불필요하게 초기화되는 것을 막기 위해
- 부모 Feature와 navigation을 연결하기 위해
- 앱 전체 흐름 테스트가 가능하게 하기 위해
- 화면 간 데이터 전달을 명확히 하기 위해

### 우리 프로젝트 기준 정리

현재 구조:

```text
FiilsaApp
-> 루트 Store 생성: StoreOf<AppFeature>
-> AppView에 전달
-> AppView가 screen/selectedTab을 보고 화면 선택
-> 각 화면에는 store.scope로 자식 Store 전달
```

수명:

```text
AppFeature Store
-> 앱 Window가 살아있는 동안 유지

AppFeature.State.home
-> 부모 Store가 살아있고, reducer에서 직접 초기화하지 않는 동안 유지

HomeView
-> SwiftUI가 필요할 때 다시 만들 수 있음

HomeView onDisappear
-> HomeFeature.State가 사라졌다는 뜻은 아님
```

### 핵심 정리

```text
View는 자주 다시 만들어져도 된다.
Store가 유지되면 State는 유지된다.
State 수명은 Store를 어디서 만들고 언제 nil/초기화하는지가 결정한다.
onAppear/onDisappear는 View 표시 이벤트이지 Store 생성/소멸 이벤트가 아니다.
Effect 취소는 필요하면 명시적으로 처리해야 한다.
```

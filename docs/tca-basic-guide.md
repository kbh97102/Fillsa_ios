# TCA Basic Guide

이 문서는 Swift/iOS를 처음 보는 Android 개발자를 기준으로 TCA의 기초를 설명한다.

TCA는 The Composable Architecture의 약자다. SwiftUI 앱에서 MVI 구조를 강하게 지키기 위한 라이브러리라고 보면 된다.

## 1. TCA가 해결하려는 문제

SwiftUI만으로도 화면은 만들 수 있다. 하지만 앱이 커지면 다음 문제가 생긴다.

- 화면 상태가 여러 곳에서 바뀐다.
- API 호출 위치가 View 안으로 들어간다.
- 화면 이동, alert, sheet 상태가 흩어진다.
- 테스트하기 어렵다.
- 부모 화면과 자식 화면의 상태 전달이 복잡해진다.

Android에서도 같은 문제가 있다. 그래서 보통 ViewModel, UiState, MVI, UseCase, Repository, Hilt를 쓴다.

TCA는 iOS에서 이 문제를 아래 규칙으로 해결한다.

```text
State는 한 곳에 둔다.
Action은 모든 이벤트를 표현한다.
State 변경은 Reducer에서만 한다.
비동기 작업은 Effect로 실행한다.
외부 의존성은 @Dependency로 주입한다.
View는 State를 그리고 Action만 보낸다.
```

## 2. 가장 작은 TCA Feature

TCA 화면 하나는 보통 이런 모양이다.

```swift
import ComposableArchitecture

@Reducer
struct CounterFeature {
    @ObservableState
    struct State: Equatable {
        var count = 0
    }

    enum Action: Equatable {
        case plusButtonTapped
        case minusButtonTapped
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .plusButtonTapped:
                state.count += 1
                return .none

            case .minusButtonTapped:
                state.count -= 1
                return .none
            }
        }
    }
}
```

Android로 생각하면 아래와 비슷하다.

```kotlin
data class CounterState(
    val count: Int = 0
)

sealed interface CounterAction {
    data object PlusButtonTapped : CounterAction
    data object MinusButtonTapped : CounterAction
}

class CounterViewModel : ViewModel() {
    private val _state = MutableStateFlow(CounterState())
    val state = _state.asStateFlow()

    fun handleAction(action: CounterAction) {
        when (action) {
            PlusButtonTapped -> _state.update { it.copy(count = it.count + 1) }
            MinusButtonTapped -> _state.update { it.copy(count = it.count - 1) }
        }
    }
}
```

## 3. State

`State`는 화면이 그려지는 데 필요한 현재 값이다.

```swift
@ObservableState
struct State: Equatable {
    var quote = DailyQuote()
    var date = Date()
    var isLoggedIn = false
    var hasLoaded = false
    var isLoading = false
}
```

Android의 `UiState`와 같다.

```kotlin
data class HomeUiState(
    val quote: DailyQuote = DailyQuote(),
    val date: LocalDate = LocalDate.now(),
    val isLoggedIn: Boolean = false,
    val hasLoaded: Boolean = false,
    val isLoading: Boolean = false,
)
```

State에 넣어야 하는 값:

- 화면에 표시되는 값
- 로딩 여부
- 선택된 탭
- 선택된 날짜
- 입력 중인 텍스트
- alert/sheet 표시 여부
- 중복 호출 방지를 위한 값
- 자식 화면의 상태

State에 넣지 않는 것이 좋은 값:

- 계산해서 바로 만들 수 있는 단순 표시 문자열
- API client, repository 같은 의존성
- View 내부에서만 끝나는 일시적 animation 값
- 전역 저장소에 있어야 하는 앱 전체 설정

## 4. Action

`Action`은 화면에서 발생하는 사건이다.

```swift
enum Action: Equatable {
    case onAppear
    case beforeTapped
    case nextTapped
    case likeTapped(Bool)
    case dailyQuoteLoaded(Result<DailyQuote, ErrorResponse>)
}
```

Action은 사용자 입력뿐 아니라 API 결과도 포함한다.

| Action 종류 | 예시 |
|---|---|
| 생명주기 | `onAppear`, `onDisappear`, `task` |
| 버튼 | `nextTapped`, `saveTapped`, `backTapped` |
| 입력 | `memoChanged(String)`, `searchTextChanged(String)` |
| API 결과 | `dailyQuoteLoaded(Result<DailyQuote, ErrorResponse>)` |
| DB 결과 | `localQuoteLoaded(LocalQuoteInfo?)` |
| 화면 이동 요청 | `delegate(.back)`, `delegate(.detailSelected(id))` |

Action 이름은 가능한 한 사용자의 의도를 기준으로 짓는다.

좋은 이름:

```swift
case likeButtonTapped(Bool)
case memoTextChanged(String)
case saveButtonTapped
case dailyQuoteResponse(Result<DailyQuote, ErrorResponse>)
```

덜 좋은 이름:

```swift
case setLike(Bool)
case updateMemo(String)
case callApi
```

Action은 "무슨 일이 일어났는가"를 표현하는 것이 좋다.

## 5. Reducer

Reducer는 Action을 받아서 State를 바꾸는 곳이다.

```swift
Reduce { state, action in
    switch action {
    case .nextTapped:
        state.date = nextDate(from: state.date)
        state.hasLoaded = false
        return load(state: &state)

    case let .dailyQuoteLoaded(.success(quote)):
        state.quote = quote
        state.hasLoaded = true
        state.isLoading = false
        return .none
    }
}
```

Android ViewModel의 `handleAction` 또는 `reduce` 함수와 같다.

Reducer에서 해야 하는 일:

- State 변경
- Action 분기
- Effect 시작
- Effect 취소
- 자식 Feature 연결

Reducer에서 피해야 하는 일:

- View 직접 조작
- UIKit/SwiftUI View 인스턴스 저장
- API client를 직접 생성
- 랜덤값, 현재 시간, UUID를 직접 사용
- 복잡한 문자열 파싱을 View 로직과 섞기

현재 시간, UUID, API, DB 같은 외부 값은 dependency로 빼는 것이 TCA 스타일이다.

## 6. return .none

TCA Reducer는 항상 `Effect`를 반환한다.

```swift
case .plusButtonTapped:
    state.count += 1
    return .none
```

`return .none`은 "State만 바꾸고 추가 작업은 없다"는 뜻이다.

정식으로는 빈 Effect 또는 no effect라고 이해하면 된다.

Android로 보면 다음과 같다.

```kotlin
fun handleAction(action: Action) {
    when (action) {
        PlusButtonTapped -> {
            updateState { copy(count = count + 1) }
            return // 추가 coroutine 없음
        }
    }
}
```

반대로 API 호출이 필요하면 `.none`이 아니라 `.run` 같은 Effect를 반환한다.

## 7. Effect

Effect는 Reducer 밖에서 실행되는 작업이다.

대표적인 Effect:

- API 호출
- DB 읽기/쓰기
- UserDefaults/Keychain 접근
- 알림 권한 요청
- sleep/debounce
- 파일 읽기
- 외부 SDK 호출

예시:

```swift
return .run { send in
    do {
        let quote = try await homeClient.getDailyQuoteNoToken(quoteDate)
        await send(.dailyQuoteLoaded(.success(quote)))
    } catch let error as ErrorResponse {
        await send(.dailyQuoteLoaded(.failure(error)))
    } catch {
        await send(.dailyQuoteLoaded(.failure(.defaultError)))
    }
}
```

Android로 보면:

```kotlin
viewModelScope.launch {
    try {
        val quote = homeRepository.getDailyQuoteNoToken(quoteDate)
        handleAction(DailyQuoteLoaded(Result.success(quote)))
    } catch (e: Throwable) {
        handleAction(DailyQuoteLoaded(Result.failure(e)))
    }
}
```

중요한 규칙:

```text
Effect 안에서는 State를 직접 바꾸지 않는다.
Effect는 결과 Action을 send한다.
State 변경은 다시 Reducer에서 한다.
```

## 8. send

Effect 안에서 `send`는 Action을 다시 Reducer로 보내는 함수다.

```swift
await send(.dailyQuoteLoaded(.success(quote)))
```

흐름은 다음과 같다.

```text
Reducer
-> Effect 실행
-> API 호출
-> send(.dailyQuoteLoaded)
-> Reducer가 다시 Action 처리
-> State 변경
```

Android로 보면 `handleAction(...)`을 다시 호출하거나, MVI에서 result action을 dispatch하는 것과 비슷하다.

## 9. Store

`Store`는 State와 Reducer를 들고 있는 객체다.

```swift
Store(initialState: HomeFeature.State()) {
    HomeFeature()
}
```

Android의 ViewModel 인스턴스처럼 생각하면 된다.

Store가 하는 일:

- 현재 State 보관
- View가 보낸 Action 받기
- Reducer 실행
- Effect 실행
- Effect가 보낸 Action 다시 처리
- State 변경을 View에 알리기

SwiftUI View는 Store를 통해 State를 읽고 Action을 보낸다.

## 10. SwiftUI View와 Store

View는 화면만 그린다.

```swift
struct CounterView: View {
    let store: StoreOf<CounterFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                Text("\(viewStore.count)")

                Button("+") {
                    viewStore.send(.plusButtonTapped)
                }
            }
        }
    }
}
```

Android Compose와 비교하면:

```kotlin
@Composable
fun CounterScreen(viewModel: CounterViewModel) {
    val state by viewModel.state.collectAsState()

    Column {
        Text("${state.count}")

        Button(
            onClick = { viewModel.handleAction(PlusButtonTapped) }
        ) {
            Text("+")
        }
    }
}
```

View에서 하지 말아야 할 일:

- API 호출
- DB 저장
- 복잡한 비즈니스 판단
- 로그인 여부 판단 후 상태 변경
- 화면 이동 상태 직접 조작

View에서 해야 할 일:

- State 표시
- 버튼 클릭 시 Action 전송
- 입력값 변경 시 Action 전송
- SwiftUI layout 구성

## 11. @Dependency

`@Dependency`는 외부 의존성을 가져오는 방법이다.

```swift
@Dependency(\.homeClient) private var homeClient
@Dependency(\.sessionClient) private var sessionClient
```

Android Hilt 생성자 주입과 목적이 같다.

```kotlin
@HiltViewModel
class HomeViewModel @Inject constructor(
    private val homeUseCase: HomeUseCase,
    private val sessionUseCase: SessionUseCase,
) : ViewModel()
```

TCA에서는 의존성을 struct로 정의하고 `DependencyValues`에 등록한다.

```swift
struct HomeClient {
    var getDailyQuoteNoToken: @Sendable (String) async throws -> DailyQuote
}

extension HomeClient: DependencyKey {
    static let liveValue: HomeClient = {
        let repository = LiveRepositories.home
        let useCase = GetDailyQuoteNoTokenUseCase(homeRepository: repository)

        return HomeClient(
            getDailyQuoteNoToken: { quoteDate in
                try await useCase(quoteDate: quoteDate)
            }
        )
    }()
}

extension DependencyValues {
    var homeClient: HomeClient {
        get { self[HomeClient.self] }
        set { self[HomeClient.self] = newValue }
    }
}
```

Feature에서는 이렇게 쓴다.

```swift
@Dependency(\.homeClient) private var homeClient
```

이러면 Feature는 실제 Repository 구현을 몰라도 된다.

## 12. UseCase, Dependency Client, Repository의 차이

이 프로젝트에서는 Reducer가 최종적으로 UseCase를 호출하도록 설계한다. TCA의 dependency client는 그 UseCase를 `@Dependency`로 주입하기 위한 얇은 어댑터다.

```text
Feature
-> Dependency Client
-> Domain UseCase
-> Repository
-> API / DB
```

예:

```text
HomeFeature
-> HomeClient
-> GetDailyQuoteNoTokenUseCase
-> DefaultHomeRepository
-> APIClient
```

Android로 보면:

```text
HomeViewModel
-> UseCase
-> Repository
-> Retrofit / Room
```

Domain UseCase는 "무슨 일을 한다"는 비즈니스 흐름이다. 로그인 후 토큰 저장처럼 API와 로컬 저장을 함께 해야 하는 작업은 UseCase에 둔다. Repository는 실제 data layer 구현에 가깝고, TCA dependency client는 Feature가 테스트하기 좋은 형태로 UseCase를 노출한다.

## 13. Scope

부모 Feature가 자식 Feature를 연결할 때 `Scope`를 쓴다.

```swift
Scope(state: \.home, action: \.home) {
    HomeFeature()
}
```

뜻:

```text
AppFeature.State.home은 HomeFeature.State다.
AppFeature.Action.home은 HomeFeature.Action이다.
home 관련 Action은 HomeFeature가 처리하게 한다.
```

Android로 보면 상위 Navigation ViewModel이 화면별 ViewModel을 연결하는 느낌이다.

## 14. 부모 Feature와 자식 Feature

`AppFeature`는 앱 전체 부모 Feature다.

```swift
@ObservableState
struct State: Equatable {
    var screen: AppScreen = .splash
    var home = HomeFeature.State()
    var quoteList = QuoteListFeature.State()
    var calendar = CalendarFeature.State()
}
```

Action도 자식 Action을 감싼다.

```swift
enum Action: Equatable {
    case home(HomeFeature.Action)
    case quoteList(QuoteListFeature.Action)
    case calendar(CalendarFeature.Action)
}
```

부모는 화면 이동, 탭 변경, 자식 간 데이터 전달을 담당한다.

자식은 자기 화면 내부 로직만 담당한다.

## 15. Delegate Action

자식 Feature가 부모에게 알려야 하는 일이 있다.

- 뒤로 가기
- 저장 완료
- 상세 화면으로 이동
- 로그인 필요

이럴 때 delegate Action을 쓴다.

```swift
enum Action: Equatable {
    case saveButtonTapped
    case delegate(Delegate)

    enum Delegate: Equatable {
        case back
        case saved
    }
}
```

자식에서 부모에게 알림:

```swift
case .saveButtonTapped:
    return .send(.delegate(.saved))
```

부모에서 처리:

```swift
case .memoInsert(.delegate(.saved)):
    state.screen = .main
    state.selectedTab = .quoteList
    return .none
```

Android의 one-shot effect, navigation event, callback과 비슷하다.

## 16. Binding

텍스트 입력처럼 View와 State가 자주 연결되는 값은 binding으로 처리할 수 있다.

기본 방식:

```swift
enum Action: Equatable {
    case memoChanged(String)
}

case let .memoChanged(text):
    state.memo = text
    return .none
```

View:

```swift
TextField(
    "",
    text: viewStore.binding(
        get: \.memo,
        send: Action.memoChanged
    )
)
```

TCA에는 `@BindingState`와 `BindingReducer` 패턴도 있다. 입력 필드가 많아지면 이 방식을 검토한다.

이 프로젝트에서는 초반에는 명시적인 `memoChanged(String)` 같은 Action을 쓰는 편이 이해하기 쉽다.

## 17. Error 처리

TCA에서 에러도 Action으로 처리한다.

```swift
case dailyQuoteLoaded(Result<DailyQuote, ErrorResponse>)
```

성공:

```swift
case let .dailyQuoteLoaded(.success(quote)):
    state.quote = quote
    state.isLoading = false
    return .none
```

실패:

```swift
case let .dailyQuoteLoaded(.failure(error)):
    state.errorMessage = error.message
    state.isLoading = false
    return .none
```

Effect 안에서 실패를 잡고 failure Action으로 보낸다.

```swift
catch let error as ErrorResponse {
    await send(.dailyQuoteLoaded(.failure(error)))
}
```

## 18. 로딩 상태

API 호출 전:

```swift
state.isLoading = true
return .run { ... }
```

API 성공:

```swift
state.isLoading = false
```

API 실패:

```swift
state.isLoading = false
```

중복 호출 방지:

```swift
guard !state.isLoading else { return .none }
```

화면 최초 한 번만 호출:

```swift
guard !state.hasLoaded, !state.isLoading else { return .none }
```

## 19. Feature 작성 순서

새 화면을 만들 때 순서:

1. Android Compose UI를 읽는다.
2. Android ViewModel, Action, State를 읽는다.
3. 화면에서 필요한 값을 `State`로 적는다.
4. 사용자 입력과 API 결과를 `Action`으로 적는다.
5. 필요한 Domain UseCase를 만들고 Repository protocol을 연결한다.
6. `Core/Dependencies`에서 TCA dependency와 `liveValue`를 만든다.
7. Reducer에서 Action별 상태 변경을 작성한다.
8. API/DB는 Effect에서 use case dependency를 호출한다.
9. SwiftUI View는 State 표시와 Action 전송만 하게 만든다.
10. 필요하면 부모 `AppFeature`에 화면 이동을 연결한다.
11. 빌드하고 Android 동작과 비교한다.

## 20. 기초 체크리스트

Feature를 만들 때 아래를 확인한다.

- `State`가 화면 상태를 모두 담고 있는가?
- `Action`이 사용자 입력과 비동기 결과를 모두 표현하는가?
- View에서 API/DB를 직접 호출하지 않는가?
- State 변경이 Reducer 안에만 있는가?
- Effect 결과가 다시 Action으로 들어오는가?
- `isLoading`이 성공/실패 양쪽에서 false로 돌아오는가?
- onAppear 중복 호출을 막는가?
- Android에 없는 UI/기능을 추가하지 않았는가?

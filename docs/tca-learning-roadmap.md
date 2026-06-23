# TCA Learning Roadmap

이 문서는 이 프로젝트에서 TCA를 이해하고 구현할 때 볼 문서의 진입점이다.

현재 프로젝트는 `swift-composable-architecture` 1.26.0을 사용한다.

## 읽는 순서

0. `docs/async/README.md`
   - Swift `async/await`, `Task`, cancellation의 기본
   - Android coroutine과 Swift concurrency의 차이
   - `MainActor`, `actor`, `Sendable`, `@Sendable`의 의미
   - TCA `Effect.run`을 이해하기 위한 선행 개념

   기초 내용을 더 자세히 볼 때는 `docs/async/basics.md`, 심화 점검과 면접 대비는 `docs/async/interview.md`를 함께 본다.

1. `docs/tca-basic-guide.md`
   - TCA가 무엇인지
   - Android ViewModel/MVI와 어떻게 대응되는지
   - `State`, `Action`, `Reducer`, `Effect`, `Store`, `@Dependency`가 무엇인지
   - 화면을 만들 때 어떤 순서로 구현해야 하는지

2. `docs/tca-advanced-guide.md`
   - SwiftUI 생명주기와 TCA의 관계
   - Effect 취소
   - 부모/자식 Feature 조합
   - navigation, tab, sheet, alert 같은 화면 상태 관리
   - dependency 교체와 테스트
   - 복잡한 화면을 설계하는 방법

3. `docs/tca-guide.md`
   - 앞의 두 문서를 요약한 빠른 참고 문서
   - 실제 `HomeFeature`, `AppFeature`와 연결해서 다시 볼 때 사용

## Android 개발자 기준 핵심 대응표

| Android | TCA |
|---|---|
| `ViewModel` | `Feature` + `Reducer` + `Store` |
| `UiState` / `StateFlow` | `State` |
| `Intent` / `Action` / `Event` | `Action` |
| `viewModelScope.launch` | `Effect.run` |
| `suspend fun` | `async` function |
| `try/catch` around suspend call | `do/catch` + `try await` |
| `Job.cancel()` | `.cancellable(id:)`, `.cancel(id:)` |
| Hilt | `@Dependency`, `DependencyValues` |
| UseCase injection | `@Dependency` + `Core/Dependencies` liveValue |
| Repository | Domain protocol + Data implementation |
| Compose UI | SwiftUI `View` |
| `collectAsState()` | Store observation |
| Navigation route | parent Feature state |
| one-shot navigation event | delegate Action |
| fake repository test | dependency override |

## 이 프로젝트에서 우선 알아야 하는 파일

| 역할 | 파일 |
|---|---|
| 앱 전체 상태와 화면 이동 | `Fiilsa/App/AppFeature.swift` |
| 앱 전체 SwiftUI View | `Fiilsa/App/AppView.swift` |
| 홈 화면 Feature | `Fiilsa/Presentation/Home/HomeFeature.swift` |
| 홈 화면 View | `Fiilsa/Presentation/Home/HomeView.swift` |
| TCA dependency/liveValue 조립 | `Fiilsa/Core/Dependencies/*.swift` |
| Domain UseCase | `Fiilsa/Domain/UseCases/**/*.swift` |
| Repository protocol | `Fiilsa/Domain/Repositories/*.swift` |
| API 구현 | `Fiilsa/Data/API/APIClient.swift` |
| Repository 구현 | `Fiilsa/Data/Repositories/*Repository.swift` |

## 학습 목표

이 문서 세트를 읽은 뒤에는 다음을 할 수 있어야 한다.

- Android ViewModel 코드를 보고 iOS TCA Feature로 옮길 수 있다.
- Swift `async/await`, `Task`, cancellation, `@Sendable`의 기본 의미를 설명할 수 있다.
- 화면 상태를 `State`로 나눌 수 있다.
- 사용자 입력과 API 결과를 `Action`으로 설계할 수 있다.
- API/DB 작업을 `Effect`로 작성할 수 있다.
- `@Dependency`로 Domain UseCase를 주입하고 테스트에서 fake로 바꿀 수 있다.
- `onAppear`, `onDisappear`, `.task`, cancellation을 이용해 생명주기를 제어할 수 있다.
- 부모 Feature에서 자식 Feature를 `Scope`로 조합할 수 있다.
- 화면 이동과 delegate Action을 설계할 수 있다.
- 테스트에서 dependency를 fake로 갈아끼울 수 있다.

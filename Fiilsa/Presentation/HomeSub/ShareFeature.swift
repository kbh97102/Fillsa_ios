import ComposableArchitecture
import Foundation

@Reducer
struct ShareFeature {
    @ObservableState
    struct State: Equatable {
        var quote = ""
        var author = ""
        var selectedPage = 0
        var isDescriptionVisible = false
        var toastMessage: String?

        init(quote: String = "", author: String = "") {
            self.quote = quote
            self.author = author
        }
    }

    enum Action: Equatable {
        case onAppear
        case descriptionVisibilityLoaded(Bool)
        case pageChanged(Int)
        case descriptionTapped
        case copyTapped
        case saveCompleted(Bool)
        case shareCompleted
        case toastDismissed
        case backTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case back
        }
    }

    @Dependency(\.settingsClient) private var settingsClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let isVisible = (try? await settingsClient.getShareDescriptionVisible()) ?? true
                    await send(.descriptionVisibilityLoaded(isVisible))
                }

            case let .descriptionVisibilityLoaded(isVisible):
                state.isDescriptionVisible = isVisible
                return .none

            case let .pageChanged(page):
                state.selectedPage = page
                return .none

            case .descriptionTapped:
                state.isDescriptionVisible = false
                return .run { _ in
                    try? await settingsClient.setShareDescriptionVisible(false)
                }

            case .copyTapped:
                state.toastMessage = "복사되었습니다."
                return .none

            case let .saveCompleted(success):
                state.toastMessage = success ? "저장 성공" : "저장 실패"
                return .none

            case .shareCompleted:
                return .none

            case .toastDismissed:
                state.toastMessage = nil
                return .none

            case .backTapped:
                return .send(.delegate(.back))

            case .delegate:
                return .none
            }
        }
    }
}

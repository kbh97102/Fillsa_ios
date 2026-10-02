import ComposableArchitecture
import Foundation

@Reducer
struct GeneralPopupFeature {
    @ObservableState
    struct State: Equatable {
        var hasLoaded = false
        var isLoading = false
        var queue: [PopupResponse] = []
        var currentPopup: PopupResponse?
    }

    enum Action: Equatable {
        case loadIfNeeded
        case loaded([PopupResponse])
        case loadCancelled
        case dismissCurrent
        case dismissToday
        case nextPopup
    }

    @Dependency(\.commonClient) private var commonClient
    @Dependency(\.hiddenPopupClient) private var hiddenPopupClient
    @Dependency(\.loadingClient) private var loadingClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .loadIfNeeded:
                guard !state.hasLoaded, !state.isLoading else { return .none }
                state.isLoading = true

                return .run { send in
                    guard !Task.isCancelled else { return }
                    let token = await loadingClient.begin()
                    if !Task.isCancelled {
                        var wasCancelled = false
                        do {
                            try await hiddenPopupClient.clearAllIfNeeded()
                        } catch is CancellationError {
                            wasCancelled = true
                        } catch {}

                        var popups: [PopupResponse] = []

                        if !wasCancelled, !Task.isCancelled {
                            do {
                                let generalPopup = try await commonClient.getPopupGeneral()
                                let isHidden: Bool
                                do {
                                    isHidden = try await hiddenPopupClient.isHidden(generalPopup.popupSeq)
                                } catch is CancellationError {
                                    throw CancellationError()
                                } catch {
                                    isHidden = false
                                }
                                if !isHidden, !Task.isCancelled {
                                    popups.append(generalPopup)
                                }
                            } catch is CancellationError {
                                wasCancelled = true
                            } catch {}
                        }

                        if !wasCancelled, !Task.isCancelled {
                            do {
                                let versionPopup = try await commonClient.getPopupVersionUpdate(appVersion())
                                popups.append(versionPopup)
                            } catch is CancellationError {
                                wasCancelled = true
                            } catch {}
                        }

                        if !Task.isCancelled {
                            if wasCancelled {
                                await send(.loadCancelled)
                            } else {
                                await send(.loaded(popups.sortedByPopupPriority()))
                            }
                        }
                    }
                    await loadingClient.end(token)
                }

            case let .loaded(popups):
                state.hasLoaded = true
                state.isLoading = false
                state.queue = popups
                state.currentPopup = state.queue.isEmpty ? nil : state.queue.removeFirst()
                return .none

            case .loadCancelled:
                state.isLoading = false
                return .none

            case .dismissCurrent:
                return .send(.nextPopup)

            case .dismissToday:
                guard let popup = state.currentPopup else { return .send(.nextPopup) }
                return .run { send in
                    try? await hiddenPopupClient.add(popup.popupSeq)
                    await send(.nextPopup)
                }

            case .nextPopup:
                state.currentPopup = state.queue.isEmpty ? nil : state.queue.removeFirst()
                return .none
            }
        }
    }
}

private func appVersion() -> String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
}

private extension Array where Element == PopupResponse {
    func sortedByPopupPriority() -> [PopupResponse] {
        sorted { lhs, rhs in
            popupPriority(lhs.popupType) < popupPriority(rhs.popupType)
        }
    }

    func popupPriority(_ type: String) -> Int {
        switch type {
        case "VERSION_UPDATE":
            return 1
        case "NOTICE":
            return 2
        case "EVENT":
            return 3
        default:
            return Int.max
        }
    }
}

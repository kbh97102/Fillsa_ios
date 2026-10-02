import ComposableArchitecture
import Foundation
import Testing
@testable import Fiilsa

@Suite("LoadingEffect")
struct LoadingEffectTests {
    @Test @MainActor func scopeEndsAfterResultActionIsReduced() async {
        let registry = LoadingRegistry()
        let gate = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: Probe.State()) {
            Probe(gate: gate.stream)
        } withDependencies: {
            $0.loadingClient = loadingTestClient(registry)
        }
        let task = await store.send(.start)
        var counts = await registry.counts().makeAsyncIterator()
        while await counts.next() == 0 {}
        #expect(await loadingCount(registry) == 1)
        gate.continuation.finish()
        await store.receive(.result) { $0.didReduceResult = true }
        await task.finish()
        #expect(store.state.didReduceResult)
        #expect(await loadingCount(registry) == 0)
    }

    @Reducer struct Probe {
        @ObservableState struct State: Equatable { var didReduceResult = false }
        enum Action: Equatable { case start, result }
        let gate: AsyncStream<Void>
        var body: some Reducer<State, Action> {
            Reduce { state, action in
                switch action {
                case .start:
                    return .runWithLoading { send in
                        for await _ in gate {}
                        await send(.result)
                    }
                case .result:
                    state.didReduceResult = true
                    return .none
                }
            }
        }
    }
}

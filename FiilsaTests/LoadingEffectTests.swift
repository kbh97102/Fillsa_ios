import ComposableArchitecture
import Foundation
import Testing
@testable import Fiilsa

@Suite("LoadingEffect")
struct LoadingEffectTests {
    @Test func groupWaitsForAllThreeChildren() async {
        let registry = LoadingRegistry()
        let a = AsyncStream<Void>.makeStream()
        let b = AsyncStream<Void>.makeStream()
        let c = AsyncStream<Void>.makeStream()
        let client = loadingTestClient(registry)
        let group = Task {
            let token = await client.begin()
            async let first: Void = waitForFinish(a.stream)
            async let second: Void = waitForFinish(b.stream)
            async let third: Void = waitForFinish(c.stream)
            _ = await (first, second, third)
            await client.end(token)
        }
        var counts = await registry.counts().makeAsyncIterator()
        while await counts.next() == 0 {}
        a.continuation.finish()
        b.continuation.finish()
        #expect(await loadingCount(registry) == 1)
        c.continuation.finish()
        await group.value
        #expect(await loadingCount(registry) == 0)
    }

    private func waitForFinish(_ stream: AsyncStream<Void>) async {
        for await _ in stream {}
    }

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

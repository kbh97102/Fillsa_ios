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
        let completed = AsyncStream<String>.makeStream()
        let client = loadingTestClient(registry)
        let group = Task {
            let token = await client.begin()
            async let first: Void = {
                await waitForFinish(a.stream)
                completed.continuation.yield("A")
            }()
            async let second: Void = {
                await waitForFinish(b.stream)
                completed.continuation.yield("B")
            }()
            async let third: Void = {
                await waitForFinish(c.stream)
                completed.continuation.yield("C")
            }()
            _ = await (first, second, third)
            await client.end(token)
        }
        var counts = await registry.counts().makeAsyncIterator()
        while await counts.next() == 0 {}
        var done = completed.stream.makeAsyncIterator()
        a.continuation.finish()
        #expect(await done.next() == "A")
        b.continuation.finish()
        #expect(await done.next() == "B")
        #expect(await loadingCount(registry) == 1)
        c.continuation.finish()
        #expect(await done.next() == "C")
        await group.value
        #expect(await loadingCount(registry) == 0)
    }

    @Test func oneFailedChildDoesNotEndGroup() async {
        let registry = LoadingRegistry()
        let a = AsyncStream<Void>.makeStream()
        let c = AsyncStream<Void>.makeStream()
        let completed = AsyncStream<String>.makeStream()
        let client = loadingTestClient(registry)
        let group = Task {
            let token = await client.begin()
            async let first: Void = {
                await waitForFinish(a.stream)
                completed.continuation.yield("A")
            }()
            async let second: Void = {
                do { throw ErrorResponse.defaultError }
                catch { completed.continuation.yield("B failed") }
            }()
            async let third: Void = {
                await waitForFinish(c.stream)
                completed.continuation.yield("C")
            }()
            _ = await (first, second, third)
            await client.end(token)
        }
        var done = completed.stream.makeAsyncIterator()
        #expect(await done.next() == "B failed")
        a.continuation.finish()
        #expect(await done.next() == "A")
        #expect(await loadingCount(registry) == 1)
        c.continuation.finish()
        #expect(await done.next() == "C")
        await group.value
        #expect(await loadingCount(registry) == 0)
    }

    private func waitForFinish(_ stream: AsyncStream<Void>) async {
        for await _ in stream {}
    }

    @Test @MainActor func scopeEndsAfterResultActionIsReduced() async {
        let registry = LoadingRegistry()
        let gate = AsyncStream<Void>.makeStream()
        let marker = ReductionMarker()
        let store = TestStore(initialState: Probe.State()) {
            Probe(gate: gate.stream, marker: marker)
        } withDependencies: {
            $0.loadingClient = LoadingClient(
                begin: { await registry.begin() },
                end: { token in
                    let reduced = marker.wasReduced
                    if !reduced { Issue.record("Scope ended before result Action reduced") }
                    await registry.end(token)
                },
                counts: { await registry.counts() }
            )
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
        let marker: ReductionMarker
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
                    marker.markReduced()
                    return .none
                }
            }
        }
    }

    final class ReductionMarker: @unchecked Sendable {
        private let lock = NSLock()
        private var reduced = false

        func markReduced() { lock.withLock { reduced = true } }
        var wasReduced: Bool { lock.withLock { reduced } }
    }
}

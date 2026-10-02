import ComposableArchitecture
import Foundation
import Testing
@testable import Fiilsa

@Suite("LoadingClient")
struct LoadingClientTests {
    @Test func singleScopeStartsAndEnds() async {
        let registry = LoadingRegistry()
        #expect(await loadingCount(registry) == 0)
        let token = await registry.begin()
        #expect(await loadingCount(registry) == 1)
        await registry.end(token)
        #expect(await loadingCount(registry) == 0)
    }

    @Test func overlappingScopesRemainActiveUntilLastEnd() async {
        let registry = LoadingRegistry()
        let a = await registry.begin()
        let b = await registry.begin()
        #expect(await loadingCount(registry) == 2)
        await registry.end(a)
        #expect(await loadingCount(registry) == 1)
        await registry.end(b)
        #expect(await loadingCount(registry) == 0)
    }

    @Test func duplicateEndDoesNotEndAnotherScope() async {
        let registry = LoadingRegistry()
        let a = await registry.begin()
        let b = await registry.begin()
        await registry.end(a)
        await registry.end(a)
        #expect(await loadingCount(registry) == 1)
        await registry.end(b)
        #expect(await loadingCount(registry) == 0)
    }

    @Test func lateSubscriberReceivesCurrentCount() async {
        let registry = LoadingRegistry()
        let token = await registry.begin()
        var counts = await registry.counts().makeAsyncIterator()
        #expect(await counts.next() == 1)
        await registry.end(token)
        #expect(await counts.next() == 0)
    }

    @Test func cancelledBeforeStartDoesNotBegin() async {
        let registry = LoadingRegistry()
        let client = loadingTestClient(registry)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            await client.withLoading {
                Issue.record("Cancelled work must not run")
            }
        }
        await task.value
        #expect(await loadingCount(registry) == 0)
    }

    @Test func cancelledOperationBalancesItsToken() async {
        let registry = LoadingRegistry()
        let client = loadingTestClient(registry)
        let started = AsyncStream<Void>.makeStream()
        let gate = AsyncStream<Void>.makeStream()
        let task = Task {
            await client.withLoading {
                started.continuation.yield(())
                for await _ in gate.stream {}
            }
        }
        var events = started.stream.makeAsyncIterator()
        _ = await events.next()
        #expect(await loadingCount(registry) == 1)
        task.cancel()
        await task.value
        #expect(await loadingCount(registry) == 0)
        started.continuation.finish()
        gate.continuation.finish()
    }

    @Test func cancellationWhileBeginIsSuspendedEndsTheLateToken() async {
        let registry = LoadingRegistry()
        let beginGate = AsyncStream<Void>.makeStream()
        let beginStarted = AsyncStream<Void>.makeStream()
        let client = LoadingClient(
            begin: {
                beginStarted.continuation.yield(())
                for await _ in beginGate.stream {}
                return await registry.begin()
            },
            end: { await registry.end($0) },
            counts: { await registry.counts() }
        )
        let task = Task {
            await client.withLoading {
                Issue.record("Cancelled operation must not start after delayed begin")
            }
        }
        var events = beginStarted.stream.makeAsyncIterator()
        _ = await events.next()
        task.cancel()
        beginGate.continuation.finish()
        await task.value
        #expect(await loadingCount(registry) == 0)
    }
}

func loadingTestClient(_ registry: LoadingRegistry) -> LoadingClient {
    LoadingClient(
        begin: { await registry.begin() },
        end: { await registry.end($0) },
        counts: { await registry.counts() }
    )
}

func loadingCount(_ registry: LoadingRegistry) async -> Int {
    var counts = await registry.counts().makeAsyncIterator()
    return await counts.next() ?? -1
}

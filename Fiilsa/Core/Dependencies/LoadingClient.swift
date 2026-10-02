import ComposableArchitecture
import Foundation

struct LoadingClient: Sendable {
    var begin: @Sendable () async -> UUID
    var end: @Sendable (UUID) async -> Void
    var counts: @Sendable () async -> AsyncStream<Int>

    func withLoading(_ operation: @Sendable () async -> Void) async {
        guard !Task.isCancelled else { return }
        let token = await begin()
        if !Task.isCancelled {
            await operation()
        }
        await end(token)
    }
}

actor LoadingRegistry {
    private var tokens: Set<UUID> = []
    private var subscribers: [UUID: AsyncStream<Int>.Continuation] = [:]

    func begin() -> UUID {
        let token = UUID()
        tokens.insert(token)
        publish()
        return token
    }

    func end(_ token: UUID) {
        guard tokens.remove(token) != nil else { return }
        publish()
    }

    func counts() -> AsyncStream<Int> {
        let id = UUID()
        let (stream, continuation) = AsyncStream<Int>.makeStream(bufferingPolicy: .bufferingNewest(1))
        subscribers[id] = continuation
        continuation.yield(tokens.count)
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id) }
        }
        return stream
    }

    private func publish() {
        for continuation in subscribers.values {
            continuation.yield(tokens.count)
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }
}

extension LoadingClient: DependencyKey {
    static let liveValue: LoadingClient = {
        let registry = LoadingRegistry()
        return LoadingClient(
            begin: { await registry.begin() },
            end: { await registry.end($0) },
            counts: { await registry.counts() }
        )
    }()

    static let testValue = LoadingClient(
        begin: { UUID() },
        end: { _ in },
        counts: {
            AsyncStream {
                $0.yield(0)
                $0.finish()
            }
        }
    )
}

extension DependencyValues {
    var loadingClient: LoadingClient {
        get { self[LoadingClient.self] }
        set { self[LoadingClient.self] = newValue }
    }
}

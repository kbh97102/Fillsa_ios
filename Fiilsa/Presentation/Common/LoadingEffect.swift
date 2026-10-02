import ComposableArchitecture

extension Effect {
    static func runWithLoading(
        operation: @escaping @Sendable (Send<Action>) async -> Void,
        fileID: StaticString = #fileID,
        filePath: StaticString = #filePath,
        line: UInt = #line,
        column: UInt = #column
    ) -> Self {
        @Dependency(\.loadingClient) var loadingClient
        return .run(operation: { send in
            await loadingClient.withLoading { await operation(send) }
        }, fileID: fileID, filePath: filePath, line: line, column: column)
    }
}

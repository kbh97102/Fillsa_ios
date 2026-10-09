import Alamofire
import Foundation
import Testing
@testable import Fiilsa

@Suite(.serialized)
struct TokenRefreshTests {
    @Test @MainActor func expiredAccessTokenRefreshesWithTheLoginDeviceID() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RefreshURLProtocol.self]
        let tokens = TestTokenStore()
        let expirations = AsyncStream<Void>.makeStream()
        let observer = NotificationCenter.default.addObserver(
            forName: .fillsaSessionExpired,
            object: nil,
            queue: nil
        ) { _ in
            expirations.continuation.yield(())
        }
        defer { NotificationCenter.default.removeObserver(observer) }
        let client = APIClientFactory.authenticated(
            environment: APIEnvironment(baseURL: URL(string: "https://refresh-test.invalid")!),
            tokenStore: tokens,
            sessionConfiguration: configuration
        )

        let response = try await client.send(
            APIRequest<EmptyRequestBody>(method: .get, path: "/member"),
            responseType: Int.self
        )

        expirations.continuation.finish()
        var expirationEvents = expirations.stream.makeAsyncIterator()
        #expect(response == 42)
        #expect(await tokens.accessToken() == "renewed-access")
        #expect(await tokens.refreshToken() == "renewed-refresh")
        #expect(await expirationEvents.next() == nil)
    }
}

private actor TestTokenStore: TokenStore {
    private var access = "expired-access"
    private var refresh = "current-refresh"

    func accessToken() -> String { access }
    func refreshToken() -> String { refresh }
    func update(accessToken: String, refreshToken: String) {
        access = accessToken
        refresh = refreshToken
    }
    func clear() {
        access = ""
        refresh = ""
    }
}

private final class RefreshURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "refresh-test.invalid"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let path = request.url?.path
        let authorization = request.value(forHTTPHeaderField: "Authorization")
        let requestBody = request.httpBody ?? readBodyStream()
        let status: Int
        let body: String

        if path == APIEndpoint.refreshToken {
            let payload = try? JSONSerialization.jsonObject(with: requestBody) as? [String: String]
            if payload?["deviceId"] == DeviceIDProvider.current(), payload?["refreshToken"] == "current-refresh" {
                status = 200
                body = #"{"accessToken":"renewed-access","refreshToken":"renewed-refresh"}"#
            } else {
                status = 400
                body = "{}"
            }
        } else if path == "/member", authorization == "Bearer expired-access" {
            status = 401
            body = "{}"
        } else if path == "/member", authorization == "Bearer renewed-access" {
            status = 200
            body = "42"
        } else {
            status = 400
            body = "{}"
        }

        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private func readBodyStream() -> Data {
        guard let stream = request.httpBodyStream else { return Data() }
        stream.open()
        defer { stream.close() }
        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            body.append(contentsOf: buffer[..<count])
        }
        return body
    }
}

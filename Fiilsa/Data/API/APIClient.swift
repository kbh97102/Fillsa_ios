import Foundation

protocol APIClientProtocol {
    func send<Response: Decodable, Body: Encodable>(
        _ request: APIRequest<Body>,
        responseType: Response.Type
    ) async throws -> Response
}

struct APIClient: APIClientProtocol {
    typealias AccessTokenProvider = @Sendable () async -> String?

    private let environment: APIEnvironment
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let accessTokenProvider: AccessTokenProvider

    init(
        environment: APIEnvironment = .production,
        session: URLSession = .shared,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        accessTokenProvider: @escaping AccessTokenProvider = { nil }
    ) {
        self.environment = environment
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
        self.accessTokenProvider = accessTokenProvider
    }

    func send<Response: Decodable, Body: Encodable>(
        _ request: APIRequest<Body>,
        responseType: Response.Type = Response.self
    ) async throws -> Response {
        let urlRequest = try await makeURLRequest(from: request)
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ErrorResponse.networkError
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let error = try? decoder.decode(ErrorResponse.self, from: data) {
                throw error
            }
            throw ErrorResponse(
                timestamp: "",
                httpStatus: httpResponse.statusCode,
                errorCode: httpResponse.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }

        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }

        return try decoder.decode(Response.self, from: data)
    }

    private func makeURLRequest<Body: Encodable>(from request: APIRequest<Body>) async throws -> URLRequest {
        var components = URLComponents(
            url: environment.baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = request.queryItems.isEmpty ? nil : request.queryItems

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if request.requiresAuthorization, let accessToken = await accessTokenProvider(), !accessToken.isEmpty {
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let body = request.body {
            urlRequest.httpBody = try encoder.encode(body)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return urlRequest
    }
}

struct EmptyResponse: Decodable, Equatable {}


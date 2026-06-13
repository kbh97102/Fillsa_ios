import Foundation
import Alamofire

@preconcurrency
protocol APIClientProtocol {
    func send<Response: Decodable, Body: Encodable>(
        _ request: APIRequest<Body>,
        responseType: Response.Type
    ) async throws -> Response
}

struct APIClient: APIClientProtocol {
    private let environment: APIEnvironment
    private let session: Session
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        environment: APIEnvironment = .production,
        session: Session = .default,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.environment = environment
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }

    func send<Response: Decodable, Body: Encodable>(
        _ request: APIRequest<Body>,
        responseType: Response.Type = Response.self
    ) async throws -> Response {
        if Response.self == EmptyResponse.self {
            _ = try await data(for: request)
            return EmptyResponse() as! Response
        }

        let data = try await data(for: request)
        return try decoder.decode(Response.self, from: data)
    }

    private func data<Body: Encodable>(for request: APIRequest<Body>) async throws -> Data {
        let response = await session
            .request(try makeURLRequest(from: request))
            .validate(statusCode: 200..<300)
            .serializingData()
            .response

        if let error = response.error {
            throw apiError(from: response, fallback: error)
        }

        guard let data = response.data else {
            return Data()
        }
        return data
    }

    private func makeURLRequest<Body: Encodable>(from request: APIRequest<Body>) throws -> URLRequest {
        var components = URLComponents(
            url: environment.baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = request.queryItems.isEmpty ? nil : request.queryItems

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.method = request.method.alamofireMethod
        urlRequest.headers = headers(for: request)

        if let body = request.body {
            urlRequest.httpBody = try encoder.encode(body)
        }

        return urlRequest
    }

    private func headers<Body: Encodable>(for request: APIRequest<Body>) -> HTTPHeaders {
        var headers: HTTPHeaders = ["Accept": "application/json"]
        if request.body != nil { headers.add(name: "Content-Type", value: "application/json") }
        if !request.requiresAuthorization {
            headers.add(name: FillsaRequestHeader.authorizationBehavior, value: FillsaRequestHeader.noAuthorization)
        }
        return headers
    }

    private func apiError(from response: AFDataResponse<Data>, fallback: AFError) -> Error {
        if let data = response.data, let error = try? decoder.decode(ErrorResponse.self, from: data) {
            return error
        }
        if let statusCode = response.response?.statusCode {
            return ErrorResponse(
                timestamp: "",
                httpStatus: statusCode,
                errorCode: statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: statusCode)
            )
        }
        return fallback
    }
}

struct EmptyResponse: Decodable, Equatable {}

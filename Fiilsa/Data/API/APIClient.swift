import Foundation
import Alamofire

struct APIRequestTiming: Equatable, Sendable {
    enum Outcome: Equatable, Sendable { case success, failure }

    let method: String
    let path: String
    let outcome: Outcome
    let requestMilliseconds: Int
    let decodeMilliseconds: Int
    let totalMilliseconds: Int
}

@preconcurrency
protocol APIClientProtocol {
    func send<Response: Decodable, Body: Encodable>(
        _ request: APIRequest<Body>,
        responseType: Response.Type
    ) async throws -> Response

    func uploadImage<Response: Decodable>(
        fileURL: URL,
        path: String,
        fieldName: String
    ) async throws -> Response
}

struct APIClient: APIClientProtocol {
    private let environment: APIEnvironment
    private let session: Session
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let onTiming: @Sendable (APIRequestTiming) -> Void

    init(
        environment: APIEnvironment = .production,
        session: Session = .default,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        onTiming: @escaping @Sendable (APIRequestTiming) -> Void = { HTTPLogger.logTiming($0) }
    ) {
        self.environment = environment
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
        self.onTiming = onTiming
    }

    func send<Response: Decodable, Body: Encodable>(
        _ request: APIRequest<Body>,
        responseType: Response.Type = Response.self
    ) async throws -> Response {
        let started = ProcessInfo.processInfo.systemUptime
        var responseReceived: TimeInterval?
        do {
            let data = try await data(for: request)
            responseReceived = ProcessInfo.processInfo.systemUptime
            if Response.self == EmptyResponse.self {
                onTiming(timing(for: request, started: started, responseReceived: responseReceived, outcome: .success))
                return EmptyResponse() as! Response
            }
            let decoded = try decode(data, responseType: Response.self)
            onTiming(timing(for: request, started: started, responseReceived: responseReceived, outcome: .success))
            return decoded
        } catch {
            onTiming(timing(for: request, started: started, responseReceived: responseReceived, outcome: .failure))
            throw error
        }
    }

    private func timing<Body: Encodable>(
        for request: APIRequest<Body>,
        started: TimeInterval,
        responseReceived: TimeInterval?,
        outcome: APIRequestTiming.Outcome
    ) -> APIRequestTiming {
        let finished = ProcessInfo.processInfo.systemUptime
        let received = responseReceived ?? finished
        return APIRequestTiming(
            method: request.method.rawValue,
            path: request.path,
            outcome: outcome,
            requestMilliseconds: Int((received - started) * 1_000),
            decodeMilliseconds: Int((finished - received) * 1_000),
            totalMilliseconds: Int((finished - started) * 1_000)
        )
    }

    private func decode<Response: Decodable>(_ data: Data, responseType: Response.Type) throws -> Response {
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            HTTPLogger.logDecodeError(error, responseType: Response.self, data: data)
            throw error
        }
    }

    func uploadImage<Response: Decodable>(
        fileURL: URL,
        path: String,
        fieldName: String
    ) async throws -> Response {
        let url = environment.baseURL.appendingPathComponent(path)
        let response = await session
            .upload(
                multipartFormData: { formData in
                    formData.append(
                        fileURL,
                        withName: fieldName,
                        fileName: fileURL.lastPathComponent,
                        mimeType: "image/jpeg"
                    )
                },
                to: url,
                method: .post,
                headers: [
                    "Accept": "application/json",
                    "X-App-Version": APIAppVersion.current
                ]
            )
            .validate(statusCode: 200..<300)
            .serializingData(emptyResponseCodes: [200, 204, 205])
            .response

        HTTPLogger.logResponse(response)

        if let error = response.error {
            throw apiError(from: response, fallback: error)
        }

        guard let data = response.data else {
            throw ErrorResponse.defaultError
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            HTTPLogger.logDecodeError(error, responseType: Response.self, data: data)
            throw error
        }
    }

    private func data<Body: Encodable>(for request: APIRequest<Body>) async throws -> Data {
        let urlRequest = try makeURLRequest(from: request)
        HTTPLogger.logRequest(urlRequest)

        let response = await session
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .serializingData(emptyResponseCodes: [200, 204, 205])
            .response

        HTTPLogger.logResponse(response)

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
        var headers: HTTPHeaders = [
            "Accept": "application/json",
            "X-App-Version": APIAppVersion.current
        ]
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

private enum APIAppVersion {
    static var current: String {
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        if let bundleVersion, bundleVersion != "1.0" {
            return bundleVersion
        }
        return "1.0.26"
    }
}

private enum HTTPLogger {
    static func logTiming(_ timing: APIRequestTiming) {
        #if DEBUG
        print("API timing \(timing.method) \(timing.path) outcome=\(timing.outcome) request=\(timing.requestMilliseconds)ms decode=\(timing.decodeMilliseconds)ms total=\(timing.totalMilliseconds)ms")
        #endif
    }
    static func logRequest(_ request: URLRequest) {
        #if DEBUG
        print("---------- REQUEST ----------")
        print("\(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
        print("header")
        request.allHTTPHeaderFields?
            .sorted { $0.key < $1.key }
            .forEach { print("\($0.key): \($0.value)") }
        print("message")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print(bodyString)
        } else {
            print("")
        }
        print("-----------------------------")
        #endif
    }

    static func logResponse(_ response: AFDataResponse<Data>) {
        #if DEBUG
        let request = response.request
        let statusCode = response.response?.statusCode ?? -1
        let elapsedMs = Int((response.metrics?.taskInterval.duration ?? 0) * 1000)

        print("---------- RESPONSE ----------")
        print("\(request?.httpMethod ?? "") \(request?.url?.absoluteString ?? "")")
        print("code \(statusCode) (\(elapsedMs)ms)")
        print("header")
        response.response?.allHeaderFields
            .map { "\($0.key): \($0.value)" }
            .sorted()
            .forEach { print($0) }
        print("message")
        if let data = response.data, let bodyString = String(data: data, encoding: .utf8) {
            print(bodyString)
        } else {
            print("")
        }
        print("------------------------------")
        #endif
    }

    static func logDecodeError<Response>(_ error: Error, responseType: Response.Type, data: Data) {
        #if DEBUG
        print("---------- DECODE ERROR ----------")
        print("type \(responseType)")
        print("error \(error)")
        print("message")
        print(String(data: data, encoding: .utf8) ?? "")
        print("----------------------------------")
        #endif
    }
}

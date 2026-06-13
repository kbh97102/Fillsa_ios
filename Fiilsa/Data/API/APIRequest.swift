import Foundation

struct APIRequest<Body: Encodable> {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }

    let method: Method
    let path: String
    var queryItems: [URLQueryItem] = []
    var body: Body?
    var requiresAuthorization: Bool = true

    init(
        method: Method,
        path: String,
        queryItems: [URLQueryItem] = [],
        body: Body? = nil,
        requiresAuthorization: Bool = true
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.body = body
        self.requiresAuthorization = requiresAuthorization
    }
}

struct EmptyRequestBody: Encodable {}


import Foundation

struct APIEnvironment: Equatable {
    let baseURL: URL

    static let production = APIEnvironment(
        baseURL: URL(string: "https://api.fillsa.com")!
    )
}


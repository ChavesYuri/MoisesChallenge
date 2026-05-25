import Foundation

enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The request URL could not be built."
        case .invalidResponse:
            "The server returned an unexpected response."
        case .serverError(let statusCode):
            "The server returned status code \(statusCode)."
        }
    }
}

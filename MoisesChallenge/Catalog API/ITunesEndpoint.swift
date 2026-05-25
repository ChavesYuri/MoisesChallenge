import Foundation

protocol APIEndpoint: Sendable {
    var path: String { get }
    var queryItems: [URLQueryItem] { get }
}

enum ITunesEndpoint {
    static let baseURL = URL(string: "https://itunes.apple.com")!

    struct Search: APIEndpoint {
        let term: String
        /// Cumulative result count from the start of the search (iTunes ignores `offset` for music).
        let limit: Int

        var path: String { "/search" }

        var queryItems: [URLQueryItem] {
            [
                URLQueryItem(name: "term", value: term),
                URLQueryItem(name: "media", value: "music"),
                URLQueryItem(name: "entity", value: "song"),
                URLQueryItem(name: "limit", value: "\(min(limit, ITunesSearchLimits.maxResults))")
            ]
        }
    }

    struct AlbumLookup: APIEndpoint {
        let collectionId: Int

        var path: String { "/lookup" }

        var queryItems: [URLQueryItem] {
            [
                URLQueryItem(name: "id", value: "\(collectionId)"),
                URLQueryItem(name: "entity", value: "song")
            ]
        }
    }
}

extension APIEndpoint {
    func url(baseURL: URL = ITunesEndpoint.baseURL) -> URL? {
        guard var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.queryItems = queryItems
        return components.url
    }
}

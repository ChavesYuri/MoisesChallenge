import Foundation

struct SongSearchPage: Sendable, Equatable {
    let items: [Song]
    let hasMore: Bool
}

enum ITunesSearchLimits {
    static let maxResults = 200
}

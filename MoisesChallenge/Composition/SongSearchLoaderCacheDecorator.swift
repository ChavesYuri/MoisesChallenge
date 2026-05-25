import Foundation

/// Decorator that persists successful remote page loads into SwiftData.
/// Wired through `MainSongRepository` to keep cache access on the main actor.
@MainActor
enum SongSearchLoaderCacheDecorator {
    static func search(
        decoratee: SongSearchLoader,
        cache: SongCache,
        term: String,
        limit: Int,
        offset: Int
    ) async throws -> SongSearchPage {
        let page = try await decoratee.search(term: term, limit: limit, offset: offset)
        try await cache.save(page.items)
        return page
    }
}

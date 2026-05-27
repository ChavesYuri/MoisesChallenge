import Foundation

/// Decorator that persists successful remote page loads into SwiftData.
/// Wired through `MainSongRepository` to keep cache access on the main actor.
final class SongSearchLoaderCacheDecorator: SongSearchLoader {
    private let decoratee: SongSearchLoader
    private let cache: SongCache
    
    init(decoratee: SongSearchLoader, cache: SongCache) {
        self.decoratee = decoratee
        self.cache = cache
    }
    
    @MainActor
    func search(term: String, limit: Int, offset: Int) async throws -> SongSearchPage {
        let page = try await decoratee.search(term: term, limit: limit, offset: offset)
        try await cache.save(page.items)
        return page
    }
}

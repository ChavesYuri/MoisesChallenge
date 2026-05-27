import Foundation

@MainActor
protocol SongRepository {
    func searchSongs(term: String, page: Int, pageSize: Int) async throws -> Paginated<Song>
    func albumSongs(collectionId: Int) async throws -> [Song]
    func recentlyPlayed(limit: Int) async throws -> [Song]
    func markPlayed(_ song: Song) async throws
}

@MainActor
final class MainSongRepository: SongRepository {
    private let remoteSearch: SongSearchLoader
    private let remoteAlbum: AlbumSongsLoader
    private let cache: SongCache

    init(remoteSearch: SongSearchLoader, remoteAlbum: AlbumSongsLoader, cache: SongCache) {
        self.remoteSearch = remoteSearch
        self.remoteAlbum = remoteAlbum
        self.cache = cache
    }

    func searchSongs(term: String, page: Int, pageSize: Int) async throws -> Paginated<Song> {
        let offset = page * pageSize
        do {
            let page = try await remoteSearch.search(
                term: term,
                limit: pageSize,
                offset: offset
            )
            return Paginated(items: page.items, hasMore: page.hasMore)
        } catch {
            let cached = try await cache.songs(matching: term, limit: pageSize, offset: offset)
            guard !cached.isEmpty else { throw error }
            let hasMore = cached.count == pageSize
            return Paginated(items: cached, hasMore: hasMore)
        }
    }

    func albumSongs(collectionId: Int) async throws -> [Song] {
        do {
            let songs = try await remoteAlbum.loadAlbumSongs(collectionId: collectionId)
            try await cache.save(songs)
            return songs
        } catch {
            let cached = try await cache.songs(matching: "", limit: 200, offset: 0)
                .filter { $0.collectionId == collectionId }
            guard !cached.isEmpty else { throw error }
            return cached
        }
    }

    func recentlyPlayed(limit: Int) async throws -> [Song] {
        try await cache.recentlyPlayed(limit: limit)
    }

    func markPlayed(_ song: Song) async throws {
        try await cache.markPlayed(song)
    }
}

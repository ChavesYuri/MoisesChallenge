import Foundation

enum SongLoaderError: Error, Equatable {
    case connectivity
    case invalidData
}

protocol SongSearchLoader {
    func search(term: String, limit: Int, offset: Int) async throws -> SongSearchPage
}

protocol AlbumSongsLoader {
    func loadAlbumSongs(collectionId: Int) async throws -> [Song]
}

@MainActor
protocol SongCache {
    func save(_ songs: [Song]) async throws
    func songs(matching term: String, limit: Int, offset: Int) async throws -> [Song]
    func recentlyPlayed(limit: Int) async throws -> [Song]
    func markPlayed(_ song: Song) async throws
}

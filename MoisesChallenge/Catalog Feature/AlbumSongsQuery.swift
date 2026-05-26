import Foundation

@MainActor
enum AlbumSongsQuery {
    static func songs(for seedSong: Song, repository: SongRepository) async throws -> [Song] {
        guard let collectionId = seedSong.collectionId else { return [seedSong] }
        return try await repository.albumSongs(collectionId: collectionId)
    }

    static func songsOrFallback(for seedSong: Song, repository: SongRepository) async -> [Song] {
        (try? await songs(for: seedSong, repository: repository)) ?? [seedSong]
    }
}

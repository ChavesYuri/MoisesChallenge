import Foundation
import SwiftData

@MainActor
final class LocalSongCacheLoader: SongCache {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ songs: [Song]) async throws {
        for song in songs {
            try upsert(song)
        }
        try context.save()
    }

    func songs(matching term: String, limit: Int, offset: Int) async throws -> [Song] {
        let normalizedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let descriptor = FetchDescriptor<CachedSong>(
            sortBy: [SortDescriptor(\.cachedAt, order: .reverse)]
        )
        let songs = try context.fetch(descriptor)
            .map { $0.toDomain() }
            .filter { song in
                normalizedTerm.isEmpty ||
                song.trackName.localizedCaseInsensitiveContains(normalizedTerm) ||
                song.artistName.localizedCaseInsensitiveContains(normalizedTerm) ||
                song.collectionName.localizedCaseInsensitiveContains(normalizedTerm)
            }

        guard offset < songs.count else { return [] }
        return Array(songs.dropFirst(offset).prefix(limit))
    }

    func recentlyPlayed(limit: Int) async throws -> [Song] {
        var descriptor = FetchDescriptor<CachedSong>(
            predicate: #Predicate { $0.lastPlayedAt != nil },
            sortBy: [SortDescriptor(\.lastPlayedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func markPlayed(_ song: Song) async throws {
        try upsert(song, lastPlayedAt: Date())
        try context.save()
    }

    private func upsert(_ song: Song, lastPlayedAt: Date? = nil) throws {
        let id = song.id
        let descriptor = FetchDescriptor<CachedSong>(
            predicate: #Predicate { $0.id == id }
        )
        if let cachedSong = try context.fetch(descriptor).first {
            cachedSong.update(with: song, lastPlayedAt: lastPlayedAt)
        } else {
            context.insert(CachedSong(song: song, lastPlayedAt: lastPlayedAt))
        }
    }
}

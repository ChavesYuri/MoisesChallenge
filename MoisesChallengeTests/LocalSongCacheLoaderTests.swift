import Foundation
import SwiftData
import Testing
@testable import MoisesChallenge

@MainActor
struct LocalSongCacheLoaderTests {
    @Test func saveAndSearchByTerm() async throws {
        let cache = try makeCache()
        let song = Song.fixture(id: 1, name: "Get Lucky")

        try await cache.save([song])
        let results = try await cache.songs(matching: "lucky", limit: 10, offset: 0)

        #expect(results.map(\.id) == [1])
    }

    @Test func markPlayedUpdatesRecentlyPlayedOrder() async throws {
        let cache = try makeCache()
        let first = Song.fixture(id: 1, name: "First")
        let second = Song.fixture(id: 2, name: "Second")

        try await cache.markPlayed(first)
        try await cache.markPlayed(second)
        let recent = try await cache.recentlyPlayed(limit: 2)

        #expect(recent.map(\.id) == [2, 1])
    }

    @Test func searchSupportsPaginationOffset() async throws {
        let cache = try makeCache()
        let songs = (1...3).map { Song.fixture(id: $0, name: "Track \($0)") }
        try await cache.save(songs)

        let page = try await cache.songs(matching: "", limit: 1, offset: 1)

        #expect(page.count == 1)
    }

    private func makeCache() throws -> LocalSongCacheLoader {
        let container = try ModelContainer(
            for: CachedSong.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return LocalSongCacheLoader(context: ModelContext(container))
    }
}

import Foundation
import Testing
@testable import MoisesChallenge

@MainActor
struct MoisesChallengeTests {
    @Test func songsViewModelLoadsFirstPageAndNextPage() async throws {
        let repository = FakeSongRepository(pages: [
            0: [.fixture(id: 1, name: "One"), .fixture(id: 2, name: "Two")],
            1: [.fixture(id: 3, name: "Three")]
        ])
        let viewModel = SongsViewModel(repository: repository, pageSize: 2)

        viewModel.searchText = "Daft Punk"
        await viewModel.submitSearch()

        #expect(viewModel.songs.map(\.id) == [1, 2])
        #expect(viewModel.state == .loaded)
        #expect(viewModel.hasMorePages)

        await viewModel.loadMoreIfNeeded(currentSong: try #require(viewModel.songs.last))

        #expect(viewModel.songs.map(\.id) == [1, 2, 3])
        #expect(!viewModel.hasMorePages)
        #expect(repository.requests == [
            SearchRequest(term: "Daft Punk", page: 0, pageSize: 2),
            SearchRequest(term: "Daft Punk", page: 1, pageSize: 2)
        ])
    }

    @Test func repositoryFallsBackToCacheWhenRemoteFails() async throws {
        let cache = FakeSongCache()
        cache.stored = [.fixture(id: 10, name: "Cached")]
        let repository = MainSongRepository(
            remoteSearch: FailingSongSearchLoader(),
            remoteAlbum: FailingAlbumSongsLoader(),
            cache: cache
        )

        let page = try await repository.searchSongs(term: "cached", page: 0, pageSize: 20)
        #expect(page.items.map(\.trackName) == ["Cached"])
    }

    @Test func repositoryCachesSuccessfulRemoteLoads() async throws {
        let cache = FakeSongCache()
        let repository = MainSongRepository(
            remoteSearch: StubSongSearchLoader(results: [.fixture(id: 1, name: "Fresh")]),
            remoteAlbum: FailingAlbumSongsLoader(),
            cache: cache
        )

        _ = try await repository.searchSongs(term: "a", page: 0, pageSize: 10)
        #expect(cache.saved.map(\.id) == [1])
    }

    @Test func markPlayedRefreshesRecentlyPlayed() async {
        let song = Song.fixture(id: 99, name: "Played")
        let repository = FakeSongRepository(recent: [])
        let viewModel = SongsViewModel(repository: repository)

        viewModel.markPlayed(song)
        try? await Task.sleep(for: .milliseconds(100))

        #expect(repository.playedSongs == [song])
    }

    @Test func cumulativePaginationReturnsDistinctPages() {
        let firstBatch = (1...20).map { Song.fixture(id: $0, name: "Track \($0)") }
        let first = ITunesSearchPaginator.page(
            from: firstBatch,
            fetchedCount: 20,
            requestedLimit: 20,
            pageLimit: 10,
            offset: 0
        )
        #expect(first.items.map(\.id) == Array(1...10))
        #expect(first.hasMore)

        let secondBatch = (1...40).map { Song.fixture(id: $0, name: "Track \($0)") }
        let second = ITunesSearchPaginator.page(
            from: secondBatch,
            fetchedCount: 40,
            requestedLimit: 40,
            pageLimit: 10,
            offset: 10
        )
        #expect(second.items.map(\.id) == Array(11...20))
        #expect(second.hasMore)

        let finalBatch = (1...25).map { Song.fixture(id: $0, name: "Track \($0)") }
        let last = ITunesSearchPaginator.page(
            from: finalBatch,
            fetchedCount: 25,
            requestedLimit: 40,
            pageLimit: 10,
            offset: 20
        )
        #expect(last.items.map(\.id) == Array(21...25))
        #expect(!last.hasMore)
    }

    @Test func mapperRejectsNon2xxResponses() {
        let response = HTTPURLResponse(
            url: URL(string: "https://itunes.apple.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!

        #expect(throws: ITunesSongMapper.MappingError.invalidStatusCode) {
            try ITunesSongMapper.map(Data(), from: response)
        }
    }
}

struct SearchRequest: Equatable {
    let term: String
    let page: Int
    let pageSize: Int
}

@MainActor
final class FakeSongRepository: SongRepository {
    var pages: [Int: [Song]]
    var recent: [Song]
    var requests: [SearchRequest] = []
    var playedSongs: [Song] = []

    init(pages: [Int: [Song]] = [:], recent: [Song] = []) {
        self.pages = pages
        self.recent = recent
    }

    func searchSongs(term: String, page: Int, pageSize: Int) async throws -> Paginated<Song> {
        requests.append(SearchRequest(term: term, page: page, pageSize: pageSize))
        let items = pages[page] ?? []
        return Paginated(items: items, hasMore: items.count == pageSize)
    }

    func albumSongs(collectionId: Int) async throws -> [Song] {
        pages.values.flatMap { $0 }.filter { $0.collectionId == collectionId }
    }

    func recentlyPlayed(limit: Int) async throws -> [Song] {
        Array(recent.prefix(limit))
    }

    func markPlayed(_ song: Song) async throws {
        playedSongs.append(song)
        recent.insert(song, at: 0)
    }
}

struct FailingSongSearchLoader: SongSearchLoader {
    func search(term: String, limit: Int, offset: Int) async throws -> SongSearchPage {
        throw SongLoaderError.connectivity
    }
}

struct FailingAlbumSongsLoader: AlbumSongsLoader {
    func loadAlbumSongs(collectionId: Int) async throws -> [Song] {
        throw SongLoaderError.connectivity
    }
}

struct StubSongSearchLoader: SongSearchLoader {
    let results: [Song]

    func search(term: String, limit: Int, offset: Int) async throws -> SongSearchPage {
        SongSearchPage(items: results, hasMore: false)
    }
}

@MainActor
final class FakeSongCache: SongCache {
    var stored: [Song] = []
    var saved: [Song] = []
    var recentlyPlayedSongs: [Song] = []
    var markedPlayed: [Song] = []

    func save(_ songs: [Song]) async throws {
        saved = songs
        stored.append(contentsOf: songs)
    }

    func songs(matching term: String, limit: Int, offset: Int) async throws -> [Song] {
        Array(stored.dropFirst(offset).prefix(limit))
    }

    func recentlyPlayed(limit: Int) async throws -> [Song] {
        Array(recentlyPlayedSongs.prefix(limit))
    }

    func markPlayed(_ song: Song) async throws {
        markedPlayed.append(song)
    }
}

extension Song {
    static func fixture(id: Int, name: String, collectionId: Int = 100) -> Song {
        Song(
            id: id,
            trackName: name,
            artistName: "Artist \(id)",
            collectionName: "Album",
            artworkURL100: nil,
            previewURL: nil,
            trackPrice: nil,
            currency: nil,
            primaryGenreName: "Pop",
            releaseDate: nil,
            trackTimeMillis: 180000,
            collectionId: collectionId
        )
    }
}

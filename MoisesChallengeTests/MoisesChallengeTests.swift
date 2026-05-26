import Foundation
import SwiftData
import Testing
@testable import MoisesChallenge

@MainActor
struct MoisesChallengeTests {
    @Test func songsViewModelLoadsFirstPageAndNextPage() async throws {
        let repository = FakeSongRepository(pages: [
            0: [.fixture(id: 1, name: "One"), .fixture(id: 2, name: "Two")],
            1: [.fixture(id: 3, name: "Three")]
        ])
        let viewModel = SongsViewModel(
            repository: repository,
            watchSync: FakeWatchLibraryPublisher(),
            pageSize: 2
        )

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

    @Test func songsViewModelSubmitSearchWithEmptyTermResetsState() async {
        let repository = FakeSongRepository()
        let viewModel = SongsViewModel(
            repository: repository,
            watchSync: FakeWatchLibraryPublisher()
        )

        viewModel.searchText = "   "
        await viewModel.submitSearch()

        #expect(viewModel.songs.isEmpty)
        #expect(viewModel.state == .idle)
        #expect(repository.requests.isEmpty)
    }

    @Test func songsViewModelRefreshReloadsCurrentSearch() async {
        let repository = FakeSongRepository(pages: [
            0: [.fixture(id: 1, name: "Fresh")]
        ])
        let viewModel = SongsViewModel(
            repository: repository,
            watchSync: FakeWatchLibraryPublisher()
        )

        viewModel.searchText = "query"
        await viewModel.submitSearch()
        repository.requests.removeAll()
        await viewModel.refresh()

        #expect(viewModel.state == .loaded)
        #expect(repository.requests == [SearchRequest(term: "query", page: 0, pageSize: 20)])
    }

    @Test func songsViewModelLoadMoreFailureRollsBackPage() async throws {
        let repository = FakeSongRepository(pages: [
            0: [.fixture(id: 1, name: "One"), .fixture(id: 2, name: "Two")]
        ])
        repository.pages[1] = nil
        let failingRepository = FailingSearchRepository(base: repository)
        let viewModel = SongsViewModel(
            repository: failingRepository,
            watchSync: FakeWatchLibraryPublisher(),
            pageSize: 2
        )

        viewModel.searchText = "query"
        await viewModel.submitSearch()
        await viewModel.loadMoreIfNeeded(currentSong: try #require(viewModel.songs.last))

        #expect(viewModel.state == .error("offline"))
        #expect(viewModel.songs.map(\.id) == [1, 2])
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

    @Test func repositoryFallsBackToCacheForAlbumSongs() async throws {
        let cache = FakeSongCache()
        cache.stored = [.fixture(id: 5, name: "Album Track", collectionId: 777)]
        let repository = MainSongRepository(
            remoteSearch: FailingSongSearchLoader(),
            remoteAlbum: FailingAlbumSongsLoader(),
            cache: cache
        )

        let songs = try await repository.albumSongs(collectionId: 777)
        #expect(songs.map(\.id) == [5])
    }

    @Test func markPlayedRefreshesRecentlyPlayedAndPublishesToWatch() async {
        let song = Song.fixture(id: 99, name: "Played")
        let repository = FakeSongRepository(recent: [])
        let watchSync = FakeWatchLibraryPublisher()
        let viewModel = SongsViewModel(repository: repository, watchSync: watchSync)

        viewModel.markPlayed(song)
        try? await Task.sleep(for: .milliseconds(100))

        #expect(repository.playedSongs == [song])
        #expect(watchSync.publishedPayloads.count == 1)
        #expect(watchSync.publishedPayloads.first?.currentSong?.id == 99)
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

@MainActor
private final class FailingSearchRepository: SongRepository {
    private let base: FakeSongRepository
    private var searchCount = 0

    init(base: FakeSongRepository) {
        self.base = base
    }

    func searchSongs(term: String, page: Int, pageSize: Int) async throws -> Paginated<Song> {
        searchCount += 1
        if searchCount > 1 {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "offline"])
        }
        return try await base.searchSongs(term: term, page: page, pageSize: pageSize)
    }

    func albumSongs(collectionId: Int) async throws -> [Song] {
        try await base.albumSongs(collectionId: collectionId)
    }

    func recentlyPlayed(limit: Int) async throws -> [Song] {
        try await base.recentlyPlayed(limit: limit)
    }

    func markPlayed(_ song: Song) async throws {
        try await base.markPlayed(song)
    }
}

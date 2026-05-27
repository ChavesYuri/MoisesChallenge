import Foundation
import Testing
@testable import MoisesChallenge

struct RemoteLoaderTests {
    @Test func remoteSearchLoaderMapsSuccessfulResponse() async throws {
        let client = StubHTTPClient(behavior: .success(TestJSON.validSearchResponse, .ok()))
        let loader = RemoteSongSearchLoader(client: client)

        let page = try await loader.search(term: "daft", limit: 10, offset: 0)

        #expect(page.items.count == 1)
        #expect(page.items.first?.trackName == "One More Time")
        #expect(!page.hasMore)
    }

    @Test func remoteSearchLoaderMapsConnectivityErrors() async {
        let client = StubHTTPClient(behavior: .failure(URLError(.notConnectedToInternet)))
        let loader = RemoteSongSearchLoader(client: client)

        await #expect(throws: SongLoaderError.connectivity) {
            _ = try await loader.search(term: "daft", limit: 10, offset: 0)
        }
    }

    @Test func remoteAlbumLoaderMapsSuccessfulResponse() async throws {
        let client = StubHTTPClient(behavior: .success(TestJSON.validSearchResponse, .ok()))
        let loader = RemoteAlbumSongsLoader(client: client)

        let songs = try await loader.loadAlbumSongs(collectionId: 200)

        #expect(songs.count == 1)
        #expect(songs.first?.collectionId == 200)
    }

    @Test func remoteAlbumLoaderMapsInvalidDataErrors() async {
        let client = StubHTTPClient(behavior: .failure(SongLoaderError.invalidData))
        let loader = RemoteAlbumSongsLoader(client: client)

        await #expect(throws: SongLoaderError.invalidData) {
            _ = try await loader.loadAlbumSongs(collectionId: 1)
        }
    }

    @Test @MainActor func searchLoaderCacheDecoratorPersistsSuccessfulResults() async throws {
        let cache = FakeSongCache()
        let loader = StubSongSearchLoader(results: [.fixture(id: 11, name: "Saved")])
        let sut = SongSearchLoaderCacheDecorator(decoratee: loader, cache: cache)

        let page = try await sut.search(term: "saved", limit: 10, offset: 0)

        #expect(page.items.map(\.id) == [11])
        #expect(cache.saved.map(\.id) == [11])
    }
}

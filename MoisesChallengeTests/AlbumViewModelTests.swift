import Foundation
import Testing
@testable import MoisesChallenge

@MainActor
struct AlbumViewModelTests {
    @Test func loadWithoutCollectionIdUsesSeedSong() async {
        let seed = Song.fixture(id: 1, name: "Single", collectionId: 0)
        let seedWithoutAlbum = Song(
            id: seed.id,
            trackName: seed.trackName,
            artistName: seed.artistName,
            collectionName: seed.collectionName,
            artworkURL100: seed.artworkURL100,
            previewURL: seed.previewURL,
            trackPrice: seed.trackPrice,
            currency: seed.currency,
            primaryGenreName: seed.primaryGenreName,
            releaseDate: seed.releaseDate,
            trackTimeMillis: seed.trackTimeMillis,
            collectionId: nil
        )
        let viewModel = AlbumViewModel(seedSong: seedWithoutAlbum, repository: FakeSongRepository())

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.songs.map(\.id) == [1])
    }

    @Test func loadWithCollectionIdFetchesAlbumTracks() async {
        let seed = Song.fixture(id: 2, name: "Seed", collectionId: 300)
        let repository = FakeSongRepository()
        repository.albumSongsByCollectionId[300] = [
            .fixture(id: 2, name: "Seed", collectionId: 300),
            .fixture(id: 3, name: "Track Two", collectionId: 300)
        ]
        let viewModel = AlbumViewModel(seedSong: seed, repository: repository)

        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.songs.map(\.id) == [2, 3])
    }

    @Test func loadSetsEmptyStateWhenAlbumHasNoTracks() async {
        let seed = Song.fixture(id: 4, name: "Seed", collectionId: 400)
        let repository = FakeSongRepository()
        repository.albumSongsByCollectionId[400] = []
        let viewModel = AlbumViewModel(seedSong: seed, repository: repository)

        await viewModel.load()

        #expect(viewModel.state == .empty)
        #expect(viewModel.songs.isEmpty)
    }

    @Test func loadSetsErrorStateWhenRepositoryFails() async {
        let seed = Song.fixture(id: 5, name: "Seed", collectionId: 500)
        let repository = FailingAlbumRepository()
        let viewModel = AlbumViewModel(seedSong: seed, repository: repository)

        await viewModel.load()

        if case .error = viewModel.state {
            #expect(true)
        } else {
            Issue.record("Expected error state")
        }
    }
}

@MainActor
private final class FailingAlbumRepository: SongRepository {
    func searchSongs(term: String, page: Int, pageSize: Int) async throws -> Paginated<Song> {
        Paginated(items: [], hasMore: false)
    }

    func albumSongs(collectionId: Int) async throws -> [Song] {
        throw SongLoaderError.connectivity
    }

    func recentlyPlayed(limit: Int) async throws -> [Song] { [] }

    func markPlayed(_ song: Song) async throws {}
}

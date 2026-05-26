import Foundation
import Testing
@testable import MoisesChallenge

@MainActor
struct PlayerViewModelTests {
    @Test func appearPlaysPreviewAndUpdatesNowPlaying() async throws {
        let song = Song.fixture(id: 1, name: "Track")
        let repository = FakeSongRepository()
        let audioPlayer = FakeAudioPlayer()
        let nowPlaying = FakeNowPlayingManager()
        let viewModel = PlayerViewModel(
            song: song,
            repository: repository,
            audioPlayer: audioPlayer,
            nowPlaying: nowPlaying
        )

        viewModel.appear()
        try await Task.sleep(for: .milliseconds(50))

        #expect(audioPlayer.playedURL == song.previewURL)
        #expect(audioPlayer.isPlaying)
        #expect(viewModel.isPlaying)
        #expect(nowPlaying.configuredRemoteCommands)
        #expect(nowPlaying.updates.contains(where: { $0.songID == 1 && $0.isPlaying }))
        #expect(repository.playedSongs.map(\.id) == [1])
    }

    @Test func appearWithoutPreviewSetsMessage() {
        let song = Song.fixture(id: 2, name: "No Preview", includesPreview: false)
        let viewModel = PlayerViewModel(
            song: song,
            repository: FakeSongRepository(),
            audioPlayer: FakeAudioPlayer(),
            nowPlaying: FakeNowPlayingManager()
        )

        viewModel.appear()

        #expect(viewModel.message == "Preview audio is not available for this song.")
    }

    @Test func togglePlaybackUpdatesStateAndNowPlaying() {
        let viewModel = PlayerViewModel(
            song: .fixture(id: 3, name: "Toggle"),
            repository: FakeSongRepository(),
            audioPlayer: FakeAudioPlayer(),
            nowPlaying: FakeNowPlayingManager()
        )

        viewModel.appear()
        viewModel.togglePlayback()

        #expect(!viewModel.isPlaying)
    }

    @Test func seekForwardAndBackwardUpdateCurrentTime() {
        let audioPlayer = FakeAudioPlayer()
        let viewModel = PlayerViewModel(
            song: .fixture(id: 4, name: "Seek"),
            repository: FakeSongRepository(),
            audioPlayer: audioPlayer,
            nowPlaying: FakeNowPlayingManager()
        )

        viewModel.appear()
        viewModel.seekForward()
        #expect(audioPlayer.seekDelta == 15)

        viewModel.seekBackward()
        #expect(audioPlayer.seekDelta == -15)
    }

    @Test func disappearStopsPlaybackAndClearsNowPlaying() {
        let audioPlayer = FakeAudioPlayer()
        let nowPlaying = FakeNowPlayingManager()
        let viewModel = PlayerViewModel(
            song: .fixture(id: 5, name: "Clear"),
            repository: FakeSongRepository(),
            audioPlayer: audioPlayer,
            nowPlaying: nowPlaying
        )

        viewModel.appear()
        viewModel.disappear()

        #expect(!audioPlayer.isPlaying)
        #expect(audioPlayer.playedURL == nil)
        #expect(!viewModel.isPlaying)
        #expect(nowPlaying.cleared)
    }

    @Test func loadQueueUsesAlbumSongsWhenCollectionExists() async throws {
        let song = Song.fixture(id: 6, name: "Album Song", collectionId: 500)
        let albumTrack = Song.fixture(id: 7, name: "Other Track", collectionId: 500)
        let repository = FakeSongRepository()
        repository.albumSongsByCollectionId[500] = [song, albumTrack]
        let viewModel = PlayerViewModel(
            song: song,
            repository: repository,
            audioPlayer: FakeAudioPlayer(),
            nowPlaying: FakeNowPlayingManager()
        )

        viewModel.appear()
        try await Task.sleep(for: .milliseconds(50))

        #expect(viewModel.queueSongs.map(\.id) == [6, 7])
    }
}

import SwiftUI

@MainActor
@Observable
final class PlayerViewModel {
    let song: Song
    private(set) var isPlaying = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 30
    private(set) var message: String?
    private(set) var queueSongs: [Song] = []

    private let repository: SongRepository
    private let audioPlayer: AudioPlayerService

    init(
        song: Song,
        repository: SongRepository,
        audioPlayer: AudioPlayerService = SharedPlaybackService.shared
    ) {
        self.song = song
        self.repository = repository
        self.audioPlayer = audioPlayer
        self.duration = song.durationSeconds > 0 ? song.durationSeconds : 30
    }

    var remainingTimeText: String {
        "-" + Song.formatTime(max(duration - currentTime, 0))
    }

    var currentTimeText: String {
        Song.formatTime(currentTime)
    }

    func appear() {
        Task {
            try? await repository.markPlayed(song)
            await loadQueue()
        }

        guard let previewURL = song.previewURL else {
            message = "Preview audio is not available for this song."
            return
        }

        audioPlayer.onTimeUpdate = { [weak self] current, total in
            guard let self else { return }
            currentTime = current
            if total > 0 { duration = total }
            updateNowPlaying()
        }

        configureRemoteCommands()
        audioPlayer.play(url: previewURL)
        isPlaying = true
        updateNowPlaying()
    }

    func togglePlayback() {
        audioPlayer.togglePlayback()
        isPlaying = audioPlayer.isPlaying
        updateNowPlaying()
    }

    func seekForward() {
        audioPlayer.seek(by: 15)
        currentTime = audioPlayer.currentTime
        updateNowPlaying()
    }

    func seekBackward() {
        audioPlayer.seek(by: -15)
        currentTime = audioPlayer.currentTime
        updateNowPlaying()
    }

    func scrub(to progress: Double) {
        let target = duration * progress
        audioPlayer.seek(to: target)
        currentTime = audioPlayer.currentTime
        updateNowPlaying()
    }

    func disappear() {
        NowPlayingManager.clear()
    }

    private func loadQueue() async {
        guard let collectionId = song.collectionId else {
            queueSongs = [song]
            return
        }
        queueSongs = (try? await repository.albumSongs(collectionId: collectionId)) ?? [song]
    }

    private func updateNowPlaying() {
        NowPlayingManager.update(
            song: song,
            currentTime: currentTime,
            duration: duration,
            isPlaying: isPlaying
        )
    }

    private func configureRemoteCommands() {
        NowPlayingManager.configureRemoteCommands(
            onPlay: { [weak self] in
                guard let self, !isPlaying else { return }
                togglePlayback()
            },
            onPause: { [weak self] in
                guard let self, isPlaying else { return }
                togglePlayback()
            },
            onSkipForward: { [weak self] in self?.seekForward() },
            onSkipBackward: { [weak self] in self?.seekBackward() }
        )
    }
}

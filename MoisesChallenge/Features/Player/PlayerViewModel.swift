import Foundation
import Observation

@MainActor
@Observable
final class PlayerViewModel {
    let song: Song
    private(set) var isPlaying = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 30
    private(set) var message: String?

    private let repository: SongRepository
    private let audioPlayer: AudioPlayerService

    init(song: Song, repository: SongRepository, audioPlayer: AudioPlayerService = AVAudioPlayerService()) {
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
        Task { try? await repository.markPlayed(song) }

        guard let previewURL = song.previewURL else {
            message = "Preview audio is not available for this song."
            return
        }

        audioPlayer.onTimeUpdate = { [weak self] current, total in
            guard let self else { return }
            currentTime = current
            if total > 0 { duration = total }
        }

        audioPlayer.play(url: previewURL)
        isPlaying = true
    }

    func togglePlayback() {
        audioPlayer.togglePlayback()
        isPlaying = audioPlayer.isPlaying
    }

    func seekForward() {
        audioPlayer.seek(by: 15)
        currentTime = audioPlayer.currentTime
    }

    func seekBackward() {
        audioPlayer.seek(by: -15)
        currentTime = audioPlayer.currentTime
    }

    func scrub(to progress: Double) {
        let target = duration * progress
        audioPlayer.seek(to: target)
        currentTime = audioPlayer.currentTime
    }

    func disappear() {
        audioPlayer.stop()
        isPlaying = false
    }
}

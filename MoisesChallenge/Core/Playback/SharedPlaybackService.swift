import AVFoundation
import Foundation

@MainActor
final class SharedPlaybackService: AudioPlayerService {
    private let playerService = AVAudioPlayerService()

    var onTimeUpdate: ((Double, Double) -> Void)? {
        get { playerService.onTimeUpdate }
        set { playerService.onTimeUpdate = newValue }
    }

    var isPlaying: Bool { playerService.isPlaying }
    var currentTime: Double { playerService.currentTime }
    var duration: Double { playerService.duration }

    init() {
        configureAudioSession()
    }

    func play(url: URL) {
        playerService.play(url: url)
    }

    func togglePlayback() {
        playerService.togglePlayback()
    }

    func seek(to seconds: Double) {
        playerService.seek(to: seconds)
    }

    func seek(by seconds: Double) {
        playerService.seek(by: seconds)
    }

    func stop() {
        playerService.stop()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }
}

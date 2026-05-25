import AVFoundation
import Foundation

@MainActor
protocol AudioPlayerService: AnyObject {
    var isPlaying: Bool { get }
    var currentTime: Double { get }
    var duration: Double { get }
    var onTimeUpdate: ((Double, Double) -> Void)? { get set }

    func play(url: URL)
    func togglePlayback()
    func seek(to seconds: Double)
    func seek(by seconds: Double)
    func stop()
}

@MainActor
final class AVAudioPlayerService: AudioPlayerService {
    private var player: AVPlayer?
    private var timeObserver: Any?
    var onTimeUpdate: ((Double, Double) -> Void)?

    var isPlaying: Bool {
        player?.timeControlStatus == .playing
    }

    var currentTime: Double {
        guard let player else { return 0 }
        return CMTimeGetSeconds(player.currentTime())
    }

    var duration: Double {
        guard let duration = player?.currentItem?.duration else { return 0 }
        let seconds = CMTimeGetSeconds(duration)
        return seconds.isFinite ? seconds : 0
    }

    func play(url: URL) {
        stop()
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        addPeriodicObserver()
        player?.play()
    }

    func togglePlayback() {
        guard let player else { return }
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            player.play()
        }
    }

    func seek(to seconds: Double) {
        guard let player else { return }
        let time = CMTime(seconds: max(seconds, 0), preferredTimescale: 600)
        player.seek(to: time)
        notifyTime()
    }

    func seek(by seconds: Double) {
        seek(to: currentTime + seconds)
    }

    func stop() {
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        player?.pause()
        player = nil
    }

    private func addPeriodicObserver() {
        guard let player else { return }
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            self?.notifyTime()
        }
    }

    private func notifyTime() {
        onTimeUpdate?(currentTime, duration)
    }
}

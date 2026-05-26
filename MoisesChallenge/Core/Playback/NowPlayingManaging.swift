import Foundation

@MainActor
protocol NowPlayingManaging: AnyObject {
    func update(song: Song, currentTime: TimeInterval, duration: TimeInterval, isPlaying: Bool)
    func configureRemoteCommands(
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onSkipForward: @escaping () -> Void,
        onSkipBackward: @escaping () -> Void
    )
    func clear()
}

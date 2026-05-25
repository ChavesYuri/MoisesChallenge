import Foundation
import MediaPlayer
import UIKit

@MainActor
enum NowPlayingManager {
    private static var artworkTask: Task<Void, Never>?
    private static var loadedArtworkSongID: Int?
    private static var cachedArtwork: MPMediaItemArtwork?
    private static var lastInfo: [String: Any] = [:]

    static func update(song: Song, currentTime: TimeInterval, duration: TimeInterval, isPlaying: Bool) {
        if loadedArtworkSongID != song.id {
            artworkTask?.cancel()
            artworkTask = nil
            loadedArtworkSongID = song.id
            cachedArtwork = nil
        }

        let safeCurrentTime = sanitizedTime(currentTime)
        let safeDuration = sanitizedTime(duration)

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.trackName,
            MPMediaItemPropertyArtist: song.artistName,
            MPMediaItemPropertyAlbumTitle: song.collectionName,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: safeCurrentTime,
            MPMediaItemPropertyPlaybackDuration: safeDuration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1 : 0,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue
        ]

        if let cachedArtwork {
            info[MPMediaItemPropertyArtwork] = cachedArtwork
        }

        lastInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        guard cachedArtwork == nil,
              artworkTask == nil,
              let url = song.artworkURL600 ?? song.artworkURL100 else { return }

        let songID = song.id
        artworkTask = Task {
            defer { artworkTask = nil }

            guard let image = await loadImage(from: url),
                  let imageData = image.pngData(),
                  image.size.width > 0,
                  image.size.height > 0,
                  !Task.isCancelled,
                  loadedArtworkSongID == songID else { return }

            let boundsSize = image.size
            let artwork = MPMediaItemArtwork(boundsSize: boundsSize) { @Sendable _ in
                UIImage(data: imageData) ?? UIImage()
            }
            cachedArtwork = artwork

            guard loadedArtworkSongID == songID else { return }
            var updated = lastInfo
            updated[MPMediaItemPropertyArtwork] = artwork
            lastInfo = updated
            MPNowPlayingInfoCenter.default().nowPlayingInfo = updated
        }
    }

    static func configureRemoteCommands(
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onSkipForward: @escaping () -> Void,
        onSkipBackward: @escaping () -> Void
    ) {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)
        center.skipForwardCommand.removeTarget(nil)
        center.skipBackwardCommand.removeTarget(nil)

        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.skipForwardCommand.isEnabled = true
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.isEnabled = true
        center.skipBackwardCommand.preferredIntervals = [15]

        center.playCommand.addTarget { _ in onPlay(); return .success }
        center.pauseCommand.addTarget { _ in onPause(); return .success }
        center.togglePlayPauseCommand.addTarget { _ in onPlay(); return .success }
        center.skipForwardCommand.addTarget { _ in onSkipForward(); return .success }
        center.skipBackwardCommand.addTarget { _ in onSkipBackward(); return .success }
    }

    static func clear() {
        artworkTask?.cancel()
        artworkTask = nil
        loadedArtworkSongID = nil
        cachedArtwork = nil
        lastInfo = [:]
        MPNowPlayingInfoCenter.default().playbackState = .stopped
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    private static func sanitizedTime(_ value: TimeInterval) -> TimeInterval {
        value.isFinite && value >= 0 ? value : 0
    }

    private static func loadImage(from url: URL) async -> UIImage? {
        await Task.detached(priority: .utility) {
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
            return UIImage(data: data)
        }.value
    }
}

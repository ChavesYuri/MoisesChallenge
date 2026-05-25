import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityService: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityService()

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func publish(recentlyPlayed: [Song], currentSong: Song?) {
        guard WCSession.default.activationState == .activated else { return }
        let payload = WatchLibraryPayload(
            recentlyPlayed: recentlyPlayed.map(WatchSong.init),
            currentSong: currentSong.map(WatchSong.init)
        )
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? WCSession.default.updateApplicationContext(["library": data])
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}

struct WatchSong: Codable, Identifiable, Hashable {
    let id: Int
    let trackName: String
    let artistName: String
    let collectionName: String
    let artworkURLString: String?
    let previewURLString: String?
    let collectionId: Int?

    init(_ song: Song) {
        id = song.id
        trackName = song.trackName
        artistName = song.artistName
        collectionName = song.collectionName
        artworkURLString = song.artworkURL100?.absoluteString
        previewURLString = song.previewURL?.absoluteString
        collectionId = song.collectionId
    }

    var artworkURL: URL? { artworkURLString.flatMap(URL.init(string:)) }
    var previewURL: URL? { previewURLString.flatMap(URL.init(string:)) }
}

struct WatchLibraryPayload: Codable {
    let recentlyPlayed: [WatchSong]
    let currentSong: WatchSong?
}

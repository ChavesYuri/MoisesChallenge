import Foundation
import WatchConnectivity

@MainActor
final class WatchConnectivityService: NSObject, WCSessionDelegate, WatchLibraryPublisher {
    override init() {
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

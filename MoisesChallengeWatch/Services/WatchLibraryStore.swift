import Foundation
import Observation
import WatchConnectivity

@MainActor
@Observable
final class WatchLibraryStore: NSObject, WCSessionDelegate {
    private(set) var recentlyPlayed: [WatchSong] = []
    private(set) var currentSong: WatchSong?

    override init() {
        super.init()
        activateSession()
    }

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["library"] as? Data,
              let payload = try? JSONDecoder().decode(WatchLibraryPayload.self, from: data) else { return }
        Task { @MainActor in
            recentlyPlayed = payload.recentlyPlayed
            currentSong = payload.currentSong
        }
    }
}

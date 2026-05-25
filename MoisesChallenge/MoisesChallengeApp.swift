import SwiftUI

@main
struct MoisesChallengeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var composition = CompositionRoot()

    var body: some Scene {
        WindowGroup {
            AppView(composition: composition)
                .onAppear {
                    AppServices.composition = composition
                    WatchConnectivityService.shared.activate()
                }
                .task { await syncWatchLibrary(from: composition) }
        }
    }

    @MainActor
    private func syncWatchLibrary(from composition: CompositionRoot) async {
        let recent = (try? await composition.repository.recentlyPlayed(limit: 12)) ?? []
        WatchConnectivityService.shared.publish(recentlyPlayed: recent, currentSong: nil)
    }
}

import SwiftUI

struct WatchRootView: View {
    @State private var store = WatchLibraryStore()
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                WatchSplashView()
            } else {
                NavigationStack {
                    WatchSongsView(store: store)
                        .navigationDestination(for: WatchSong.self) { song in
                            WatchPlayerView(song: song)
                        }
                }
            }
        }
        .task(id: showSplash) {
            guard showSplash else { return }
            try? await Task.sleep(for: .seconds(1.0))
            withAnimation { showSplash = false }
        }
    }
}

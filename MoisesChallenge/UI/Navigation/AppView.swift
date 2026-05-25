import SwiftUI

struct AppView: View {
    let composition: CompositionRoot

    @State private var showSplash = true
    @State private var path = NavigationPath()
    @State private var isSearchBarVisible = true
    @State private var focusSearchTrigger = false

    var body: some View {
        Group {
            if showSplash {
                SplashScreen()
            } else {
                navigationContent
            }
        }
        .preferredColorScheme(.dark)
        .task(id: showSplash) {
            guard showSplash else { return }
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeOut(duration: 0.35)) {
                showSplash = false
            }

        }
    }

    private var navigationContent: some View {
        NavigationStack(path: $path) {
            SongsUIComposer.composed(
                repository: composition.repository,
                onSelectSong: { song in
                    path.append(Route.player(song))
                },
                onShowAlbum: { song in
                    path.append(Route.album(song))
                }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .player(let song):
                    PlayerUIComposer.composed(
                        song: song,
                        repository: composition.repository,
                        onShowAlbum: { path.append(Route.album(song)) }
                    )
                case .album(let song):
                    AlbumScreen(viewModel: AlbumViewModel(seedSong: song, repository: composition.repository))
                }
            }
        }
        .tint(.white)
    }
}

enum Route: Hashable {
    case player(Song)
    case album(Song)
}

extension Notification.Name {
    static let focusSongsSearch = Notification.Name("focusSongsSearch")
}

struct SearchBarVisibilityKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue = true
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

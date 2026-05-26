import SwiftUI

struct AppView: View {
    let composition: CompositionRoot

    @State private var showSplash = true
    @State private var path = NavigationPath()

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
                composition: composition,
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
                        composition: composition,
                        onShowAlbum: { path.append(Route.album(song)) }
                    )
                case .album(let song):
                    AdaptiveAlbumScreen(
                        viewModel: AlbumViewModel(seedSong: song, repository: composition.repository)
                    )
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

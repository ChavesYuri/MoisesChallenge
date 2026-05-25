import SwiftUI

enum SongsUIComposer {
    @MainActor
    static func composed(
        repository: SongRepository,
        onSelectSong: @escaping (Song) -> Void,
        onShowAlbum: @escaping (Song) -> Void
    ) -> SongsScreen {
        SongsScreen(
            viewModel: SongsViewModel(repository: repository),
            onSelectSong: onSelectSong,
            onShowAlbum: onShowAlbum
        )
    }
}

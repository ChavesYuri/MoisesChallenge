import SwiftUI

enum SongsUIComposer {
    @MainActor
    static func composed(
        composition: CompositionRoot,
        onSelectSong: @escaping (Song) -> Void,
        onShowAlbum: @escaping (Song) -> Void
    ) -> AdaptiveSongsScreen {
        AdaptiveSongsScreen(
            viewModel: SongsViewModel(
                repository: composition.repository,
                watchSync: composition.watchSync
            ),
            onSelectSong: onSelectSong,
            onShowAlbum: onShowAlbum
        )
    }
}

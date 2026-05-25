import SwiftUI

enum PlayerUIComposer {
    @MainActor
    static func composed(
        song: Song,
        repository: SongRepository,
        onShowAlbum: @escaping () -> Void
    ) -> AdaptivePlayerScreen {
        AdaptivePlayerScreen(
            viewModel: PlayerViewModel(song: song, repository: repository),
            onShowAlbum: onShowAlbum
        )
    }
}

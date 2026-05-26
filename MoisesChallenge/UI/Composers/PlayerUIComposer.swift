import SwiftUI

enum PlayerUIComposer {
    @MainActor
    static func composed(
        song: Song,
        composition: CompositionRoot,
        onShowAlbum: @escaping () -> Void
    ) -> AdaptivePlayerScreen {
        AdaptivePlayerScreen(
            viewModel: PlayerViewModel(
                song: song,
                repository: composition.repository,
                audioPlayer: composition.playback,
                nowPlaying: composition.nowPlaying
            ),
            onShowAlbum: onShowAlbum
        )
    }
}

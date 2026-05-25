import SwiftUI

struct AdaptivePlayerScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var viewModel: PlayerViewModel
    let onShowAlbum: () -> Void

    init(viewModel: PlayerViewModel, onShowAlbum: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onShowAlbum = onShowAlbum
    }

    var body: some View {
        Group {
            if DeviceLayout.isRegularWidth(horizontalSizeClass) {
                iPadPlayerScreen(viewModel: viewModel, onShowAlbum: onShowAlbum)
            } else {
                PlayerScreen(viewModel: viewModel, onShowAlbum: onShowAlbum)
            }
        }
    }
}

struct AdaptiveAlbumScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State var viewModel: AlbumViewModel

    var body: some View {
        Group {
            if DeviceLayout.isRegularWidth(horizontalSizeClass) {
                iPadAlbumScreen(viewModel: viewModel)
            } else {
                AlbumScreen(viewModel: viewModel)
            }
        }
    }
}

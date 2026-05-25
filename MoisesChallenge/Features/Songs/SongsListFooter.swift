import SwiftUI

struct SongsListFooter: View {
    let state: SongsViewState
    let hasMorePages: Bool
    let songsEmpty: Bool
    let recentlyPlayedEmpty: Bool
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .idle:
            if recentlyPlayedEmpty && songsEmpty {
                ContentUnavailableView(
                    "Ready when you are",
                    systemImage: "magnifyingglass",
                    description: Text("Search for an artist or song to begin.")
                )
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.top, 36)
            }
        case .loading, .refreshing:
            ProgressView("Loading songs")
                .tint(AppTheme.accent)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.top, 32)
        case .loadingMore:
            HStack {
                Spacer()
                ProgressView().tint(AppTheme.accent).padding(.vertical, 20)
                Spacer()
            }
        case .empty:
            ContentUnavailableView(
                "No songs found",
                systemImage: "music.note.list",
                description: Text("Try a different search term.")
            )
            .foregroundStyle(AppTheme.textSecondary)
            .padding(.top, 36)
        case .error(let message):
            VStack(spacing: 12) {
                ContentUnavailableView(
                    "Something went wrong",
                    systemImage: "wifi.exclamationmark",
                    description: Text(message)
                )
                Button("Try again", action: onRetry)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 20)
            }
            .padding(.top, 36)
        case .loaded:
            if !hasMorePages && !songsEmpty {
                Text("End of results")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct AdaptiveSongsScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var viewModel: SongsViewModel
    let onSelectSong: (Song) -> Void
    let onShowAlbum: (Song) -> Void

    init(
        viewModel: SongsViewModel,
        onSelectSong: @escaping (Song) -> Void,
        onShowAlbum: @escaping (Song) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectSong = onSelectSong
        self.onShowAlbum = onShowAlbum
    }

    var body: some View {
        Group {
            if DeviceLayout.isRegularWidth(horizontalSizeClass) {
                iPadSongsScreen(
                    viewModel: viewModel,
                    onSelectSong: onSelectSong,
                    onShowAlbum: onShowAlbum
                )
            } else {
                SongsScreen(
                    viewModel: viewModel,
                    onSelectSong: onSelectSong,
                    onShowAlbum: onShowAlbum
                )
            }
        }
    }
}

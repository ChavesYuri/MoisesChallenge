import SwiftUI

struct iPadAlbumScreen: View {
    @State var viewModel: AlbumViewModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    trackList
                    footer
                }
                .padding(32)
            }
        }
        .navigationTitle(viewModel.seedSong.collectionName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 28) {
            SongArtworkView(
                url: viewModel.seedSong.artworkURL600 ?? viewModel.seedSong.artworkURL100,
                size: 220
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.seedSong.collectionName)
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(viewModel.seedSong.artistName)
                    .font(.title2)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
    }

    private var trackList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(viewModel.songs.enumerated()), id: \.element.id) { index, song in
                HStack(spacing: 16) {
                    SongArtworkView(url: song.artworkURL100, size: 48)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.trackName)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(1)
                        Text(song.artistName)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "ellipsis")
                        .foregroundStyle(AppTheme.textSecondary)
                        .accessibilityHidden(true)
                }
                .padding(.vertical, 12)
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading album")
                .tint(AppTheme.accent)
                .foregroundStyle(AppTheme.textSecondary)
        case .loaded, .empty, .error:
            EmptyView()
        }
    }
}

import SwiftUI

struct AlbumScreen: View {
    @State var viewModel: AlbumViewModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 14) {
                    header

                    ForEach(viewModel.songs) { song in
                        SongRowView(song: song)
                    }

                    footer
                }
                .padding()
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            SongArtworkView(url: viewModel.seedSong.artworkURL600 ?? viewModel.seedSong.artworkURL100, size: 190)
            VStack(spacing: 5) {
                Text(viewModel.seedSong.collectionName)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                Text(viewModel.seedSong.artistName)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var footer: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Loading album")
                .tint(AppTheme.accent)
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.top, 24)
        case .loaded:
            EmptyView()
        case .empty:
            ContentUnavailableView("No album tracks", systemImage: "rectangle.stack.badge.person.crop", description: Text("The API did not return tracks for this album."))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.top, 24)
        case .error(let message):
            ContentUnavailableView("Could not load album", systemImage: "wifi.exclamationmark", description: Text(message))
                .foregroundStyle(AppTheme.textSecondary)
                .padding(.top, 24)
        }
    }
}

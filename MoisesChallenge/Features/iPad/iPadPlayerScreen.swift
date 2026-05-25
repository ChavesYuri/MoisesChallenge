import SwiftUI

struct iPadPlayerScreen: View {
    @State var viewModel: PlayerViewModel
    @State private var isShowingOptions = false
    @State private var scrubProgress: Double = 0
    let onShowAlbum: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            HStack(alignment: .top, spacing: 0) {
                playerPane
                    .frame(maxWidth: .infinity)

                queuePane
                    .frame(width: 320)
                    .background(Color(white: 0.08))
            }
        }
        .navigationTitle(viewModel.song.collectionName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isShowingOptions = true } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("More options")
            }
        }
        .sheet(isPresented: $isShowingOptions) {
            MoreOptionsSheet(song: viewModel.song) {
                isShowingOptions = false
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(250))
                    onShowAlbum()
                }
            }
        }
        .onAppear { viewModel.appear() }
        .onDisappear { viewModel.disappear() }
        .onChange(of: viewModel.currentTime) { _, newValue in
            guard viewModel.duration > 0 else { return }
            scrubProgress = newValue / viewModel.duration
        }
    }

    private var playerPane: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 24)

            SongArtworkView(
                url: viewModel.song.artworkURL600 ?? viewModel.song.artworkURL100,
                size: 340
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 24, y: 12)

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.song.trackName)
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(viewModel.song.artistName)
                    .font(.title3)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)

            PlayerProgressView(
                progress: $scrubProgress,
                currentTimeText: viewModel.currentTimeText,
                remainingTimeText: viewModel.remainingTimeText,
                onScrub: viewModel.scrub(to:)
            )
            .padding(.horizontal, 40)

            PlayerControlsView(
                isPlaying: viewModel.isPlaying,
                onTogglePlayback: viewModel.togglePlayback,
                onSeekBackward: viewModel.seekBackward,
                onSeekForward: viewModel.seekForward,
                playButtonSize: 80
            )

            if let message = viewModel.message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(AppTheme.warm)
            }

            Spacer()
        }
    }

    private var queuePane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Up Next", systemImage: "list.bullet")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 24)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.queueSongs) { queuedSong in
                        HStack(spacing: 12) {
                            SongArtworkView(url: queuedSong.artworkURL100, size: 44)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(queuedSong.trackName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(
                                        queuedSong.id == viewModel.song.id
                                            ? AppTheme.textPrimary
                                            : AppTheme.textSecondary
                                    )
                                    .lineLimit(1)
                                Text(queuedSong.artistName)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            queuedSong.id == viewModel.song.id
                                ? Color.white.opacity(0.08)
                                : Color.clear
                        )
                    }
                }
            }
        }
    }
}

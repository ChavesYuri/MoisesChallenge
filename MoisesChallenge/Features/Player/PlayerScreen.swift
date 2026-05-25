import SwiftUI

struct PlayerScreen: View {
    @State var viewModel: PlayerViewModel
    @State private var isShowingOptions = false
    @State private var scrubProgress: Double = 0
    let onShowAlbum: () -> Void

    init(viewModel: PlayerViewModel, onShowAlbum: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onShowAlbum = onShowAlbum
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer(minLength: 8)

                SongArtworkView(url: viewModel.song.artworkURL600 ?? viewModel.song.artworkURL100, size: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
                    .padding(.horizontal, 32)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.song.trackName)
                                .font(.title2.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                                .lineLimit(2)

                            Text(viewModel.song.artistName)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "repeat")
                            .font(.title3)
                            .foregroundStyle(AppTheme.textPrimary)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, 24)

                PlayerProgressView(
                    progress: $scrubProgress,
                    currentTimeText: viewModel.currentTimeText,
                    remainingTimeText: viewModel.remainingTimeText,
                    onScrub: viewModel.scrub(to:)
                )
                .padding(.horizontal, 24)

                PlayerControlsView(
                    isPlaying: viewModel.isPlaying,
                    onTogglePlayback: viewModel.togglePlayback,
                    onSeekBackward: viewModel.seekBackward,
                    onSeekForward: viewModel.seekForward
                )
                .padding(.top, 8)

                if let message = viewModel.message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(AppTheme.warm)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
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
}

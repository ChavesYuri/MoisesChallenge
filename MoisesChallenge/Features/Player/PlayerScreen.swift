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

                progressSection
                playbackControls

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
                Button {
                    isShowingOptions = true
                } label: {
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
        .onAppear {
            viewModel.appear()
        }
        .onDisappear {
            viewModel.disappear()
        }
        .onChange(of: viewModel.currentTime) { _, newValue in
            guard viewModel.duration > 0 else { return }
            scrubProgress = newValue / viewModel.duration
        }
    }

    private var progressSection: some View {
        VStack(spacing: 6) {
            Slider(value: Binding(
                get: { scrubProgress },
                set: { newValue in
                    scrubProgress = newValue
                    viewModel.scrub(to: newValue)
                }
            ))
            .tint(.white)

            HStack {
                Text(viewModel.currentTimeText)
                Spacer()
                Text(viewModel.remainingTimeText)
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 24)
    }

    private var playbackControls: some View {
        HStack(spacing: 48) {
            Button {
                viewModel.seekBackward()
            } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 28, weight: .semibold))
            }
            .accessibilityLabel("Go backward 15 seconds")

            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 72, height: 72)
                    .background(Color(white: 0.2), in: Circle())
            }
            .accessibilityLabel(viewModel.isPlaying ? "Pause preview" : "Play preview")

            Button {
                viewModel.seekForward()
            } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 28, weight: .semibold))
            }
            .accessibilityLabel("Go forward 15 seconds")
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.textPrimary)
        .padding(.top, 8)
    }
}

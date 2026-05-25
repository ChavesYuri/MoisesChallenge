import SwiftUI

struct WatchPlayerView: View {
    let song: WatchSong
    @State private var isPlaying = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0, green: 0.52, blue: 0.63), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {
                WatchArtworkView(url: song.artworkURL, size: 92)

                VStack(spacing: 4) {
                    Text(song.trackName)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    Text(song.artistName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 28) {
                    Button { /* previous track placeholder */ } label: {
                        Image(systemName: "backward.fill")
                    }
                    Button { isPlaying.toggle() } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .frame(width: 52, height: 52)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Button { /* next track placeholder */ } label: {
                        Image(systemName: "forward.fill")
                    }
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle(song.collectionName)
    }
}

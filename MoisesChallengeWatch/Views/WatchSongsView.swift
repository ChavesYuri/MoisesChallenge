import SwiftUI

struct WatchSongsView: View {
    @Bindable var store: WatchLibraryStore

    var body: some View {
        List(store.recentlyPlayed) { song in
            NavigationLink(value: song) {
                WatchSongRow(song: song)
            }
        }
        .navigationTitle("Songs")
        .overlay {
            if store.recentlyPlayed.isEmpty {
                ContentUnavailableView(
                    "No Songs",
                    systemImage: "music.note.list",
                    description: Text("Play songs on iPhone")
                )
            }
        }
    }
}

struct WatchSongRow: View {
    let song: WatchSong

    var body: some View {
        HStack(spacing: 10) {
            WatchArtworkView(url: song.artworkURL)
            VStack(alignment: .leading, spacing: 2) {
                Text(song.trackName)
                    .font(.headline)
                    .lineLimit(1)
                Text(song.artistName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

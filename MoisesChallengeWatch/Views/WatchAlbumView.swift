import SwiftUI

struct WatchAlbumView: View {
    let seedSong: WatchSong
    let tracks: [WatchSong]
    let onSelect: (WatchSong) -> Void

    var body: some View {
        List(tracks) { song in
            Button { onSelect(song) } label: {
                WatchSongRow(song: song)
            }
            .buttonStyle(.plain)
        }
        .navigationTitle(seedSong.collectionName)
    }
}

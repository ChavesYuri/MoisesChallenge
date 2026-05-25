import SwiftUI

struct SongRowView: View {
    let song: Song

    var body: some View {
        HStack(spacing: 14) {
            SongArtworkView(url: song.artworkURL100, size: 56)

            VStack(alignment: .leading, spacing: 5) {
                Text(song.trackName)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                Text(song.artistName)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(song.trackName), \(song.artistName)")
    }
}

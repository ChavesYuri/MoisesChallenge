import SwiftUI

struct MoreOptionsSheet: View {
    let song: Song
    let onShowAlbum: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 42, height: 5)
                .padding(.top, 8)

            HStack(spacing: 14) {
                SongArtworkView(url: song.artworkURL100, size: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.trackName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(song.artistName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }

            VStack(spacing: 10) {
                Button {
                    dismiss()
                    onShowAlbum()
                } label: {
                    optionLabel(title: "View album", systemImage: "rectangle.stack.fill")
                }
                .disabled(song.collectionId == nil)

                if let previewURL = song.previewURL {
                    ShareLink(item: previewURL) {
                        optionLabel(title: "Share preview", systemImage: "square.and.arrow.up")
                    }
                }

                Button(role: .cancel) {
                    dismiss()
                } label: {
                    optionLabel(title: "Close", systemImage: "xmark")
                }
            }
        }
        .padding(20)
        .presentationDetents([.height(280), .medium])
        .presentationDragIndicator(.hidden)
    }

    private func optionLabel(title: String, systemImage: String) -> some View {
        HStack {
            Image(systemName: systemImage)
                .frame(width: 28)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .foregroundStyle(.primary)
        .padding()
        .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

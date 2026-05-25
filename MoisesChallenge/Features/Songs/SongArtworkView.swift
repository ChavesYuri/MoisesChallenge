import SwiftUI

struct SongArtworkView: View {
    let url: URL?
    var size: CGFloat = 64

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                placeholder
            case .empty:
                ProgressView()
                    .tint(AppTheme.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.elevated)
            @unknown default:
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            AppTheme.elevated
            Image(systemName: "music.note")
                .font(.title2)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

import SwiftUI

struct WatchArtworkView: View {
    let url: URL?
    var size: CGFloat = 44

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            default:
                Color.gray.opacity(0.3)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.18))
    }
}

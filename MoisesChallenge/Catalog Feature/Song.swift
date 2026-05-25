import Foundation

struct Song: Identifiable, Hashable, Sendable {
    let id: Int
    let trackName: String
    let artistName: String
    let collectionName: String
    let artworkURL100: URL?
    let previewURL: URL?
    let trackPrice: Double?
    let currency: String?
    let primaryGenreName: String?
    let releaseDate: Date?
    let trackTimeMillis: Int?
    let collectionId: Int?

    var artworkURL600: URL? {
        guard let artworkURL100 else { return nil }
        return URL(string: artworkURL100.absoluteString.replacingOccurrences(of: "100x100", with: "600x600"))
    }

    var durationSeconds: Double {
        guard let trackTimeMillis else { return 0 }
        return Double(max(trackTimeMillis, 0)) / 1000
    }

    var durationText: String {
        Self.formatTime(durationSeconds)
    }

    static func formatTime(_ seconds: Double) -> String {
        let total = max(Int(seconds), 0)
        return "\(total / 60):\(String(format: "%02d", total % 60))"
    }

    var priceText: String {
        guard let trackPrice, let currency else { return "Preview" }
        return trackPrice == 0 ? "Free" : "\(currency) \(String(format: "%.2f", trackPrice))"
    }
}

extension Song {
    static let preview = Song(
        id: 1,
        trackName: "Get Lucky",
        artistName: "Daft Punk feat. Pharrell Williams",
        collectionName: "Random Access Memories",
        artworkURL100: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/8a/00/00/8a000000.jpg/100x100bb.jpg"),
        previewURL: nil,
        trackPrice: 1.29,
        currency: "USD",
        primaryGenreName: "Electronic",
        releaseDate: Date(),
        trackTimeMillis: 248000,
        collectionId: 10
    )
}

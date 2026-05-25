import Foundation

struct WatchSong: Codable, Identifiable, Hashable {
    let id: Int
    let trackName: String
    let artistName: String
    let collectionName: String
    let artworkURLString: String?
    let previewURLString: String?
    let collectionId: Int?

    var artworkURL: URL? { artworkURLString.flatMap(URL.init(string:)) }
    var previewURL: URL? { previewURLString.flatMap(URL.init(string:)) }
}

struct WatchLibraryPayload: Codable {
    let recentlyPlayed: [WatchSong]
    let currentSong: WatchSong?
}

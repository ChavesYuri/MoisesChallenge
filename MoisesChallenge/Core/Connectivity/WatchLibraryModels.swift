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

extension WatchSong {
    init(_ song: Song) {
        id = song.id
        trackName = song.trackName
        artistName = song.artistName
        collectionName = song.collectionName
        artworkURLString = song.artworkURL100?.absoluteString
        previewURLString = song.previewURL?.absoluteString
        collectionId = song.collectionId
    }
}

struct WatchLibraryPayload: Codable {
    let recentlyPlayed: [WatchSong]
    let currentSong: WatchSong?
}

import Foundation
import SwiftData

@Model
final class CachedSong {
    @Attribute(.unique) var id: Int
    var trackName: String
    var artistName: String
    var collectionName: String
    var artworkURLString: String?
    var previewURLString: String?
    var trackPrice: Double?
    var currency: String?
    var primaryGenreName: String?
    var releaseDate: Date?
    var trackTimeMillis: Int?
    var collectionId: Int?
    var lastPlayedAt: Date?
    var cachedAt: Date

    init(song: Song, lastPlayedAt: Date? = nil, cachedAt: Date = Date()) {
        self.id = song.id
        self.trackName = song.trackName
        self.artistName = song.artistName
        self.collectionName = song.collectionName
        self.artworkURLString = song.artworkURL100?.absoluteString
        self.previewURLString = song.previewURL?.absoluteString
        self.trackPrice = song.trackPrice
        self.currency = song.currency
        self.primaryGenreName = song.primaryGenreName
        self.releaseDate = song.releaseDate
        self.trackTimeMillis = song.trackTimeMillis
        self.collectionId = song.collectionId
        self.lastPlayedAt = lastPlayedAt
        self.cachedAt = cachedAt
    }

    func update(with song: Song, lastPlayedAt: Date? = nil) {
        trackName = song.trackName
        artistName = song.artistName
        collectionName = song.collectionName
        artworkURLString = song.artworkURL100?.absoluteString
        previewURLString = song.previewURL?.absoluteString
        trackPrice = song.trackPrice
        currency = song.currency
        primaryGenreName = song.primaryGenreName
        releaseDate = song.releaseDate
        trackTimeMillis = song.trackTimeMillis
        collectionId = song.collectionId
        cachedAt = Date()
        if let lastPlayedAt {
            self.lastPlayedAt = lastPlayedAt
        }
    }

    func toDomain() -> Song {
        Song(
            id: id,
            trackName: trackName,
            artistName: artistName,
            collectionName: collectionName,
            artworkURL100: artworkURLString.flatMap(URL.init(string:)),
            previewURL: previewURLString.flatMap(URL.init(string:)),
            trackPrice: trackPrice,
            currency: currency,
            primaryGenreName: primaryGenreName,
            releaseDate: releaseDate,
            trackTimeMillis: trackTimeMillis,
            collectionId: collectionId
        )
    }
}

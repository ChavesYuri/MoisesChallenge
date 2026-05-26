import Foundation
import Testing
@testable import MoisesChallenge

struct SearchRequest: Equatable {
    let term: String
    let page: Int
    let pageSize: Int
}

@MainActor
final class FakeSongRepository: SongRepository {
    var pages: [Int: [Song]]
    var recent: [Song]
    var albumSongsByCollectionId: [Int: [Song]] = [:]
    var requests: [SearchRequest] = []
    var playedSongs: [Song] = []
    var albumRequests: [Int] = []

    init(pages: [Int: [Song]] = [:], recent: [Song] = []) {
        self.pages = pages
        self.recent = recent
    }

    func searchSongs(term: String, page: Int, pageSize: Int) async throws -> Paginated<Song> {
        requests.append(SearchRequest(term: term, page: page, pageSize: pageSize))
        let items = pages[page] ?? []
        return Paginated(items: items, hasMore: items.count == pageSize)
    }

    func albumSongs(collectionId: Int) async throws -> [Song] {
        albumRequests.append(collectionId)
        if let songs = albumSongsByCollectionId[collectionId] {
            return songs
        }
        return pages.values.flatMap { $0 }.filter { $0.collectionId == collectionId }
    }

    func recentlyPlayed(limit: Int) async throws -> [Song] {
        Array(recent.prefix(limit))
    }

    func markPlayed(_ song: Song) async throws {
        playedSongs.append(song)
        recent.insert(song, at: 0)
    }
}

struct FailingSongSearchLoader: SongSearchLoader {
    func search(term: String, limit: Int, offset: Int) async throws -> SongSearchPage {
        throw SongLoaderError.connectivity
    }
}

struct FailingAlbumSongsLoader: AlbumSongsLoader {
    func loadAlbumSongs(collectionId: Int) async throws -> [Song] {
        throw SongLoaderError.connectivity
    }
}

struct StubSongSearchLoader: SongSearchLoader {
    let results: [Song]
    var hasMore: Bool = false

    func search(term: String, limit: Int, offset: Int) async throws -> SongSearchPage {
        SongSearchPage(items: results, hasMore: hasMore)
    }
}

struct StubAlbumSongsLoader: AlbumSongsLoader {
    let songs: [Song]

    func loadAlbumSongs(collectionId: Int) async throws -> [Song] {
        songs
    }
}

@MainActor
final class FakeSongCache: SongCache {
    var stored: [Song] = []
    var saved: [Song] = []
    var recentlyPlayedSongs: [Song] = []
    var markedPlayed: [Song] = []

    func save(_ songs: [Song]) async throws {
        saved = songs
        stored.append(contentsOf: songs)
    }

    func songs(matching term: String, limit: Int, offset: Int) async throws -> [Song] {
        let normalized = term.normalizedCacheSearchTerm
        let filtered = stored.filter { song in
            normalized.isEmpty ||
            song.trackName.localizedCaseInsensitiveContains(normalized) ||
            song.artistName.localizedCaseInsensitiveContains(normalized) ||
            song.collectionName.localizedCaseInsensitiveContains(normalized)
        }
        guard offset < filtered.count else { return [] }
        return Array(filtered.dropFirst(offset).prefix(limit))
    }

    func recentlyPlayed(limit: Int) async throws -> [Song] {
        Array(recentlyPlayedSongs.prefix(limit))
    }

    func markPlayed(_ song: Song) async throws {
        markedPlayed.append(song)
    }
}

@MainActor
final class FakeWatchLibraryPublisher: WatchLibraryPublisher {
    var activated = false
    var publishedPayloads: [(recentlyPlayed: [Song], currentSong: Song?)] = []

    func activate() {
        activated = true
    }

    func publish(recentlyPlayed: [Song], currentSong: Song?) {
        publishedPayloads.append((recentlyPlayed, currentSong))
    }
}

@MainActor
final class FakeAudioPlayer: AudioPlayerService {
    var isPlaying = false
    var currentTime: Double = 0
    var duration: Double = 30
    var onTimeUpdate: ((Double, Double) -> Void)?
    var playedURL: URL?
    var seekTarget: Double?
    var seekDelta: Double?

    func play(url: URL) {
        playedURL = url
        isPlaying = true
    }

    func togglePlayback() {
        isPlaying.toggle()
    }

    func seek(to seconds: Double) {
        seekTarget = seconds
        currentTime = seconds
    }

    func seek(by seconds: Double) {
        seekDelta = seconds
        currentTime += seconds
    }

    func stop() {
        isPlaying = false
        playedURL = nil
    }
}

@MainActor
final class FakeNowPlayingManager: NowPlayingManaging {
    struct UpdateCall: Equatable {
        let songID: Int
        let currentTime: TimeInterval
        let duration: TimeInterval
        let isPlaying: Bool
    }

    var updates: [UpdateCall] = []
    var cleared = false
    var configuredRemoteCommands = false

    func update(song: Song, currentTime: TimeInterval, duration: TimeInterval, isPlaying: Bool) {
        updates.append(UpdateCall(
            songID: song.id,
            currentTime: currentTime,
            duration: duration,
            isPlaying: isPlaying
        ))
    }

    func configureRemoteCommands(
        onPlay: @escaping () -> Void,
        onPause: @escaping () -> Void,
        onSkipForward: @escaping () -> Void,
        onSkipBackward: @escaping () -> Void
    ) {
        configuredRemoteCommands = true
    }

    func clear() {
        cleared = true
    }
}

final class StubHTTPClient: HTTPClient, @unchecked Sendable {
    enum Behavior {
        case success(Data, HTTPURLResponse)
        case failure(Error)
    }

    let behavior: Behavior
    var requestedURLs: [URL] = []

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        requestedURLs.append(url)
        switch behavior {
        case .success(let data, let response):
            return (data, response)
        case .failure(let error):
            throw error
        }
    }
}

extension Song {
    static func fixture(
        id: Int,
        name: String,
        collectionId: Int = 100,
        previewURL: URL? = nil,
        includesPreview: Bool = true
    ) -> Song {
        Song(
            id: id,
            trackName: name,
            artistName: "Artist \(id)",
            collectionName: "Album",
            artworkURL100: URL(string: "https://is1-ssl.mzstatic.com/image/thumb/100x100bb.jpg"),
            previewURL: includesPreview ? (previewURL ?? URL(string: "https://audio.example.com/\(id).m4a")) : previewURL,
            trackPrice: nil,
            currency: nil,
            primaryGenreName: "Pop",
            releaseDate: nil,
            trackTimeMillis: 180000,
            collectionId: collectionId
        )
    }
}

enum TestJSON {
    static let validSearchResponse = """
    {
      "resultCount": 1,
      "results": [{
        "trackId": 42,
        "trackName": "One More Time",
        "artistName": "Daft Punk",
        "collectionName": "Discovery",
        "artworkUrl100": "https://is1-ssl.mzstatic.com/image/thumb/100x100bb.jpg",
        "previewUrl": "https://audio-ssl.itunes.apple.com/preview.m4a",
        "trackPrice": 1.29,
        "currency": "USD",
        "primaryGenreName": "Electronic",
        "trackTimeMillis": 320000,
        "collectionId": 200
      }]
    }
    """.data(using: .utf8)!
}

extension HTTPURLResponse {
    static func ok(url: URL = URL(string: "https://itunes.apple.com/search")!) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
}

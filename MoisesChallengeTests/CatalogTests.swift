import Foundation
import Testing
@testable import MoisesChallenge

struct ITunesMapperTests {
    @Test func mapperParsesValidSearchResponse() throws {
        let songs = try ITunesSongMapper.map(TestJSON.validSearchResponse, from: .ok())

        #expect(songs.count == 1)
        #expect(songs[0].id == 42)
        #expect(songs[0].trackName == "One More Time")
        #expect(songs[0].artistName == "Daft Punk")
        #expect(songs[0].collectionId == 200)
    }

    @Test func mapperFiltersIncompleteResults() throws {
        let json = """
        {
          "resultCount": 2,
          "results": [
            { "trackId": 1, "trackName": "Valid", "artistName": "Artist" },
            { "trackName": "Missing ID" }
          ]
        }
        """.data(using: .utf8)!

        let songs = try ITunesSongMapper.map(json, from: .ok())

        #expect(songs.count == 1)
        #expect(songs[0].trackName == "Valid")
    }

    @Test func mapperThrowsForInvalidJSON() {
        #expect(throws: (any Error).self) {
            _ = try ITunesSongMapper.map(Data("not json".utf8), from: .ok())
        }
    }
}

struct ITunesEndpointTests {
    @Test func searchEndpointBuildsExpectedURL() {
        let endpoint = ITunesEndpoint.Search(term: "daft punk", limit: 25)
        let url = endpoint.url()

        #expect(url?.absoluteString.contains("term=daft%20punk") == true)
        #expect(url?.absoluteString.contains("media=music") == true)
        #expect(url?.absoluteString.contains("entity=song") == true)
        #expect(url?.absoluteString.contains("limit=25") == true)
    }

    @Test func albumLookupEndpointBuildsExpectedURL() {
        let endpoint = ITunesEndpoint.AlbumLookup(collectionId: 12345)
        let url = endpoint.url()

        #expect(url?.absoluteString.contains("/lookup") == true)
        #expect(url?.absoluteString.contains("id=12345") == true)
        #expect(url?.absoluteString.contains("entity=song") == true)
    }
}

struct HTTPClientTests {
    @Test func urlSessionClientThrowsForNonHTTPResponse() async {
        final class MockURLProtocol: URLProtocol {
            override class func canInit(with request: URLRequest) -> Bool { true }
            override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
            override func startLoading() {
                client?.urlProtocol(self, didReceive: URLResponse(), cacheStoragePolicy: .notAllowed)
                client?.urlProtocolDidFinishLoading(self)
            }
            override func stopLoading() {}
        }

        var config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let client = URLSessionHTTPClient(session: URLSession(configuration: config))

        await #expect(throws: NetworkError.invalidResponse) {
            _ = try await client.get(from: URL(string: "https://example.com")!)
        }
    }
}

struct SongFormattingTests {
    @Test func formatTimePadsSeconds() {
        #expect(Song.formatTime(65) == "1:05")
        #expect(Song.formatTime(0) == "0:00")
    }

    @Test func durationSecondsUsesTrackTimeMillis() {
        let song = Song.fixture(id: 1, name: "Timed")
        #expect(song.durationSeconds == 180)
    }

    @Test func artworkURL600ReplacesThumbnailSize() {
        let song = Song(
            id: 1,
            trackName: "Art",
            artistName: "Artist",
            collectionName: "Album",
            artworkURL100: URL(string: "https://example.com/100x100bb.jpg"),
            previewURL: nil,
            trackPrice: nil,
            currency: nil,
            primaryGenreName: nil,
            releaseDate: nil,
            trackTimeMillis: nil,
            collectionId: nil
        )

        #expect(song.artworkURL600?.absoluteString.contains("600x600") == true)
    }
}

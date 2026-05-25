import Foundation

enum ITunesSongMapper {
    enum MappingError: Error {
        case invalidData
        case invalidStatusCode
    }

    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [Song] {
        try mapResponse(data, from: response).songs
    }

    static func mapResponse(_ data: Data, from response: HTTPURLResponse) throws -> (songs: [Song], fetchedCount: Int) {
        guard response.isOK else { throw MappingError.invalidStatusCode }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(ITunesSearchResponseDTO.self, from: data)
        let songs = dto.results.compactMap(map)
        guard !songs.isEmpty || dto.results.isEmpty else { throw MappingError.invalidData }
        return (songs, dto.results.count)
    }

    private static func map(_ dto: ITunesSongDTO) -> Song? {
        guard let trackId = dto.trackId, let trackName = dto.trackName, let artistName = dto.artistName else {
            return nil
        }
        return Song(
            id: trackId,
            trackName: trackName,
            artistName: artistName,
            collectionName: dto.collectionName ?? "Single",
            artworkURL100: dto.artworkUrl100,
            previewURL: dto.previewUrl,
            trackPrice: dto.trackPrice,
            currency: dto.currency,
            primaryGenreName: dto.primaryGenreName,
            releaseDate: dto.releaseDate,
            trackTimeMillis: dto.trackTimeMillis,
            collectionId: dto.collectionId
        )
    }
}

private extension HTTPURLResponse {
    var isOK: Bool { (200...299).contains(statusCode) }
}

struct ITunesSearchResponseDTO: Decodable, Sendable {
    let resultCount: Int
    let results: [ITunesSongDTO]
}

struct ITunesSongDTO: Decodable, Sendable {
    let trackId: Int?
    let trackName: String?
    let artistName: String?
    let collectionName: String?
    let artworkUrl100: URL?
    let previewUrl: URL?
    let trackPrice: Double?
    let currency: String?
    let primaryGenreName: String?
    let releaseDate: Date?
    let trackTimeMillis: Int?
    let collectionId: Int?
}

import Foundation

struct RemoteSongSearchLoader: SongSearchLoader {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func search(term: String, limit: Int, offset: Int) async throws -> SongSearchPage {
        let cumulativeLimit = min(offset + limit, ITunesSearchLimits.maxResults)
        let endpoint = ITunesEndpoint.Search(term: term, limit: cumulativeLimit)
        guard let url = endpoint.url() else { throw SongLoaderError.invalidData }
        do {
            let (data, response) = try await client.get(from: url)
            let (allSongs, fetchedCount) = try ITunesSongMapper.mapResponse(data, from: response)
            return ITunesSearchPaginator.page(
                from: allSongs,
                fetchedCount: fetchedCount,
                requestedLimit: cumulativeLimit,
                pageLimit: limit,
                offset: offset
            )
        } catch is SongLoaderError {
            throw SongLoaderError.invalidData
        } catch {
            throw SongLoaderError.connectivity
        }
    }
}

struct RemoteAlbumSongsLoader: AlbumSongsLoader {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func loadAlbumSongs(collectionId: Int) async throws -> [Song] {
        let endpoint = ITunesEndpoint.AlbumLookup(collectionId: collectionId)
        guard let url = endpoint.url() else { throw SongLoaderError.invalidData }
        do {
            let (data, response) = try await client.get(from: url)
            return try ITunesSongMapper.map(data, from: response)
        } catch is SongLoaderError {
            throw SongLoaderError.invalidData
        } catch {
            throw SongLoaderError.connectivity
        }
    }
}

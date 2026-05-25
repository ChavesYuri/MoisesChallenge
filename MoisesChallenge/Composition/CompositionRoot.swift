import Foundation
import SwiftData

@MainActor
final class CompositionRoot {
    let modelContainer: ModelContainer
    let repository: SongRepository

    init(httpClient: HTTPClient = URLSessionHTTPClient()) {
        do {
            modelContainer = try ModelContainer(for: CachedSong.self)
        } catch {
            fatalError("Failed to create SwiftData model container: \(error)")
        }

        let context = ModelContext(modelContainer)
        let cache = LocalSongCacheLoader(context: context)
        let remoteSearch = RemoteSongSearchLoader(client: httpClient)
        let remoteAlbum = RemoteAlbumSongsLoader(client: httpClient)

        repository = MainSongRepository(
            remoteSearch: remoteSearch,
            remoteAlbum: remoteAlbum,
            cache: cache
        )
    }
}

import Foundation
import SwiftData

@MainActor
final class CompositionRoot {
    let modelContainer: ModelContainer
    let repository: SongRepository
    let playback: AudioPlayerService
    let watchSync: WatchLibraryPublisher
    let nowPlaying: NowPlayingManaging

    init(
        httpClient: HTTPClient = URLSessionHTTPClient(),
        playback: AudioPlayerService? = nil,
        watchSync: WatchLibraryPublisher? = nil,
        nowPlaying: NowPlayingManaging? = nil
    ) {
        do {
            modelContainer = try ModelContainer(for: CachedSong.self)
        } catch {
            fatalError("Failed to create SwiftData model container: \(error)")
        }

        let context = ModelContext(modelContainer)
        let cache = LocalSongCacheLoader(context: context)
        let remoteSearch = RemoteSongSearchLoader(client: httpClient)
        let remoteSongSearchLoaderCacheDecorator = SongSearchLoaderCacheDecorator(decoratee: remoteSearch, cache: cache)
        let remoteAlbum = RemoteAlbumSongsLoader(client: httpClient)

        repository = MainSongRepository(
            remoteSearch: remoteSongSearchLoaderCacheDecorator,
            remoteAlbum: remoteAlbum,
            cache: cache
        )
        self.playback = playback ?? SharedPlaybackService()
        self.watchSync = watchSync ?? WatchConnectivityService()
        self.nowPlaying = nowPlaying ?? NowPlayingManager(httpClient: httpClient)
    }
}

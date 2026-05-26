import Foundation
import Observation

enum AlbumViewState: Equatable {
    case loading
    case loaded
    case empty
    case error(String)
}

@MainActor
@Observable
final class AlbumViewModel {
    let seedSong: Song
    private(set) var songs: [Song] = []
    private(set) var state: AlbumViewState = .loading

    private let repository: SongRepository

    init(seedSong: Song, repository: SongRepository) {
        self.seedSong = seedSong
        self.repository = repository
    }

    func load() async {
        guard seedSong.collectionId != nil else {
            songs = [seedSong]
            state = .loaded
            return
        }

        do {
            songs = try await AlbumSongsQuery.songs(for: seedSong, repository: repository)
            state = songs.isEmpty ? .empty : .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

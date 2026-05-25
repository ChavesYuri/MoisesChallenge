import Foundation
import Observation

enum SongsViewState: Equatable {
    case idle
    case loading
    case loadingMore
    case refreshing
    case loaded
    case empty
    case error(String)
}

@MainActor
@Observable
final class SongsViewModel {
    var searchText = ""
    private(set) var songs: [Song] = []
    private(set) var recentlyPlayed: [Song] = []
    private(set) var state: SongsViewState = .idle
    private(set) var hasMorePages = true

    private let repository: SongRepository
    private let pageSize: Int
    private var currentPage = 0
    private var currentTerm = ""

    init(repository: SongRepository, pageSize: Int = 20) {
        self.repository = repository
        self.pageSize = pageSize
    }

    func onAppear() async {
        await loadRecentlyPlayed()
    }

    func submitSearch() async {
        let term = normalizedSearchText
        guard !term.isEmpty else {
            songs = []
            state = .idle
            hasMorePages = true
            return
        }

        currentTerm = term
        currentPage = 0
        hasMorePages = true
        songs = []
        state = .loading
        await loadPage(reset: true)
    }

    func refresh() async {
        guard !currentTerm.isEmpty else {
            await loadRecentlyPlayed()
            return
        }
        currentPage = 0
        hasMorePages = true
        state = .refreshing
        await loadPage(reset: true)
    }

    func loadMoreIfNeeded(currentSong: Song) async {
        guard hasMorePages, songs.last == currentSong, state != .loadingMore else { return }
        state = .loadingMore
        currentPage += 1
        await loadPage(reset: false)
    }

    func markPlayed(_ song: Song) {
        Task {
            try? await repository.markPlayed(song)
            await loadRecentlyPlayed()
            let recent = (try? await repository.recentlyPlayed(limit: 12)) ?? []
            WatchConnectivityService.shared.publish(recentlyPlayed: recent, currentSong: song)
        }
    }

    private func loadRecentlyPlayed() async {
        recentlyPlayed = (try? await repository.recentlyPlayed(limit: 10)) ?? []
    }

    private func loadPage(reset: Bool) async {
        do {
            let page = try await repository.searchSongs(term: currentTerm, page: currentPage, pageSize: pageSize)
            if reset {
                songs = page.items
                hasMorePages = page.hasMore
            } else {
                let updated = appendUnique(page.items)
                let didAppendNewItems = updated.count > songs.count
                songs = updated
                hasMorePages = page.hasMore && didAppendNewItems
            }
            state = songs.isEmpty ? .empty : .loaded
        } catch {
            state = .error(error.localizedDescription)
            if reset {
                songs = []
            } else {
                currentPage = max(currentPage - 1, 0)
            }
        }
    }

    private func appendUnique(_ newSongs: [Song]) -> [Song] {
        let existingIDs = Set(songs.map(\.id))
        return songs + newSongs.filter { !existingIDs.contains($0.id) }
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

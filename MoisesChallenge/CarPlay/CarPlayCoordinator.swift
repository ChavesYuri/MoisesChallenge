import CarPlay
import UIKit

@MainActor
final class CarPlayCoordinator {
    private let interfaceController: CPInterfaceController
    private let repository: SongRepository
    private let playback: AudioPlayerService
    private let nowPlaying: NowPlayingManaging

    init(
        interfaceController: CPInterfaceController,
        repository: SongRepository,
        playback: AudioPlayerService,
        nowPlaying: NowPlayingManaging
    ) {
        self.interfaceController = interfaceController
        self.repository = repository
        self.playback = playback
        self.nowPlaying = nowPlaying
    }

    func start() async {
        let root = await makeRootTemplate()
        interfaceController.setRootTemplate(root, animated: true, completion: nil)
    }

    private func makeRootTemplate() async -> CPListTemplate {
        var sections: [CPListSection] = []

        let recent = (try? await repository.recentlyPlayed(limit: 12)) ?? []
        if !recent.isEmpty {
            sections.append(
                CPListSection(
                    items: recent.map { makeSongItem($0) },
                    header: "Recently Played",
                    sectionIndexTitle: nil
                )
            )
        }

        sections.append(
            CPListSection(
                items: [makeSearchItem()],
                header: "Browse",
                sectionIndexTitle: nil
            )
        )

        let template = CPListTemplate(title: "Songs", sections: sections)
        template.tabTitle = "Library"
        template.tabImage = UIImage(systemName: "music.note.list")
        return template
    }

    private func makeSearchItem() -> CPListItem {
        let item = CPListItem(text: "Search Songs", detailText: "Find music in iTunes")
        item.handler = { [weak self] _, completion in
            self?.presentSearch()
            completion()
        }
        return item
    }

    private func makeSongItem(_ song: Song) -> CPListItem {
        let item = CPListItem(text: song.trackName, detailText: song.artistName)
        item.handler = { [weak self] _, completion in
            self?.presentNowPlaying(for: song)
            completion()
        }
        return item
    }

    private func presentSearch() {
        let template = CPSearchTemplate()
        template.delegate = SearchDelegate(coordinator: self)
        interfaceController.pushTemplate(template, animated: true, completion: nil)
    }

    func showResults(for term: String) async {
        let page = (try? await repository.searchSongs(term: term, page: 0, pageSize: 25))
        let songs = page?.items ?? []
        let items = songs.map { makeSongItem($0) }
        let section = CPListSection(items: items, header: "Results", sectionIndexTitle: nil)
        let list = CPListTemplate(title: "Search", sections: [section])
        interfaceController.pushTemplate(list, animated: true, completion: nil)
    }

    private func presentNowPlaying(for song: Song) {
        guard let url = song.previewURL else { return }
        playback.play(url: url)

        nowPlaying.update(
            song: song,
            currentTime: 0,
            duration: song.durationSeconds,
            isPlaying: true
        )

        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        interfaceController.pushTemplate(nowPlayingTemplate, animated: true, completion: nil)

        Task { try? await repository.markPlayed(song) }
    }
}

@MainActor
private final class SearchDelegate: NSObject, CPSearchTemplateDelegate {
    private weak var coordinator: CarPlayCoordinator?

    init(coordinator: CarPlayCoordinator) {
        self.coordinator = coordinator
    }

    func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        updatedSearchText searchText: String,
        completionHandler: @escaping ([CPListItem]) -> Void
    ) {
        let term = searchText.normalizedSearchTerm
        guard !term.isEmpty else {
            completionHandler([])
            return
        }
        Task { @MainActor in
            await coordinator?.showResults(for: term)
            completionHandler([])
        }
    }

    func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        selectedResult item: CPListItem,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

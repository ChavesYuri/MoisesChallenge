import Foundation

@MainActor
protocol WatchLibraryPublisher: AnyObject {
    func activate()
    func publish(recentlyPlayed: [Song], currentSong: Song?)
}

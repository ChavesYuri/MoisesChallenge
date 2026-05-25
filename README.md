# Moises Music Challenge

iOS music search app built with **Swift 6**, **SwiftUI**, **MVVM**, **Swift concurrency**, **SwiftData**, and a replaceable network layer. Architecture follows the layering patterns used in [EssentialFeed](https://github.com/essentialdeveloper/EssentialFeed) and [EssentialApp](https://github.com/essentialdeveloper/EssentialApp).

## Screens

- **Splash** — gradient `#0086A0` → `#000000` with centered note artwork
- **Songs (Home)** — search, paginated iTunes results, recently played, pull-to-refresh
- **Song Details (Player)** — preview playback, ±15s seek, scrubber, album title in navigation bar
- **More options sheet** — view album (from list or player)
- **Album** — album artwork header and track list

## Architecture

```
MoisesChallenge/
├── Catalog Feature/     # Domain models & loader protocols (Song, SongSearchLoader, SongCache)
├── Catalog API/         # Remote loaders, endpoints, mappers, HTTPClient
├── Catalog Cache/       # SwiftData store & LocalSongCacheLoader
├── Shared API/          # Paginated, HTTP abstractions
├── Composition/         # Decorators, composites, CompositionRoot, MainSongRepository
├── UI/
│   ├── Navigation/      # AppView + NavigationStack routes
│   └── Composers/       # SongsUIComposer, PlayerUIComposer
├── Features/            # SwiftUI screens + ViewModels (MVVM)
└── Core/                # Design system, audio playback
```

### Offline-first

1. Remote search/album loads are wrapped with `SongSearchLoaderCacheDecorator`.
2. On network failure, `SongSearchLoaderWithFallbackComposite` serves SwiftData cache.
3. Recently played tracks are shown on the home screen when idle.

### Replaceable API

Swap `HTTPClient` or remote loaders in `CompositionRoot` without touching UI or ViewModels.

## Requirements

- Xcode 16+
- iOS 17+ (project targets latest SDK)

## Run

Open `MoisesChallenge.xcodeproj`, select the **MoisesChallenge** scheme, and run on a simulator or device.

## Tests

```bash
xcodebuild test -project MoisesChallenge.xcodeproj -scheme MoisesChallenge -destination 'platform=iOS Simulator,name=iPhone 16'
```

Tests cover pagination, cache fallback, cache decorator, recently played, and mapper validation.

## API

Uses the public [iTunes Search API](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/Searching.html).

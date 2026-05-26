# Moises Music Challenge

iOS music search app built with **Swift 6**, **SwiftUI**, **MVVM**, **Swift concurrency**, **SwiftData**, and a replaceable network layer.

## Platforms

| Platform | Layout | Location |
|----------|--------|----------|
| **iPhone** | Phone-first navigation stack | `Features/Songs`, `Features/Player`, `Features/Album` |
| **iPad** | Adaptive wide layouts (player + queue, album header, song grid) | `Features/iPad/` |
| **CarPlay** | List templates + Now Playing | `CarPlay/` |
| **Apple Watch** | Companion app synced via WatchConnectivity | `MoisesChallengeWatch/` |

Adaptive layouts activate when `horizontalSizeClass == .regular` (iPad landscape/portrait).

## Screens

- **Splash** — gradient `#0086A0` → `#000000`
- **Songs** — search, pagination, recently played, pull-to-refresh
- **Player** — preview playback, scrubber, ±15s seek; iPad adds **Up Next** queue
- **Album** — track list; iPad uses horizontal album header
- **More options sheet** — view album, share preview

## Architecture

```
MoisesChallenge/
├── Catalog Feature/     # Domain models & loader protocols
├── Catalog API/         # Remote loaders, endpoints, mappers
├── Catalog Cache/       # SwiftData store
├── Shared API/          # Paginated, HTTPClient
├── Composition/         # CompositionRoot, MainSongRepository
├── CarPlay/             # CarPlay scene + coordinator
├── Core/                # Theme, playback, WatchConnectivity
├── Features/            # SwiftUI + ViewModels
├── Features/iPad/       # iPad-specific layouts
└── UI/                  # Navigation + composers

MoisesChallengeWatch/    # watchOS companion (recently played + player UI)
```

## CarPlay setup

CarPlay code is included under `CarPlay/`. To run on a CarPlay simulator or device:

1. Request the **CarPlay Audio** entitlement from Apple.
2. Set `CODE_SIGN_ENTITLEMENTS` to `Config/MoisesChallenge-CarPlay.entitlements` on the iOS target.
3. Run with **I/O → External Displays → CarPlay** in Simulator.

## Apple Watch setup

1. Install the **watchOS 26.x** simulator runtime in Xcode.
2. In Xcode, add an **Embed Watch Content** build phase on the iOS target pointing to `MoisesChallengeWatch`.
3. Run the iOS app on a paired iPhone simulator; the watch receives recently played songs via WatchConnectivity.

## Run

Open `MoisesChallenge.xcodeproj`, select **MoisesChallenge**, run on iPhone or iPad simulator.

```bash
xcodebuild -project MoisesChallenge.xcodeproj -scheme MoisesChallenge \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Tests

```bash
xcodebuild test -project MoisesChallenge.xcodeproj -scheme MoisesChallenge \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:MoisesChallengeTests
```

## API

Uses the public [iTunes Search API](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/Searching.html) with cumulative-limit pagination (iTunes ignores `offset` for music).

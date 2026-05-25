import SwiftUI

struct SongsScreen: View {
    @State private var isSearchTextFieldVisible = true
    @State private var viewModel: SongsViewModel
    @FocusState private var isSearchFocused
    @State private var optionsSong: Song?

    let onSelectSong: (Song) -> Void
    let onShowAlbum: (Song) -> Void

    init(
        viewModel: SongsViewModel,
        onSelectSong: @escaping (Song) -> Void,
        onShowAlbum: @escaping (Song) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectSong = onSelectSong
        self.onShowAlbum = onShowAlbum
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    searchHeader
                        .id(SongsScrollTarget.searchHeader)

                    if !viewModel.recentlyPlayed.isEmpty && viewModel.songs.isEmpty && viewModel.state == .idle {
                        recentlyPlayedSection
                    }

                    songsSection
                }
            }
            .background(AppTheme.background)
            .refreshable { await viewModel.refresh() }
            .task { await viewModel.onAppear() }
            .toolbar {
                if !isSearchTextFieldVisible {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                scrollProxy.scrollTo(SongsScrollTarget.searchHeader, anchor: .top)
                                isSearchFocused = true
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .accessibilityLabel("Scroll to search")
                    }
                }
            }
            .navigationTitle("Songs")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $optionsSong) { song in
            MoreOptionsSheet(song: song) {
                optionsSong = nil
                onShowAlbum(song)
            }
        }
    }

    private var searchHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityHidden(true)

            TextField("Search", text: $viewModel.searchText)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(AppTheme.textPrimary)
                .tint(AppTheme.accent)
                .onSubmit { Task { await viewModel.submitSearch() } }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(white: 0.15), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Search songs")
        .onScrollVisibilityChange { isSearchTextFieldVisible = $0 }
    }

    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recently Played")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 20)
                .padding(.top, 4)

            ForEach(viewModel.recentlyPlayed) { song in
                songRow(song)
            }
        }
        .padding(.bottom, 12)
    }

    private var songsSection: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.songs) { song in
                songRow(song)
                    .task { await viewModel.loadMoreIfNeeded(currentSong: song) }
            }

            SongsListFooter(
                state: viewModel.state,
                hasMorePages: viewModel.hasMorePages,
                songsEmpty: viewModel.songs.isEmpty,
                recentlyPlayedEmpty: viewModel.recentlyPlayed.isEmpty,
                onRetry: { Task { await viewModel.submitSearch() } }
            )
        }
        .padding(.bottom, 24)
    }

    private func songRow(_ song: Song) -> some View {
        HStack(spacing: 0) {
            Button {
                viewModel.markPlayed(song)
                onSelectSong(song)
            } label: {
                SongRowView(song: song)
            }
            .buttonStyle(.plain)

            Button { optionsSong = song } label: {
                Image(systemName: "ellipsis")
                    .font(.footnote.bold())
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More options for \(song.trackName)")
        }
        .padding(.horizontal, 12)
    }
}

private enum SongsScrollTarget {
    static let searchHeader = "songs-search-header"
}

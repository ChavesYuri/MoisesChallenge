import SwiftUI

struct iPadSongsScreen: View {
    @Bindable var viewModel: SongsViewModel
    @FocusState private var isSearchFocused
    @State private var optionsSong: Song?
    @State private var isSearchVisible = true

    let onSelectSong: (Song) -> Void
    let onShowAlbum: (Song) -> Void

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    searchHeader
                        .id(SongsScrollTarget.searchHeader)

                    if !viewModel.recentlyPlayed.isEmpty && viewModel.songs.isEmpty && viewModel.state == .idle {
                        recentlyPlayedSection
                    }

                    songsGrid
                }
            }
            .background(AppTheme.background)
            .refreshable { await viewModel.refresh() }
            .scrollDismissesKeyboard(.immediately)
            .task { await viewModel.onAppear() }
            .toolbar {
                if !isSearchVisible {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation {
                                scrollProxy.scrollTo(SongsScrollTarget.searchHeader, anchor: .top)
                                isSearchFocused = true
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
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
                .foregroundStyle(AppTheme.textSecondary)
            TextField("Search songs...", text: $viewModel.searchText)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .foregroundStyle(AppTheme.textPrimary)
                .onSubmit { Task { await viewModel.submitSearch() } }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Color(white: 0.15), in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .onScrollVisibilityChange { isSearchVisible = $0 }
    }

    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Played")
                .font(.title3.bold())
                .padding(.horizontal, 32)
            LazyVStack(spacing: 0) {
                ForEach(viewModel.recentlyPlayed) { song in
                    songRow(song)
                }
            }
        }
        .padding(.bottom, 24)
    }

    private var songsGrid: some View {
        VStack(spacing: 0) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.songs) { song in
                    songRow(song)
                        .task { await viewModel.loadMoreIfNeeded(currentSong: song) }
                }
            }

            SongsListFooter(
                state: viewModel.state,
                hasMorePages: viewModel.hasMorePages,
                songsEmpty: viewModel.songs.isEmpty,
                recentlyPlayedEmpty: viewModel.recentlyPlayed.isEmpty,
                onRetry: { Task { await viewModel.submitSearch() } }
            )
            .padding(.bottom, 32)
        }
    }

    private func songRow(_ song: Song) -> some View {
        HStack(spacing: 0) {
            Button {
                isSearchFocused = false
                onSelectSong(song)
                viewModel.markPlayed(song)
            } label: {
                SongRowView(song: song)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button { optionsSong = song } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More options for \(song.trackName)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 20)
        .padding(.vertical, 4)
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 32)
        .padding(.vertical, 2)
    }
}

private enum SongsScrollTarget {
    static let searchHeader = "songs-search-header"
}

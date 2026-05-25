import Foundation

/// iTunes Search ignores the `offset` query parameter for music. Pagination is done by
/// requesting a larger cumulative `limit` and slicing the response client-side.
enum ITunesSearchPaginator {
    static func page(
        from allSongs: [Song],
        fetchedCount: Int,
        requestedLimit: Int,
        pageLimit: Int,
        offset: Int
    ) -> SongSearchPage {
        let pageItems = Array(allSongs.dropFirst(offset).prefix(pageLimit))

        // `resultCount` from iTunes is the size of the current response, not total matches.
        // If we received a full cumulative window, more results may exist (up to 200).
        let receivedFullWindow = fetchedCount == requestedLimit
        let belowAPIcap = requestedLimit < ITunesSearchLimits.maxResults
        let hasMore = !pageItems.isEmpty && receivedFullWindow && belowAPIcap

        return SongSearchPage(items: pageItems, hasMore: hasMore)
    }
}

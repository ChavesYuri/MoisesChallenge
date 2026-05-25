import Foundation

struct Paginated<Item: Sendable>: Sendable {
    let items: [Item]
    let hasMore: Bool

    init(items: [Item], hasMore: Bool) {
        self.items = items
        self.hasMore = hasMore
    }
}

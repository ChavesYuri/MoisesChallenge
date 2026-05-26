import Foundation

extension String {
    var normalizedSearchTerm: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedCacheSearchTerm: String {
        normalizedSearchTerm.lowercased()
    }
}

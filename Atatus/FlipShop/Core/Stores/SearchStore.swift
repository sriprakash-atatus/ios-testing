/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Atatus (https://www.atatus.com/).
 * Copyright 2026-Present Atatus, Inc.
 */

import Foundation
import Observation

/// The search screen's query, recent and popular searches, and results.
@MainActor
@Observable
final class SearchStore {
    static let maximumRecentSearches = 10

    var query = ""
    private(set) var recentSearches: [String] = []
    private(set) var popularSearches: [String] = []
    private(set) var results: [Product] = []
    private(set) var resultsState: LoadState = .idle
    /// The query the current results are for.
    private(set) var submittedQuery: String?

    @ObservationIgnored private let service: any SearchServiceProtocol
    @ObservationIgnored private let persistence: PersistenceStore

    init(service: any SearchServiceProtocol, persistence: PersistenceStore = .shared) {
        self.service = service
        self.persistence = persistence
        recentSearches = persistence.load([String].self, for: .recentSearches) ?? []
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether results for the current text are on screen, rather than suggestions.
    var isShowingResults: Bool {
        submittedQuery != nil && submittedQuery == trimmedQuery
    }

    func suggestions(products: [Product], categories: [ProductCategory]) -> [SearchSuggestion] {
        SearchEngine.suggestions(for: trimmedQuery, products: products, categories: categories)
    }

    func loadPopularSearches() async {
        guard popularSearches.isEmpty else {
            return
        }
        popularSearches = (try? await service.popularSearches()) ?? []
    }

    /// Searches for `text`, or the current query when `text` is `nil`, and remembers it as a recent search.
    func submit(_ text: String? = nil, in products: [Product]) async {
        let term = (text ?? query).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            return
        }
        query = term
        submittedQuery = term
        remember(term)
        resultsState = .loading

        do {
            let found = try await service.search(term, in: products)
            // A newer search may have started while this one ran; only the latest one lands.
            guard submittedQuery == term else {
                return
            }
            results = found
            resultsState = .loaded
        } catch {
            guard submittedQuery == term else {
                return
            }
            results = []
            resultsState = .failed(message: APIError.message(for: error))
        }
    }

    /// Back to recent and popular searches.
    func clear() {
        query = ""
        submittedQuery = nil
        results = []
        resultsState = .idle
    }

    func removeRecent(_ term: String) {
        recentSearches.removeAll { $0.caseInsensitiveCompare(term) == .orderedSame }
        persistence.save(recentSearches, for: .recentSearches)
    }

    func clearRecent() {
        recentSearches = []
        persistence.remove(.recentSearches)
    }

    private func remember(_ term: String) {
        recentSearches.removeAll { $0.caseInsensitiveCompare(term) == .orderedSame }
        recentSearches.insert(term, at: 0)
        recentSearches = Array(recentSearches.prefix(Self.maximumRecentSearches))
        persistence.save(recentSearches, for: .recentSearches)
    }
}

//
//  SearchView.swift
//  hnr-reader
//

import SwiftUI

struct SearchView: View {
    @State private var query = ""

    private var allStories: [HNStory] {
        StoryFeed.allCases.flatMap { MockData.stories(for: $0) }
    }

    private var results: [HNStory] {
        guard !query.isEmpty else { return [] }
        let q = query.lowercased()
        return allStories.filter {
            $0.title.lowercased().contains(q) ||
            $0.author.lowercased().contains(q) ||
            ($0.domain?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    SearchEmptyState()
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 48, leading: 16, bottom: 0, trailing: 16))
                } else if results.isEmpty {
                    NoResultsView(query: query)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 48, leading: 16, bottom: 0, trailing: 16))
                } else {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, story in
                        StoryRowView(story: story, rank: index + 1)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparatorTint(Color(uiColor: .separator))
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, placement: .toolbar)
        }
    }
}

// MARK: - Empty State

struct SearchEmptyState: View {
    private let suggestions = ["SwiftUI", "LLM inference", "Rust async", "PostgreSQL", "open source"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Suggested")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))

            ForEach(suggestions, id: \.self) { term in
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    Text(term)
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.vertical, 2)

                Divider()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

// MARK: - No Results

struct NoResultsView: View {
    let query: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 34))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))

            Text("No results for \"\(query)\"")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

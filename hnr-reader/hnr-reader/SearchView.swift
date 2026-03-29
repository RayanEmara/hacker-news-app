//
//  SearchView.swift
//  hnr-reader
//

import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var results: [HNStory] = []
    @State private var isSearching = false
    @State private var selectedStory: HNStory?
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty && results.isEmpty {
                    SearchEmptyState()
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 48, leading: 16, bottom: 0, trailing: 16))
                } else if isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 48, leading: 16, bottom: 0, trailing: 16))
                } else if !query.isEmpty && results.isEmpty {
                    NoResultsView(query: query)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 48, leading: 16, bottom: 0, trailing: 16))
                } else {
                    ForEach(results) { story in
                        Button { selectedStory = story } label: {
                            StoryRowView(story: story)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparatorTint(Color(uiColor: .separator))
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.system(size: 18))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(item: $selectedStory) { story in
                StoryDetailView(story: story)
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .task(id: query) {
                guard !query.isEmpty else {
                    results = []
                    return
                }
                isSearching = true
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                do {
                    let result = try await HNService.searchStories(query: query)
                    if !Task.isCancelled {
                        results = result.stories
                    }
                } catch {
                    if !Task.isCancelled {
                        results = []
                    }
                }
                isSearching = false
            }
        }
    }
}

// MARK: - Empty State

struct SearchEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))

            Text("Search Hacker News")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
        }
        .frame(maxWidth: .infinity)
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

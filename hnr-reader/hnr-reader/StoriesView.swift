//
//  StoriesView.swift
//  hnr-reader
//

import SwiftUI

struct StoriesView: View {
    let feed: StoryFeed
    @State private var store: StoryStore
    @State private var selectedStory: HNStory?
    @State private var showSettings = false

    init(feed: StoryFeed) {
        self.feed = feed
        self._store = State(initialValue: StoryStore(feed: feed))
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.stories.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = store.error, store.stories.isEmpty {
                    ErrorStateView(message: error.localizedDescription) {
                        Task { await store.loadStories() }
                    }
                } else {
                    List {
                        ForEach(store.stories) { story in
                            StoryRowView(story: story, isRead: ReadHistory.shared.isRead(story.id))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    ReadHistory.shared.markRead(story.id)
                                    selectedStory = story
                                }
                                .overlay(alignment: .trailing) {
                                    if let urlString = story.url, let url = URL(string: urlString) {
                                        Link(destination: url) {
                                            Color.clear
                                                .frame(width: 70, height: 70)
                                        }
                                        .padding(.trailing, 16)
                                        .padding(.top, 13)
                                    }
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparatorTint(Color(uiColor: .separator))
                                .listRowSeparator(.hidden, edges: .top)
                                .onAppear {
                                    if story.id == store.stories.last?.id {
                                        Task { await store.loadMore() }
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .navigationDestination(item: $selectedStory) { story in
                        StoryDetailView(story: story)
                    }
                    .refreshable {
                        await store.refresh()
                    }
                }
            }
            .navigationTitle(feed.rawValue)
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
        }
        .task {
            if store.stories.isEmpty {
                await store.loadStories()
            }
        }
    }
}

// MARK: - Error State

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 34))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))

            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .multilineTextAlignment(.center)

            Button("Retry", action: retry)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

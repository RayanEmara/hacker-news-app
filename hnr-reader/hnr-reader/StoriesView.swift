//
//  StoriesView.swift
//  hnr-reader
//

import SwiftUI

struct StoriesView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let feed: StoryFeed
    @State private var store: StoryStore
    @State private var readHistory = ReadHistory.shared
    @State private var selectedStory: HNStory?
    @State private var showSettings = false
    @State private var splitViewVisibility: NavigationSplitViewVisibility = .all

    init(feed: StoryFeed) {
        self.feed = feed
        self._store = State(initialValue: StoryStore(feed: feed))
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                splitViewLayout
            } else {
                stackedLayout
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: selectedStory) { _, story in
            if let story {
                readHistory.markRead(story.id)
            }
        }
        .task {
            if store.stories.isEmpty {
                await store.loadStories()
            }
        }
    }

    private var stackedLayout: some View {
        NavigationStack {
            storyList(selectionMode: false, topInset: 0)
                .navigationDestination(item: $selectedStory) { story in
                    StoryDetailView(story: story)
                }
                .navigationTitle(feed.rawValue)
                .navigationBarTitleDisplayMode(.large)
                .toolbar { settingsToolbar }
        }
    }

    private var splitViewLayout: some View {
        GeometryReader { proxy in
            NavigationSplitView(columnVisibility: $splitViewVisibility) {
                storyList(selectionMode: true, topInset: proxy.safeAreaInsets.top)
                    .toolbar(.hidden, for: .navigationBar)
            } detail: {
                ZStack {
                    if let selectedStory {
                        StoryDetailView(story: selectedStory)
                            .id(selectedStory.id)
                            .transition(.opacity)
                    } else {
                        ContentUnavailableView("Select a Post", systemImage: "doc.text")
                            .transition(.opacity)
                    }
                }
                .toolbar { settingsToolbar }
                .toolbarRole(.browser)
                .animation(.easeInOut(duration: 0.18), value: selectedStory?.id)
            }
            .navigationSplitViewStyle(.balanced)
            .ignoresSafeArea(edges: .top)
        }
    }

    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "person.circle")
                    .font(.system(size: 18))
            }
        }
    }

    @ViewBuilder
    private func storyList(selectionMode: Bool, topInset: CGFloat) -> some View {
        Group {
            if store.isLoading && store.stories.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = store.error, store.stories.isEmpty {
                ErrorStateView(message: error.localizedDescription) {
                    Task { await store.loadStories() }
                }
            } else {
                List(selection: selectionMode ? $selectedStory : .constant(nil)) {
                    if selectionMode {
                        HStack(spacing: 12) {
                            Text(feed.rawValue)
                                .font(.system(size: 26, weight: .bold))
                            Spacer()
                            Button {
                                splitViewVisibility = splitViewVisibility == .detailOnly ? .all : .detailOnly
                            } label: {
                                Image(systemName: splitViewVisibility == .detailOnly ? "sidebar.leading" : "rectangle.leadinghalf.inset.filled")
                                    .font(.system(size: 19, weight: .medium))
                                    .foregroundStyle(Color(uiColor: .label))
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowInsets(EdgeInsets(top: topInset + 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                    ForEach(store.stories) { story in
                        StoryRowView(story: story, isRead: readHistory.isRead(story.id))
                            .contentShape(Rectangle())
                            .onTapGesture {
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
                .refreshable {
                    await store.refresh()
                }
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

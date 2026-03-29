//
//  StoriesView.swift
//  hnr-reader
//

import SwiftUI

struct StoriesView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let focusSearchRequestID: Int
    @State var feed: StoryFeed
    @State private var store: StoryStore
    @State private var readHistory = ReadHistory.shared
    @State private var selectedStory: HNStory?
    @State private var showSettings = false
    @State private var splitViewVisibility: NavigationSplitViewVisibility = .all
    @State private var searchQuery = ""
    @State private var searchResults: [HNStory] = []
    @State private var isSearching = false
    @State private var showSearch = false
    @State private var browserURL: URL?
    @State private var isSearchPresented = false

    @AppStorage("useInAppBrowser") private var useInAppBrowser = true

    init(feed: StoryFeed, focusSearchRequestID: Int = 0) {
        self.focusSearchRequestID = focusSearchRequestID
        self._feed = State(initialValue: feed)
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
            browserURL = nil
            if let story {
                readHistory.markRead(story.id)
            }
        }
        .onChange(of: feed) { _, newFeed in
            selectedStory = nil
            store = StoryStore(feed: newFeed)
            Task { await store.loadStories() }
        }
        .task {
            if store.stories.isEmpty {
                await store.loadStories()
            }
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

    private var stackedLayout: some View {
        NavigationStack {
            storyList(selectionMode: false)
                .navigationDestination(item: $selectedStory) { story in
                    StoryDetailView(story: story)
                }
                .navigationTitle(feed.rawValue)
                .navigationBarTitleDisplayMode(.large)
                .toolbar { settingsToolbar }
        }
    }

    private var splitViewLayout: some View {
        NavigationSplitView(columnVisibility: $splitViewVisibility) {
            storyList(selectionMode: true)
                .navigationTitle(feed.rawValue)
                .navigationBarTitleDisplayMode(.large)
                .searchable(text: $searchQuery, isPresented: $isSearchPresented, placement: .sidebar, prompt: "Search")
                .task(id: searchQuery) {
                    guard !searchQuery.isEmpty else {
                        searchResults = []
                        isSearching = false
                        return
                    }
                    isSearching = true
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    do {
                        let result = try await HNService.searchStories(query: searchQuery)
                        if !Task.isCancelled {
                            searchResults = result.stories
                        }
                    } catch {
                        if !Task.isCancelled {
                            searchResults = []
                        }
                    }
                    isSearching = false
                }
                .onChange(of: focusSearchRequestID) { _, _ in
                    isSearchPresented = true
                }
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

                if let browserURL {
                    InlineWebView(url: browserURL)
                        .id(browserURL)
                        .background(Color(.systemBackground))
                        .ignoresSafeArea(.container, edges: [.top, .bottom])
                        .transition(.modifier(
                            active: WebViewTransition(opacity: 0, blur: 6),
                            identity: WebViewTransition(opacity: 1, blur: 0)
                        ))
                }
            }
            .environment(\.openURL, OpenURLAction { url in
                if useInAppBrowser {
                    browserURL = url
                    return .handled
                }
                return .systemAction
            })
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    if browserURL != nil {
                        Button {
                            browserURL = nil
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                        }
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("Feed", selection: $feed) {
                            ForEach(StoryFeed.allCases, id: \.self) { f in
                                Label(f.rawValue, systemImage: f.iconName).tag(f)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(feed.shortTitle)
                                .padding(.leading, 4)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .font(.system(size: 15, weight: .semibold))
                    }
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.system(size: 18))
                    }
                }
            }
            .toolbarRole(.browser)
            .animation(.easeInOut(duration: 0.18), value: selectedStory?.id)
            .animation(.spring(duration: 0.3, bounce: 0.0), value: browserURL)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func storyList(selectionMode: Bool) -> some View {
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
                    if selectionMode && !searchQuery.isEmpty {
                        if isSearching {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        } else if searchResults.isEmpty {
                            NoResultsView(query: searchQuery)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        } else {
                            ForEach(searchResults) { story in
                                StoryRowView(story: story)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedStory = story
                                    }
                                    .listRowBackground(
                                        selectedStory == story
                                            ? Color.primary.opacity(0.1)
                                            : Color.clear
                                    )
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparatorTint(Color(uiColor: .separator))
                                    .listRowSeparator(.hidden, edges: .top)
                            }
                        }
                    } else {
                        ForEach(store.stories) { story in
                            StoryRowView(story: story, isRead: readHistory.isRead(story.id))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedStory = story
                                }
                                .listRowBackground(
                                    selectionMode && selectedStory == story
                                        ? Color.primary.opacity(0.1)
                                        : Color.clear
                                )
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
                }
                .listStyle(.plain)
                .refreshable {
                    await store.refresh()
                }
            }
        }
    }
}

// MARK: - Web View Transition

struct WebViewTransition: ViewModifier {
    let opacity: Double
    let blur: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .blur(radius: blur)
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

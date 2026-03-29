//
//  ContentView.swift
//  hnr-reader
//
//  Created by Rayan Emara on 28/03/2026.
//

import SwiftUI

private enum AppTab: Hashable {
    case top
    case new
    case ask
    case show
    case search

    init(feed: StoryFeed) {
        switch feed {
        case .top: self = .top
        case .new: self = .new
        case .ask: self = .ask
        case .show: self = .show
        }
    }
}

struct ContentView: View {
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage("defaultFeed") private var defaultFeedStorage = StoryFeed.top.storageValue
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab = AppTab.top
    @State private var searchFocusRequestID = 0

    private var defaultFeed: StoryFeed {
        StoryFeed.fromStorageValue(defaultFeedStorage)
    }

    private var usesSplitViewLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var preferredColorScheme: ColorScheme? {
        switch appColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        rootContent
        .background {
            Button("Focus Search") {
                focusSearch()
            }
            .keyboardShortcut("f", modifiers: .command)
            .hidden()
        }
        .preferredColorScheme(preferredColorScheme)
        .onAppear {
            selectedTab = AppTab(feed: defaultFeed)
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        if usesSplitViewLayout {
            StoriesView(feed: defaultFeed, focusSearchRequestID: searchFocusRequestID)
                .id(defaultFeed)
        } else {
            TabView(selection: $selectedTab) {
                Tab("Top", systemImage: "flame.fill", value: AppTab.top) {
                    StoriesView(feed: .top)
                }

                Tab("New", systemImage: "sparkles", value: AppTab.new) {
                    StoriesView(feed: .new)
                }

                Tab("Ask", systemImage: "bubble.left.fill", value: AppTab.ask) {
                    StoriesView(feed: .ask)
                }

                Tab("Show", systemImage: "eye.fill", value: AppTab.show) {
                    StoriesView(feed: .show)
                }

                Tab(value: AppTab.search, role: .search) {
                    SearchView(focusSearchRequestID: searchFocusRequestID)
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
        }
    }

    private func focusSearch() {
        if usesSplitViewLayout {
            searchFocusRequestID += 1
        } else {
            selectedTab = .search
            Task { @MainActor in
                await Task.yield()
                searchFocusRequestID += 1
            }
        }
    }
}

#Preview {
    ContentView()
}

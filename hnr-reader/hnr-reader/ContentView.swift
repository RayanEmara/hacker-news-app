//
//  ContentView.swift
//  hnr-reader
//
//  Created by Rayan Emara on 28/03/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Top", systemImage: "flame.fill") {
                StoriesView(feed: .top)
            }

            Tab("New", systemImage: "sparkles") {
                StoriesView(feed: .new)
            }

            Tab("Ask", systemImage: "bubble.left.fill") {
                StoriesView(feed: .ask)
            }

            Tab("Show", systemImage: "eye.fill") {
                StoriesView(feed: .show)
            }

            Tab(role: .search) {
                SearchView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
}

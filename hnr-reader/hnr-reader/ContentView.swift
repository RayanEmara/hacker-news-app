//
//  ContentView.swift
//  hnr-reader
//
//  Created by Rayan Emara on 28/03/2026.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var preferredColorScheme: ColorScheme? {
        switch appColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                StoriesView(feed: .top)
            } else {
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
        .preferredColorScheme(preferredColorScheme)
    }
}

#Preview {
    ContentView()
}

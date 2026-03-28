//
//  StoriesView.swift
//  hnr-reader
//

import SwiftUI

struct StoriesView: View {
    let feed: StoryFeed
    @State private var stories: [HNStory] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(stories) { story in
                    StoryRowView(story: story)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparatorTint(Color(uiColor: .separator))
                }
            }
            .listStyle(.plain)
            .navigationTitle(feed.rawValue)
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            stories = MockData.stories(for: feed)
        }
    }
}

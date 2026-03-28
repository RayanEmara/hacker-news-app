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
                ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                    StoryRowView(story: story, rank: index + 1)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparatorTint(Color(uiColor: .separator))
                }
            }
            .listStyle(.plain)
            .navigationTitle(feed.rawValue)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            stories = MockData.stories(for: feed).shuffled()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .tint(Color(.label))
                }
            }
        }
        .onAppear {
            stories = MockData.stories(for: feed)
        }
    }
}

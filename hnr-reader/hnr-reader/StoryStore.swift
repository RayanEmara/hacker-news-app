//
//  StoryStore.swift
//  hnr-reader
//

import Foundation

@Observable
class StoryStore {
    let feed: StoryFeed

    private(set) var stories: [HNStory] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private var currentPage = 0
    private var hasMore = true
    private var isLoadingMore = false

    init(feed: StoryFeed) {
        self.feed = feed
    }

    func loadStories() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        currentPage = 0

        do {
            let result = try await HNService.fetchStories(feed: feed, page: 0)
            stories = result.stories
            hasMore = result.hasMore
            currentPage = 1
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true

        do {
            let result = try await HNService.fetchStories(feed: feed, page: currentPage)
            stories.append(contentsOf: result.stories)
            hasMore = result.hasMore
            currentPage += 1
        } catch {
            // Silently fail on pagination — user can scroll again to retry
        }

        isLoadingMore = false
    }

    func refresh() async {
        error = nil
        currentPage = 0

        do {
            let result = try await HNService.fetchStories(feed: feed, page: 0)
            stories = result.stories
            hasMore = result.hasMore
            currentPage = 1
        } catch {
            self.error = error
        }
    }
}

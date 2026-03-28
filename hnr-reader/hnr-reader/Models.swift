//
//  Models.swift
//  hnr-reader
//

import Foundation

enum StoryFeed: String, CaseIterable {
    case top = "Top"
    case new = "New"
    case ask = "Ask"
    case show = "Show"
}

struct HNStory: Identifiable {
    let id: Int
    let title: String
    let url: String?
    let domain: String?
    let score: Int
    let author: String
    let timeAgo: String
    let commentsCount: Int
    let feed: StoryFeed
    let isAskHN: Bool
    let isShowHN: Bool
    let bodyText: String?

    init(
        id: Int,
        title: String,
        url: String? = nil,
        domain: String? = nil,
        score: Int,
        author: String,
        timeAgo: String,
        commentsCount: Int,
        feed: StoryFeed = .top,
        isAskHN: Bool = false,
        isShowHN: Bool = false,
        bodyText: String? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.domain = domain
        self.score = score
        self.author = author
        self.timeAgo = timeAgo
        self.commentsCount = commentsCount
        self.feed = feed
        self.isAskHN = isAskHN
        self.isShowHN = isShowHN
        self.bodyText = bodyText
    }
}

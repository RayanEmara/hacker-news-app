//
//  Models.swift
//  hnr-reader
//

import Foundation

enum StoryFeed: String, CaseIterable {
    case top = "Top stories"
    case new = "New stories"
    case ask = "Ask Hacker News"
    case show = "Show Hacker News"
}

struct HNStory: Identifiable, Hashable {
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

    static func from(_ hit: AlgoliaHit, feed: StoryFeed) -> HNStory? {
        guard let title = hit.title, !title.isEmpty,
              let idInt = Int(hit.objectID)
        else { return nil }

        let domain: String? = hit.url.flatMap { URL(string: $0)?.host?.replacingOccurrences(of: "www.", with: "") }
        let timeAgo = hit.createdAtI.map { Self.relativeTime(from: $0) } ?? ""
        let isAsk = title.hasPrefix("Ask HN")
        let isShow = title.hasPrefix("Show HN")

        return HNStory(
            id: idInt,
            title: title,
            url: hit.url,
            domain: domain,
            score: hit.points ?? 0,
            author: hit.author ?? "",
            timeAgo: timeAgo,
            commentsCount: hit.numComments ?? 0,
            feed: feed,
            isAskHN: isAsk,
            isShowHN: isShow,
            bodyText: hit.storyText
        )
    }

    private static func relativeTime(from timestamp: Int) -> String {
        let seconds = Int(Date().timeIntervalSince1970) - timestamp
        if seconds < 60 { return "\(seconds)s ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }
}

// MARK: - Comment

struct HNComment: Identifiable {
    let id: Int
    let author: String
    let body: String
    let timeAgo: String
    let depth: Int

    static func from(_ child: AlgoliaItemChild, depth: Int) -> HNComment? {
        guard let author = child.author, let text = child.text, !author.isEmpty else { return nil }
        return HNComment(
            id: child.id,
            author: author,
            body: stripHTML(text),
            timeAgo: child.createdAtI.map { relativeTime(from: $0) } ?? "",
            depth: depth
        )
    }

    private static func relativeTime(from timestamp: Int) -> String {
        let seconds = Int(Date().timeIntervalSince1970) - timestamp
        if seconds < 60 { return "\(seconds)s ago" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }

    private static func stripHTML(_ html: String) -> String {
        var result = html
        result = result.replacingOccurrences(of: "<p>", with: "\n\n")
        result = result.replacingOccurrences(of: "<br>", with: "\n")
        result = result.replacingOccurrences(of: "<br/>", with: "\n")
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>") {
            result = regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: "")
        }
        result = result
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&#x2F;", with: "/")
            .replacingOccurrences(of: "&nbsp;", with: " ")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

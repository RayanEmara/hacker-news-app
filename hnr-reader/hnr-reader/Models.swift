//
//  Models.swift
//  hnr-reader
//

import Foundation

enum StoryFeed: String, CaseIterable {
    case top = "Top posts"
    case new = "New posts"
    case ask = "Ask posts"
    case show = "Show posts"

    var storageValue: String {
        switch self {
        case .top: "top"
        case .new: "new"
        case .ask: "ask"
        case .show: "show"
        }
    }

    var shortTitle: String {
        switch self {
        case .top: "Top"
        case .new: "New"
        case .ask: "Ask"
        case .show: "Show"
        }
    }

    var iconName: String {
        switch self {
        case .top: "flame.fill"
        case .new: "sparkles"
        case .ask: "bubble.left.fill"
        case .show: "eye.fill"
        }
    }

    static func fromStorageValue(_ value: String) -> StoryFeed {
        Self.allCases.first(where: { $0.storageValue == value }) ?? .top
    }
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
    let body: AttributedString
    let timeAgo: String
    let depth: Int

    static func from(_ child: AlgoliaItemChild, depth: Int) -> HNComment? {
        guard let author = child.author, let text = child.text, !author.isEmpty else { return nil }
        return HNComment(
            id: child.id,
            author: author,
            body: parseHTML(text),
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

    static func decodeEntities(_ text: String) -> String {
        text.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&#x2F;", with: "/")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#47;", with: "/")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }

    private enum InlineTag {
        case link(url: String, text: String)
        case italic(text: String)
    }

    static func parseHTML(_ html: String) -> AttributedString {
        var processed = html
        var tags: [(range: NSRange, tag: InlineTag)] = []

        // Extract <a> tags
        if let linkPattern = try? NSRegularExpression(pattern: #"<a\s+[^>]*href\s*=\s*"([^"]*)"[^>]*>(.*?)</a>"#, options: .caseInsensitive) {
            let ns = processed as NSString
            for match in linkPattern.matches(in: processed, range: NSRange(location: 0, length: ns.length)) {
                let url = decodeEntities(ns.substring(with: match.range(at: 1)))
                let text = decodeEntities(ns.substring(with: match.range(at: 2)))
                tags.append((match.range, .link(url: url, text: text)))
            }
        }

        // Extract <i> / <em> tags
        if let italicPattern = try? NSRegularExpression(pattern: #"<(i|em)>(.*?)</\1>"#, options: .caseInsensitive) {
            let ns = processed as NSString
            for match in italicPattern.matches(in: processed, range: NSRange(location: 0, length: ns.length)) {
                let range = match.range
                // Skip if this range overlaps with an already-extracted tag (e.g. italic inside a link)
                if tags.contains(where: { NSIntersectionRange($0.range, range).length > 0 }) { continue }
                let text = ns.substring(with: match.range(at: 2))
                tags.append((range, .italic(text: text)))
            }
        }

        // Sort by position ascending (document order) — replace from end to start to preserve indices
        tags.sort { $0.range.location < $1.range.location }

        for (i, tag) in tags.enumerated().reversed() {
            guard let range = Range(tag.range, in: processed) else { continue }
            processed.replaceSubrange(range, with: "⟦TAG\(i)⟧")
        }

        // Convert block-level HTML to newlines
        processed = processed.replacingOccurrences(of: "<p>", with: "\n\n")
        processed = processed.replacingOccurrences(of: "<br>", with: "\n")
        processed = processed.replacingOccurrences(of: "<br/>", with: "\n")

        // Strip remaining HTML tags
        if let tagRegex = try? NSRegularExpression(pattern: "<[^>]+>") {
            processed = tagRegex.stringByReplacingMatches(in: processed, range: NSRange(location: 0, length: (processed as NSString).length), withTemplate: "")
        }

        processed = decodeEntities(processed)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Build AttributedString, replacing placeholders with styled runs
        var result = AttributedString()
        var remaining = processed

        for (i, tag) in tags.enumerated() {
            let placeholder = "⟦TAG\(i)⟧"
            guard let placeholderRange = remaining.range(of: placeholder) else { continue }

            let before = String(remaining[remaining.startIndex..<placeholderRange.lowerBound])
            if !before.isEmpty {
                result.append(AttributedString(before))
            }

            switch tag.tag {
            case .link(let url, let text):
                var linkStr = AttributedString(decodeEntities(text))
                if let parsedURL = URL(string: url) {
                    linkStr.link = parsedURL
                }
                result.append(linkStr)
            case .italic(let text):
                var italicStr = AttributedString(decodeEntities(text))
                italicStr.inlinePresentationIntent = .emphasized
                result.append(italicStr)
            }

            remaining = String(remaining[placeholderRange.upperBound...])
        }

        if !remaining.isEmpty {
            result.append(AttributedString(remaining))
        }

        return result
    }
}

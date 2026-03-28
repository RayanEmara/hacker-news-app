//
//  StoryRowView.swift
//  hnr-reader
//

import SwiftUI

// MARK: - Story Row

struct StoryRowView: View {
    let story: HNStory
    let rank: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {

            // titolo
            Text(story.title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            
            if let body = story.bodyText {
                Text(body)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            
            if let domain = story.domain, let urlString = story.url {
                URLPillView(domain: domain, urlString: urlString)
            }

            
            MetaRowView(story: story, rank: rank)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - URL Pill

struct URLPillView: View {
    let domain: String
    let urlString: String

    private var pathSuffix: String {
        guard let url = URL(string: urlString) else { return "" }
        var path = url.path
        if let query = url.query { path += "?\(query)" }
        return path.isEmpty ? "" : path
    }

    var body: some View {
        HStack(spacing: 8) {
            FaviconView(domain: domain)
                .frame(width: 17, height: 17)

            // Domain bold + path gray — iOS 26 string interpolation style
            Text("\(Text(domain).fontWeight(.semibold))\(Text(pathSuffix).foregroundStyle(.secondary))")
                .font(.system(size: 13))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Favicon

struct FaviconView: View {
    let domain: String

    private var resolved: (symbol: String, color: Color) {
        if domain.contains("github") {
            return ("chevron.left.forwardslash.chevron.right", Color(.label))
        } else if domain.contains("youtube") {
            return ("play.rectangle.fill", .red)
        } else if domain.contains("arxiv") {
            return ("doc.text.fill", Color(red: 0.68, green: 0.11, blue: 0.11))
        } else if domain.contains("stanford") {
            return ("graduationcap.fill", Color(red: 0.55, green: 0.09, blue: 0.09))
        } else if domain.contains("anthropic") {
            return ("sparkles", .blue)
        } else if domain.contains("apple") || domain.contains("developer.apple") {
            return ("apple.logo", Color(.label))
        } else if domain.contains("postgresql") || domain.contains("postgres") {
            return ("cylinder.fill", Color(red: 0.25, green: 0.45, blue: 0.75))
        } else if domain.contains("mozilla") || domain.contains("firefox") {
            return ("flame.fill", Color(red: 0.9, green: 0.45, blue: 0.1))
        } else if domain.contains("medium") {
            return ("text.alignleft", Color(.label))
        } else if domain.contains("techcrunch") {
            return ("bolt.fill", Color(red: 0.1, green: 0.72, blue: 0.38))
        } else if domain.contains("vercel") || domain.contains("nextjs") {
            return ("triangle.fill", Color(.label))
        } else if domain.contains("bun.sh") {
            return ("shazam.logo.fill", Color(red: 0.95, green: 0.75, blue: 0.25))
        } else if domain.contains("git-scm") {
            return ("arrow.triangle.branch", Color(red: 0.93, green: 0.29, blue: 0.20))
        } else if domain.contains("supabase") {
            return ("bolt.fill", Color(red: 0.23, green: 0.76, blue: 0.51))
        } else if domain.contains("zed.dev") {
            return ("keyboard", Color(.label))
        } else {
            return ("globe", Color(.secondaryLabel))
        }
    }

    var body: some View {
        Image(systemName: resolved.symbol)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(resolved.color)
            .frame(width: 17, height: 17)
    }
}

// MARK: - Meta Row

struct MetaRowView: View {
    let story: HNStory
    let rank: Int

    var body: some View {
        HStack(spacing: 0) {
            // Rank
            HStack(spacing: 2) {
                Text("#")
                    .foregroundStyle(Color(.tertiaryLabel))
                Text("\(rank)")
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .font(.system(size: 13))

            Text("  ·  ")
                .font(.system(size: 13))
                .foregroundStyle(Color(.quaternaryLabel))

            // Score
            HStack(spacing: 4) {
                Image(systemName: "arrowtriangle.up")
                    .font(.system(size: 10, weight: .medium))
                Text("\(story.score) points")
                    .font(.system(size: 13))
            }
            .foregroundStyle(Color(.secondaryLabel))

            Text("  ·  ")
                .font(.system(size: 13))
                .foregroundStyle(Color(.quaternaryLabel))

            // Comments
            HStack(spacing: 4) {
                Image(systemName: "bubble.right")
                    .font(.system(size: 10, weight: .medium))
                Text("\(story.commentsCount) comments")
                    .font(.system(size: 13))
            }
            .foregroundStyle(Color(.secondaryLabel))

            Spacer(minLength: 8)

            // Time
            Text(story.timeAgo)
                .font(.system(size: 13))
                .foregroundStyle(Color(.tertiaryLabel))
        }
    }
}

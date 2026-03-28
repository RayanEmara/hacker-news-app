//
//  StoryRowView.swift
//  hnr-reader
//

import SwiftUI

// MARK: - Story Row

struct StoryRowView: View {
    let story: HNStory

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // Left: content
            VStack(alignment: .leading, spacing: 6) {
                Text(story.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 4)

                // Meta row
                HStack(spacing: 6) {
                    Text(sourceLabel)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text("·")
                        .foregroundStyle(Color(uiColor: .quaternaryLabel))

                    HStack(spacing: 3) {
                        Image(systemName: "arrowtriangle.up")
                            .imageScale(.small)
                        Text(formattedScore)
                    }

                    Text("·")
                        .foregroundStyle(Color(uiColor: .quaternaryLabel))

                    HStack(spacing: 3) {
                        Image(systemName: "bubble.right")
                            .imageScale(.small)
                        Text("\(story.commentsCount)")
                    }

                    Text("·")
                        .foregroundStyle(Color(uiColor: .quaternaryLabel))

                    Text(story.timeAgo)
                }
                .font(.system(size: 12))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
            }

            Spacer(minLength: 0)

            // Right: thumbnail
            StoryThumbnail(story: story)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sourceLabel: String {
        if story.isAskHN { return "Ask HN" }
        if story.isShowHN { return "Show HN" }
        return story.domain ?? "news.ycombinator.com"
    }

    private var formattedScore: String {
        story.score >= 1000
            ? String(format: "%.1fK", Double(story.score) / 1000)
            : "\(story.score)"
    }
}

// MARK: - Thumbnail

struct StoryThumbnail: View {
    let story: HNStory

    private enum Kind { case video, code, text, link }

    private var kind: Kind {
        guard let domain = story.domain else { return .text }
        if domain.contains("youtube") || domain.contains("youtu.be") || domain.contains("vimeo") {
            return .video
        }
        if domain.contains("github") || domain.contains("gitlab") {
            return .code
        }
        return .link
    }

    private var tint: Color {
        deterministicColor(for: story.domain ?? story.title)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backgroundColor)

            icon
        }
        .frame(width: 70, height: 70)
    }

    private var backgroundColor: Color {
        switch kind {
        case .video:  return Color(uiColor: .systemGray4)
        case .code:   return Color(uiColor: .systemGray6)
        case .text:   return Color(uiColor: .secondarySystemBackground)
        case .link:   return tint.opacity(0.13)
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch kind {
        case .video:
            Image(systemName: "play.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(uiColor: .label))
                .offset(x: 2)

        case .code:
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color(uiColor: .label))

        case .text:
            Image(systemName: "text.alignleft")
                .font(.system(size: 22))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))

        case .link:
            Text(String((story.domain ?? story.title).prefix(1)).uppercased())
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
        }
    }
}

// MARK: - Helpers

func deterministicColor(for text: String) -> Color {
    let hues: [Double] = [0.58, 0.35, 0.72, 0.09, 0.50, 0.15, 0.93, 0.27, 0.65, 0.44]
    let hash = text.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
    return Color(hue: hues[abs(hash) % hues.count], saturation: 0.55, brightness: 0.62)
}

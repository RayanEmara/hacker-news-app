//
//  StoryRowView.swift
//  hnr-reader
//

import SwiftUI
import LinkPresentation

// MARK: - Story Row

struct StoryRowView: View {
    let story: HNStory
    var isRead: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // Left: content
            VStack(alignment: .leading, spacing: 6) {
                Text(story.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isRead ? .secondary : .primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 4)

                // Meta rows
                VStack(alignment: .leading, spacing: 6) {
                    Text(sourceLabel)
                        .fontWeight(.medium)

                    HStack(spacing: 6) {
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
                }
                .font(.caption)
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
    @State private var previewImage: UIImage?

    // Only fetch OG image for link posts (has a URL, not a text post)
    private var isLinkPost: Bool {
        story.url != nil && !story.isAskHN && !story.isShowHN
    }

    private var tint: Color {
        deterministicColor(for: story.domain ?? story.title)
    }

    var body: some View {
        Group {
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
            } else {
                fallback
            }
        }
        .frame(width: 70, height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .task(id: story.id) {
            guard isLinkPost, let url = story.url else { return }
            previewImage = await OGImageCache.shared.fetch(url: url)
        }
    }

    @ViewBuilder
    private var fallback: some View {
        ZStack {
            fallbackBackground
            fallbackIcon
        }
    }

    private var fallbackBackground: Color {
        guard let domain = story.domain else {
            return Color(uiColor: .secondarySystemBackground)
        }
        if domain.contains("youtube") || domain.contains("youtu.be") || domain.contains("vimeo") {
            return Color(uiColor: .systemGray4)
        }
        if domain.contains("github") || domain.contains("gitlab") {
            return Color(uiColor: .systemGray6)
        }
        if story.isAskHN || story.isShowHN || story.url == nil {
            return Color(uiColor: .secondarySystemBackground)
        }
        return tint.opacity(0.13)
    }

    @ViewBuilder
    private var fallbackIcon: some View {
        if let domain = story.domain {
            if domain.contains("youtube") || domain.contains("youtu.be") || domain.contains("vimeo") {
                Image(systemName: "play.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .label))
                    .offset(x: 2)
            } else if domain.contains("github") || domain.contains("gitlab") {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(uiColor: .label))
            } else if story.isAskHN || story.isShowHN || story.url == nil {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 22))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            } else {
                Text(String(domain.prefix(1)).uppercased())
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
            }
        } else {
            Image(systemName: "text.alignleft")
                .font(.system(size: 22))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
    }
}

// MARK: - OG Image Cache

@MainActor
final class OGImageCache {
    static let shared = OGImageCache()
    private var cached: [String: UIImage] = [:]
    private var failed: Set<String> = []
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    func fetch(url: String) async -> UIImage? {
        if let hit = cached[url] { return hit }
        if failed.contains(url) { return nil }

        // Reuse an in-flight task for the same URL rather than making a duplicate request
        if let existing = inFlight[url] {
            return await existing.value
        }

        let task = Task { @MainActor in
            await Self.fetchViaLinkPresentation(url: url)
        }
        inFlight[url] = task
        let result = await task.value
        inFlight.removeValue(forKey: url)

        if let result {
            cached[url] = result
        } else {
            failed.insert(url)
        }
        return result
    }

    private static func fetchViaLinkPresentation(url: String) async -> UIImage? {
        guard let parsedURL = URL(string: url) else { return nil }
        let provider = LPMetadataProvider()
        provider.timeout = 10
        guard let metadata = try? await provider.startFetchingMetadata(for: parsedURL),
              let imageProvider = metadata.imageProvider,
              let image = try? await imageProvider.loadUIImage()
        else { return nil }
        return image
    }
}

private extension NSItemProvider {
    func loadUIImage() async throws -> UIImage? {
        guard canLoadObject(ofClass: UIImage.self) else { return nil }
        return try await withCheckedThrowingContinuation { continuation in
            _ = loadObject(ofClass: UIImage.self) { object, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: object as? UIImage)
                }
            }
        }
    }
}

// MARK: - Helpers

func deterministicColor(for text: String) -> Color {
    let hues: [Double] = [0.58, 0.35, 0.72, 0.09, 0.50, 0.15, 0.93, 0.27, 0.65, 0.44]
    let hash = text.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
    return Color(hue: hues[abs(hash) % hues.count], saturation: 0.55, brightness: 0.62)
}

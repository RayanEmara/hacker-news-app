//
//  StoryDetailView.swift
//  hnr-reader
//

import SwiftUI

struct StoryDetailView: View {
    let story: HNStory

    @State private var previewImage: UIImage?
    @State private var comments: [HNComment] = []
    @State private var isLoadingComments = true
    @State private var collapsedIDs: Set<Int> = []

    /// Returns comments with collapsed children filtered out.
    private var visibleComments: [HNComment] {
        var result: [HNComment] = []
        var skipDepthAbove: Int? = nil
        for comment in comments {
            if let threshold = skipDepthAbove {
                if comment.depth > threshold {
                    continue // child of a collapsed comment
                } else {
                    skipDepthAbove = nil
                }
            }
            result.append(comment)
            if collapsedIDs.contains(comment.id) {
                skipDepthAbove = comment.depth
            }
        }
        return result
    }

    private var navTitle: String {
        if story.isAskHN { return "Ask HN" }
        if story.isShowHN { return "Show HN" }
        return story.domain ?? "Hacker News"
    }

    var body: some View {
        ScrollView {
            // frame(maxWidth: .infinity) is required — without it, ScrollView proposes
            // an unconstrained width to the VStack, breaking all child padding/wrapping.
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Hero image
                if let img = previewImage {
                    Group {
                        if let urlString = story.url, let url = URL(string: urlString) {
                            Link(destination: url) {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                    .overlay {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                    }
                                    .clipped()
                            }
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                                .overlay {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                }
                                .clipped()
                        }
                    }
                }

                // MARK: Title + body + metadata
                VStack(alignment: .leading, spacing: 10) {
                    Text(story.title)
                        .font(.title2.weight(.bold))

                    if let bodyText = story.bodyText, !bodyText.isEmpty {
                        Text(HNComment.parseHTML(bodyText))
                            .font(.system(size: 15))
                            .foregroundStyle(Color(uiColor: .label))
                            .tint(Color(red: 0.4, green: 0.6, blue: 1.0))
                    }

                    HStack(spacing: 4) {
                        if let urlString = story.url, let url = URL(string: urlString) {
                            Link(destination: url) {
                                Text(story.domain ?? "news.ycombinator.com")
                                    .foregroundStyle(Color.orange)
                            }
                        } else {
                            Text(story.domain ?? "news.ycombinator.com")
                                .foregroundStyle(Color.orange)
                        }
                        Text("by \(story.author)")
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                    .font(.system(size: 13, weight: .medium))

                    HStack(spacing: 5) {
                        Text("\(story.score) pts")
                        Text("·").foregroundStyle(Color(uiColor: .quaternaryLabel))
                        Text("\(story.commentsCount) comments")
                        Text("·").foregroundStyle(Color(uiColor: .quaternaryLabel))
                        Text(story.timeAgo)
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

                // MARK: Action bar
                HStack(spacing: 0) {
                    actionButton("arrowtriangle.up")
                    actionButton("arrowtriangle.down")
                    Spacer()
                    actionButton("bookmark")
                    actionButton("bubble.right")
                    if let urlString = story.url, let shareURL = URL(string: urlString) {
                        ShareLink(item: shareURL) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 19))
                                .foregroundStyle(Color(uiColor: .label))
                                .frame(width: 50, height: 44)
                        }
                    } else {
                        actionButton("square.and.arrow.up")
                    }
                }
                .padding(.horizontal, 6)

                Divider()

                // MARK: Comments
                if isLoadingComments {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else if comments.isEmpty {
                    Text("No comments yet")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(uiColor: .tertiaryLabel))
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .multilineTextAlignment(.center)
                } else {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(visibleComments) { comment in
                            CommentRowView(
                                comment: comment,
                                opAuthor: story.author,
                                isCollapsed: collapsedIDs.contains(comment.id),
                                onToggleCollapse: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        if collapsedIDs.contains(comment.id) {
                                            collapsedIDs.remove(comment.id)
                                        } else {
                                            collapsedIDs.insert(comment.id)
                                        }
                                    }
                                }
                            )
                            Divider()
                                .padding(.leading, 16 + CGFloat(min(comment.depth, 4)) * 12)
                        }
                    }
                }

            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            async let imageTask: Void = loadImage()
            async let commentsTask: Void = loadComments()
            _ = await (imageTask, commentsTask)
        }
    }

    private func loadImage() async {
        guard let url = story.url else { return }
        previewImage = await OGImageCache.shared.fetch(url: url)
    }

    private func loadComments() async {
        do {
            comments = try await HNService.fetchComments(storyID: story.id)
        } catch {}
        isLoadingComments = false
    }

    @ViewBuilder
    private func actionButton(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 19))
            .foregroundStyle(Color(uiColor: .tertiaryLabel))
            .frame(width: 50, height: 44)
    }
}

// MARK: - Comment Row

struct CommentRowView: View {
    let comment: HNComment
    let opAuthor: String
    var isCollapsed: Bool = false
    var onToggleCollapse: (() -> Void)? = nil

    private var isOP: Bool { comment.author == opAuthor }
    private var depth: Int { min(comment.depth, 4) }
    private var leadingPad: CGFloat { 16 + CGFloat(depth) * 12 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header — tapping this collapses/expands
            HStack(alignment: .center, spacing: 4) {
                Text(isOP ? "(OP) \(comment.author)" : comment.author)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isOP ? Color.accentColor.opacity(isCollapsed ? 0.5 : 1.0) : Color(uiColor: isCollapsed ? .tertiaryLabel : .label))
                    .lineLimit(1)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))

                Spacer(minLength: 8)

                Text(comment.timeAgo)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    .layoutPriority(1)
            }
            .contentShape(Rectangle())
            .onTapGesture { onToggleCollapse?() }

            // Body — links are tappable, not intercepted by collapse gesture
            if !isCollapsed {
                Text(comment.body)
                    .font(.system(size: 15))
                    .foregroundStyle(Color(uiColor: .label))
                    .tint(Color(red: 0.4, green: 0.6, blue: 1.0))
            }
        }
        .padding(.leading, leadingPad)
        .padding(.trailing, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {
            if depth > 0 {
                Rectangle()
                    .fill(Color(uiColor: .separator))
                    .frame(width: 1.5)
                    .padding(.leading, 16 + CGFloat(depth - 1) * 12 + 5)
                    .padding(.vertical, 4)
            }
        }
    }
}

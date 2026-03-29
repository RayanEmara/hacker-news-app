//
//  StoryDetailView.swift
//  hnr-reader
//

import SwiftUI

struct StoryDetailView: View {
    let story: HNStory

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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

    private var allowsTopHeroBleed: Bool { previewImage != nil }

    var body: some View {
        ScrollView {
            // frame(maxWidth: .infinity) is required — without it, ScrollView proposes
            // an unconstrained width to the VStack, breaking all child padding/wrapping.
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Hero image
                if let img = previewImage {
                    let heroContent = Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 360)
                        .overlay {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        }
                        .overlay {
                            HStack(spacing: 0) {
                                if horizontalSizeClass == .regular {
                                    LinearGradient(
                                        colors: [Color(.systemBackground), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .frame(width: 300)
                                }
                                Spacer()
                            }
                        }
                        .overlay(alignment: .bottom) {
                            ZStack(alignment: .bottom) {
                                LinearGradient(
                                    colors: [.clear, Color(.systemBackground)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                titleView(foregroundStyle: .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 14)
                            }
                        }
                        .clipped()

                    Group {
                        if let urlString = story.url, let url = URL(string: urlString) {
                            Link(destination: url) { heroContent }
                        } else {
                            heroContent
                        }
                    }
                }

                // MARK: Title + body + metadata
                VStack(alignment: .leading, spacing: 10) {
                    if previewImage == nil {
                        titleView(foregroundStyle: .primary)
                    }

                    if let bodyText = story.bodyText, !bodyText.isEmpty {
                        LinkedText(HNComment.parseHTML(bodyText))
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
                    LazyVStack(alignment: .leading, spacing: 4) {
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
                        }
                    }
                }

            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .ignoresSafeArea(edges: allowsTopHeroBleed ? .top : [])
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(allowsTopHeroBleed ? .hidden : .visible, for: .navigationBar)
        .task(id: story.id) {
            async let imageTask: Void = loadImage()
            async let commentsTask: Void = loadComments()
            _ = await (imageTask, commentsTask)
        }
    }

    private func loadImage() async {
        previewImage = nil
        guard let url = story.url else { return }
        previewImage = await OGImageCache.shared.fetch(url: url)
    }

    @ViewBuilder
    private func titleView(foregroundStyle: Color) -> some View {
        let titleContent = Text(
            "\(Text(story.title).font(.title2.weight(.bold)))\(story.url != nil ? Text(" \(Image(systemName: "arrow.up.right"))").font(.footnote.weight(.semibold)) : Text(""))"
        )
        .foregroundStyle(foregroundStyle)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)

        if let urlString = story.url, let url = URL(string: urlString) {
            Link(destination: url) {
                titleContent
            }
        } else {
            titleContent
        }
    }

    private func loadComments() async {
        comments = []
        collapsedIDs.removeAll()
        isLoadingComments = true
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
    @Environment(\.colorScheme) private var colorScheme

    private var isOP: Bool { comment.author == opAuthor }
    private var depth: Int { min(comment.depth, 4) }
    private var leadingPad: CGFloat { 16 + CGFloat(depth) * 12 }
    private var guideLeadingPad: CGFloat { depth > 0 ? 16 + CGFloat(depth - 1) * 12 + 5 : 0 }
    private let tintCornerRadius: CGFloat = 14
    private var backgroundTint: Color {
        guard depth > 0, depth % 2 == 1 else { return .clear }
        return Color(uiColor: .quaternarySystemFill).opacity(0.25)
    }
    private var guideTint: Color { pastelCommentColor(for: comment.author) }
    private var authorTint: Color {
        colorScheme == .light ? guideTint.mix(with: .black, amount: 0.38) : guideTint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header — tapping this collapses/expands
            HStack(alignment: .center, spacing: 4) {
                Text(isOP ? "(OP) \(comment.author)" : comment.author)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isCollapsed ? authorTint.opacity(0.55) : authorTint)
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
                LinkedText(comment.body)
            }
        }
        .padding(.leading, leadingPad)
        .padding(.trailing, 16)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: guideLeadingPad)
                RoundedRectangle(cornerRadius: tintCornerRadius, style: .continuous)
                    .fill(backgroundTint)
            }
        }
        .overlay(alignment: .leading) {
            if depth > 0 {
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: guideLeadingPad)
                    Rectangle()
                        .fill(guideTint.opacity(colorScheme == .light ? 0.95 : 0.9))
                        .frame(width: 1.5)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 4)
                .mask {
                    HStack(spacing: 0) {
                        Color.clear
                            .frame(width: guideLeadingPad)
                        RoundedRectangle(cornerRadius: tintCornerRadius, style: .continuous)
                    }
                }
            }
        }
    }
}

func pastelCommentColor(for author: String) -> Color {
    let palette: [Color] = [
        Color(red: 0.67, green: 0.76, blue: 0.86),
        Color(red: 0.63, green: 0.80, blue: 0.74),
        Color(red: 0.78, green: 0.72, blue: 0.88),
        Color(red: 0.87, green: 0.73, blue: 0.67),
        Color(red: 0.78, green: 0.80, blue: 0.64),
        Color(red: 0.68, green: 0.73, blue: 0.84),
        Color(red: 0.82, green: 0.69, blue: 0.78),
        Color(red: 0.69, green: 0.81, blue: 0.83),
        Color(red: 0.84, green: 0.77, blue: 0.66),
        Color(red: 0.74, green: 0.74, blue: 0.85)
    ]
    let hash = author.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
    return palette[abs(hash) % palette.count]
}

// MARK: - Linked Text (native link previews on long press)

struct LinkedText: UIViewRepresentable {
    let attributedString: AttributedString
    let font: UIFont
    let textColor: UIColor
    let linkColor: UIColor
    @Environment(\.openURL) private var openURL

    init(_ attributedString: AttributedString,
         font: UIFont = .systemFont(ofSize: 15),
         textColor: UIColor = .label,
         linkColor: UIColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)) {
        self.attributedString = attributedString
        self.font = font
        self.textColor = textColor
        self.linkColor = linkColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(openURL: openURL)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.linkTextAttributes = [.foregroundColor: linkColor]
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.openURL = openURL
        let nsAttr = NSMutableAttributedString(attributedString)
        nsAttr.addAttributes(
            [.font: font, .foregroundColor: textColor],
            range: NSRange(location: 0, length: nsAttr.length)
        )
        textView.attributedText = nsAttr
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var openURL: OpenURLAction

        init(openURL: OpenURLAction) {
            self.openURL = openURL
        }

        func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            if interaction == .invokeDefaultAction {
                openURL(url)
                return false
            }
            return true // allow long-press preview
        }
    }
}

private extension Color {
    func mix(with other: Color, amount: Double) -> Color {
        let t = max(0, min(amount, 1))
        let lhs = UIColor(self)
        let rhs = UIColor(other)

        var lr: CGFloat = 0
        var lg: CGFloat = 0
        var lb: CGFloat = 0
        var la: CGFloat = 0
        var rr: CGFloat = 0
        var rg: CGFloat = 0
        var rb: CGFloat = 0
        var ra: CGFloat = 0

        guard lhs.getRed(&lr, green: &lg, blue: &lb, alpha: &la),
              rhs.getRed(&rr, green: &rg, blue: &rb, alpha: &ra) else {
            return self
        }

        return Color(
            red: lr + (rr - lr) * t,
            green: lg + (rg - lg) * t,
            blue: lb + (rb - lb) * t,
            opacity: la + (ra - la) * t
        )
    }
}

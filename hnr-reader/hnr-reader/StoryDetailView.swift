//
//  StoryDetailView.swift
//  hnr-reader
//

import SwiftUI

struct StoryDetailView: View {
    let story: HNStory
    private let closingSpacerHeight: CGFloat = 14

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var previewImage: UIImage?
    @State private var isLoadingImage = true
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

    private var showsHero: Bool { story.url != nil && (isLoadingImage || previewImage != nil) }
    private var allowsTopHeroBleed: Bool { showsHero }

    var body: some View {
        ScrollView {
            // frame(maxWidth: .infinity) is required — without it, ScrollView proposes
            // an unconstrained width to the VStack, breaking all child padding/wrapping.
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Hero image
                if showsHero {
                    let heroContent = Color(.secondarySystemBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 360)
                        .overlay {
                            if let img = previewImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: previewImage != nil)
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
                    if !showsHero {
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
                    .font(.subheadline.weight(.medium))

                    HStack(spacing: 5) {
                        Text("\(story.score) pts")
                        Text("·").foregroundStyle(Color(uiColor: .quaternaryLabel))
                        Text("\(story.commentsCount) comments")
                        Text("·").foregroundStyle(Color(uiColor: .quaternaryLabel))
                        Text(story.timeAgo)
                    }
                    .font(.subheadline)
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
                    let visible = visibleComments
                    let allLayers = buildTintLayers(for: visible)
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(visible.enumerated()), id: \.element.id) { index, comment in
                            let nextDepth = index + 1 < visible.count ? min(visible[index + 1].depth, 4) : -1
                            VStack(spacing: 0) {
                                if comment.depth == 0 {
                                    Color.clear.frame(height: 10)
                                } else if index > 0 && visible[index - 1].depth >= comment.depth {
                                    let parentLayers = allLayers[index].filter { $0.depth < comment.depth }
                                    CommentTintSpacer(
                                        height: 14,
                                        tintLayers: parentLayers
                                    )
                                }
                                CommentRowView(
                                    comment: comment,
                                    opAuthor: story.author,
                                    tintLayers: allLayers[index],
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

                                if nextDepth < comment.depth {
                                    let closingLayerGroups = buildClosingTintLayerGroups(
                                        currentDepth: min(comment.depth, 4),
                                        nextDepth: nextDepth
                                    )
                                    ForEach(Array(closingLayerGroups.enumerated()), id: \.offset) { _, closingLayers in
                                        CommentTintSpacer(
                                            height: closingSpacerHeight,
                                            tintLayers: closingLayers
                                        )
                                    }
                                }
                            }
                            .transition(.modifier(
                                active: CommentBodyTransition(opacity: 0, blur: 5),
                                identity: CommentBodyTransition(opacity: 1, blur: 0)
                            ))
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
        isLoadingImage = true
        guard let url = story.url else {
            isLoadingImage = false
            return
        }
        previewImage = await OGImageCache.shared.fetch(url: url)
        isLoadingImage = false
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

    private func buildTintLayers(for visible: [HNComment]) -> [[CommentTintLayer]] {
        var result: [[CommentTintLayer]] = []

        for (index, comment) in visible.enumerated() {
            let depth = min(comment.depth, 4)
            let nextDepth = index + 1 < visible.count ? min(visible[index + 1].depth, 4) : -1

            var layers: [CommentTintLayer] = []
            for d in 0...depth {
                layers.append(CommentTintLayer(
                    depth: d,
                    roundTop: d == depth,
                    roundBottom: d == depth && nextDepth <= depth
                ))
            }
            result.append(layers)
        }

        return result
    }

    private func buildClosingTintLayerGroups(
        currentDepth: Int,
        nextDepth: Int
    ) -> [[CommentTintLayer]] {
        guard currentDepth > 0 else { return [] }

        let lowestClosingDepth = max(nextDepth, 0)
        guard lowestClosingDepth <= currentDepth - 1 else { return [] }

        return stride(from: currentDepth - 1, through: lowestClosingDepth, by: -1).map { closingDepth in
            (0...closingDepth).map { depth in
                CommentTintLayer(
                    depth: depth,
                    roundTop: false,
                    roundBottom: depth == closingDepth
                )
            }
        }
    }

    @ViewBuilder
    private func actionButton(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 19))
            .foregroundStyle(Color(uiColor: .tertiaryLabel))
            .frame(width: 50, height: 44)
    }
}

// MARK: - Comment Tint Layer

struct CommentTintLayer {
    let depth: Int
    let roundTop: Bool
    let roundBottom: Bool
}

struct CommentTintSpacer: View {
    let height: CGFloat
    let tintLayers: [CommentTintLayer]
    private let threadIndent: CGFloat = 14
    private let rootBubbleEdgeInset: CGFloat = 10

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                ZStack(alignment: .leading) {
                    ForEach(tintLayers, id: \.depth) { layer in
                        let fillColor = commentTintFill(for: layer.depth)
                        let shape = commentBubbleShape(for: layer, cornerRadius: cornerRadius(for: layer.depth))
                        HStack(spacing: 0) {
                            Color.clear.frame(width: outerInset(for: layer.depth))
                            Rectangle()
                                .fill(fillColor)
                                .clipShape(shape)
                            Color.clear.frame(width: outerInset(for: layer.depth))
                        }
                    }
                }
            }
    }

    private func outerInset(for depth: Int) -> CGFloat {
        rootBubbleEdgeInset + CGFloat(depth) * threadIndent
    }

    private func cornerRadius(for depth: Int) -> CGFloat {
        commentCornerRadius(for: depth, threadIndent: threadIndent)
    }
}

// MARK: - Comment Row

struct CommentRowView: View {
    let comment: HNComment
    let opAuthor: String
    var tintLayers: [CommentTintLayer] = []
    var isCollapsed: Bool = false
    var onToggleCollapse: (() -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme

    private var isOP: Bool { comment.author == opAuthor }
    private var depth: Int { min(comment.depth, 4) }
    private let threadIndent: CGFloat = 14
    private let rootBubbleEdgeInset: CGFloat = 10
    private let bubbleHorizontalPadding: CGFloat = 14
    private let bubbleVerticalPadding: CGFloat = 9
    private var leadingPad: CGFloat {
        outerInset(for: depth) + bubbleHorizontalPadding
    }
    private var trailingPad: CGFloat {
        outerInset(for: depth) + bubbleHorizontalPadding
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
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isCollapsed ? authorTint.opacity(0.55) : authorTint)
                    .lineLimit(1)

                Text(comment.timeAgo)
                    .font(.caption)
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    .layoutPriority(1)

                Image(systemName: "chevron.forward")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    .rotationEffect(.degrees(isCollapsed ? 0 : 90))
            }
            .contentShape(Rectangle())
            .onTapGesture { onToggleCollapse?() }

            // Body — fades and blurs when collapsing
            if !isCollapsed {
                LinkedText(comment.body)
                    .transition(.modifier(
                        active: CommentBodyTransition(opacity: 0, blur: 5),
                        identity: CommentBodyTransition(opacity: 1, blur: 0)
                    ))
            }
        }
        .padding(.leading, leadingPad)
        .padding(.trailing, trailingPad)
        .padding(.vertical, bubbleVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .leading) {
                ForEach(tintLayers, id: \.depth) { layer in
                    let shape = bubbleShape(for: layer)
                    let fillColor = commentTintFill(for: layer.depth)
                    HStack(spacing: 0) {
                        Color.clear.frame(width: outerInset(for: layer.depth))
                        Rectangle()
                            .fill(fillColor)
                            .clipShape(shape)
                        Color.clear.frame(width: outerInset(for: layer.depth))
                    }
                }
            }
        }
    }

    private func bubbleShape(for layer: CommentTintLayer) -> UnevenRoundedRectangle {
        commentBubbleShape(for: layer, cornerRadius: cornerRadius(for: layer.depth))
    }

    private func outerInset(for depth: Int) -> CGFloat {
        rootBubbleEdgeInset + CGFloat(depth) * threadIndent
    }

    private func cornerRadius(for depth: Int) -> CGFloat {
        commentCornerRadius(for: depth, threadIndent: threadIndent)
    }
}

private func commentBubbleShape(for layer: CommentTintLayer, cornerRadius: CGFloat) -> UnevenRoundedRectangle {
    UnevenRoundedRectangle(
        topLeadingRadius: layer.roundTop ? cornerRadius : 0,
        bottomLeadingRadius: layer.roundBottom ? cornerRadius : 0,
        bottomTrailingRadius: layer.roundBottom ? cornerRadius : 0,
        topTrailingRadius: layer.roundTop ? cornerRadius : 0,
        style: .continuous
    )
}

private func commentCornerRadius(for depth: Int, threadIndent: CGFloat) -> CGFloat {
    let rootCornerRadius: CGFloat = 18
    let radiusDropPerLevel = threadIndent * 0.4
    return max(6, rootCornerRadius - CGFloat(depth) * radiusDropPerLevel)
}

private func commentTintFill(for depth: Int) -> Color {
    depth.isMultiple(of: 2) ? Color(uiColor: .quaternarySystemFill) : Color(uiColor: .systemBackground)
}

struct CommentBodyTransition: ViewModifier {
    let opacity: Double
    let blur: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .blur(radius: blur)
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
    let textStyle: UIFont.TextStyle
    let textColor: UIColor
    let linkColor: UIColor
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(_ attributedString: AttributedString,
         textStyle: UIFont.TextStyle = .body,
         textColor: UIColor = .label,
         linkColor: UIColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)) {
        self.attributedString = attributedString
        self.textStyle = textStyle
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
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.linkTextAttributes = [.foregroundColor: linkColor]
        return textView
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        let size = uiView.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        return CGSize(width: width, height: size.height)
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        _ = dynamicTypeSize
        context.coordinator.openURL = openURL
        let resolvedFont = UIFont.preferredFont(forTextStyle: textStyle, compatibleWith: textView.traitCollection)
        let nsAttr = NSMutableAttributedString(attributedString)
        nsAttr.addAttributes(
            [.font: resolvedFont, .foregroundColor: textColor],
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

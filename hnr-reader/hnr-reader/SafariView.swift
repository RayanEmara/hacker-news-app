//
//  SafariView.swift
//  hnr-reader
//

import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true
        config.barCollapsingEnabled = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = .orange
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - View modifier that intercepts all link opens

struct InAppBrowserModifier: ViewModifier {
    @State private var safariURL: URL?

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                safariURL = url
                return .handled
            })
            .fullScreenCover(item: $safariURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea()
            }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

extension View {
    func openLinksInApp() -> some View {
        modifier(InAppBrowserModifier())
    }
}

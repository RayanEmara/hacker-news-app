//
//  SafariView.swift
//  hnr-reader
//

import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    var readerMode: Bool = true

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = readerMode
        config.barCollapsingEnabled = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = .orange
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - View modifier that intercepts all link opens

struct InAppBrowserModifier: ViewModifier {
    @AppStorage("useInAppBrowser") private var useInAppBrowser = true
    @AppStorage("useReaderMode") private var useReaderMode = true
    @State private var safariURL: URL?

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                if useInAppBrowser {
                    safariURL = url
                    return .handled
                }
                return .systemAction
            })
            .fullScreenCover(item: $safariURL) { url in
                SafariView(url: url, readerMode: useReaderMode)
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

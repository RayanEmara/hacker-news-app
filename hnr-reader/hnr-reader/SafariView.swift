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
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - View modifier that intercepts all link opens

struct InAppBrowserModifier: ViewModifier {
    @AppStorage("useInAppBrowser") private var useInAppBrowser = true
    @AppStorage("useReaderMode") private var useReaderMode = true
    @AppStorage("readerModeExceptionDomains") private var readerModeExceptionDomainsRaw = ""
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
                SafariView(url: url, readerMode: shouldUseReaderMode(for: url))
                    .ignoresSafeArea()
            }
    }

    private func shouldUseReaderMode(for url: URL) -> Bool {
        let hasOverride = readerModeExceptionDomains.contains { $0.matches(host: url.host) }
        return hasOverride ? !useReaderMode : useReaderMode
    }

    private var readerModeExceptionDomains: [String] {
        readerModeExceptionDomainsRaw
            .split(separator: "\n")
            .map { String($0) }
            .filter { !$0.isEmpty }
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

func normalizeDomain(_ value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !trimmed.isEmpty else { return nil }

    let hostCandidate: String
    if let url = URL(string: trimmed), let host = url.host {
        hostCandidate = host
    } else if let url = URL(string: "https://\(trimmed)"), let host = url.host {
        hostCandidate = host
    } else {
        hostCandidate = trimmed
    }

    let sanitized = hostCandidate
        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        .replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)

    return sanitized.isEmpty ? nil : sanitized
}

private extension String {
    func matches(host: String?) -> Bool {
        guard let normalizedSelf = normalizeDomain(self),
              let normalizedHost = host.flatMap(normalizeDomain) else { return false }
        return normalizedHost == normalizedSelf || normalizedHost.hasSuffix(".\(normalizedSelf)")
    }
}

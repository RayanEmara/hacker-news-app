//
//  SettingsView.swift
//  hnr-reader
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("useInAppBrowser") private var useInAppBrowser = true
    @AppStorage("useReaderMode") private var useReaderMode = true
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage("readerModeExceptionDomains") private var readerModeExceptionDomainsRaw = ""
    @State private var showClearCacheConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Theme", selection: $appColorScheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Toggle("In-App Browser", isOn: $useInAppBrowser)
                    Toggle("Reader Mode by Default", isOn: $useReaderMode)
                        .disabled(!useInAppBrowser)
                    NavigationLink {
                        ReaderModeExceptionsView()
                    } label: {
                        HStack {
                            Text("Reader Mode Exceptions")
                            Spacer()
                            Text("\(readerModeExceptionDomains.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!useInAppBrowser)
                } header: {
                    Text("Browser")
                } footer: {
                    if !useInAppBrowser {
                        Text("Reader mode is only available with the in-app browser.")
                    }
                }

                Section("About") {
                    LabeledContent("Version") {
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Clear Read History", role: .destructive) {
                        showClearCacheConfirmation = true
                    }
                } header: {
                    Text("Storage")
                } footer: {
                    Text("Removes the list of posts marked as already read.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear Read History?", isPresented: $showClearCacheConfirmation) {
                Button("Clear", role: .destructive) {
                    ReadHistory.shared.clear()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This resets the app's read-post cache.")
            }
        }
    }

    private var readerModeExceptionDomains: [String] {
        readerModeExceptionDomainsRaw
            .split(separator: "\n")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }
}

struct ReaderModeExceptionsView: View {
    @AppStorage("readerModeExceptionDomains") private var readerModeExceptionDomainsRaw = ""
    @State private var newReaderModeDomain = ""

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("example.com", text: $newReaderModeDomain)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Button("Add") {
                        addReaderModeDomain()
                    }
                    .disabled(normalizeDomain(newReaderModeDomain) == nil)
                }
            } header: {
                Text("Overrides")
            } footer: {
                Text("Add a domain or paste a URL. Matching includes subdomains, and listed sites invert the default reader mode setting.")
            }

            Section {
                if readerModeExceptionDomains.isEmpty {
                    Text("No exceptions yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(readerModeExceptionDomains, id: \.self) { domain in
                        HStack {
                            Text(domain)
                            Spacer()
                            Button(role: .destructive) {
                                removeReaderModeDomain(domain)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle("Reader Exceptions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var readerModeExceptionDomains: [String] {
        readerModeExceptionDomainsRaw
            .split(separator: "\n")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }

    private func addReaderModeDomain() {
        guard let domain = normalizeDomain(newReaderModeDomain) else { return }
        let updated = Set(readerModeExceptionDomains).union([domain]).sorted()
        readerModeExceptionDomainsRaw = updated.joined(separator: "\n")
        newReaderModeDomain = ""
    }

    private func removeReaderModeDomain(_ domain: String) {
        let updated = readerModeExceptionDomains.filter { $0 != domain }
        readerModeExceptionDomainsRaw = updated.joined(separator: "\n")
    }
}

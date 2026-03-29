//
//  SettingsView.swift
//  hnr-reader
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("useInAppBrowser") private var useInAppBrowser = true
    @AppStorage("useReaderMode") private var useReaderMode = true
    @AppStorage("appColorScheme") private var appColorScheme = "system"

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
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

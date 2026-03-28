//
//  hnr_readerApp.swift
//  hnr-reader
//
//  Created by Rayan Emara on 28/03/2026.
//

import SwiftUI
import UIKit

@main
struct hnr_readerApp: App {
    init() {
        let serifDescriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.serif)!
            .withSymbolicTraits(.traitBold)!
        let serifFont = UIFont(descriptor: serifDescriptor, size: 0)

        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: serifFont
        ]
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .openLinksInApp()
        }
    }
}

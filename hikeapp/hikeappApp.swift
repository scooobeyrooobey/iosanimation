//
//  hikeappApp.swift
//  hikeapp
//

import SwiftUI
import CoreText

@main
struct hikeappApp: App {
    init() {
        FontRegistry.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Force dark appearance at the root so iOS 26 Liquid Glass resolves
                // to its dark variant immediately — prevents the white-flash artefact
                // that appears when `.glassEffect` samples the system light material
                // during the first render / transition frames.
                .preferredColorScheme(.dark)
        }
    }
}

enum FontRegistry {
    /// Registers custom .otf/.ttf files shipped in the bundle (anywhere inside it).
    /// Alternative to editing Info.plist `UIAppFonts`.
    static func registerBundledFonts() {
        let fm = FileManager.default
        guard let resourceURL = Bundle.main.resourceURL else { return }
        guard let enumerator = fm.enumerator(at: resourceURL,
                                             includingPropertiesForKeys: nil,
                                             options: [.skipsHiddenFiles]) else { return }
        for case let url as URL in enumerator {
            let ext = url.pathExtension.lowercased()
            guard ext == "otf" || ext == "ttf" else { continue }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                if let err = error?.takeRetainedValue() {
                    print("Font register failed for \(url.lastPathComponent): \(err)")
                }
            }
        }
    }
}

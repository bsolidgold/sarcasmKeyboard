import XCTest
import SwiftUI
@testable import SarcasmKit

#if canImport(AppKit)
import AppKit
#endif

final class IconRendererTests: XCTestCase {
    /// Runs only when RENDER_ICON=1. Emits three PNGs into the asset catalog.
    @MainActor
    func testRenderAppIconVariants() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["RENDER_ICON"] == "1",
            "Set RENDER_ICON=1 to render app icon PNGs."
        )

        let outputDir = Self.assetCatalogDirectory()
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        try renderPNG(IconView(variant: .primary), to: outputDir.appendingPathComponent("AppIcon-1024.png"))
        // Dark is identical to primary — our icon is already dark-native. iOS uses it under Dark appearance.
        try renderPNG(IconView(variant: .primary), to: outputDir.appendingPathComponent("AppIcon-Dark-1024.png"))
        try renderPNG(IconView(variant: .tinted),  to: outputDir.appendingPathComponent("AppIcon-Tinted-1024.png"))
    }

    @MainActor
    private func renderPNG<V: View>(_ view: V, to url: URL) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        guard let cgImage = renderer.cgImage else {
            throw NSError(domain: "IconRenderer", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "ImageRenderer returned nil for \(url.lastPathComponent)"])
        }
        #if canImport(AppKit)
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "IconRenderer", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "PNG encoding failed for \(url.lastPathComponent)"])
        }
        try data.write(to: url)
        #else
        throw NSError(domain: "IconRenderer", code: 3,
                      userInfo: [NSLocalizedDescriptionKey: "PNG encoding requires AppKit (macOS)."])
        #endif
    }

    /// Resolves the asset-catalog output directory relative to this source file.
    private static func assetCatalogDirectory() -> URL {
        let thisFile = URL(fileURLWithPath: #filePath)
        // Tests/SarcasmKitTests/IconRendererTests.swift → repo root is three levels up
        let repoRoot = thisFile.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return repoRoot
            .appendingPathComponent("SarcasmKeyboard")
            .appendingPathComponent("Assets.xcassets")
            .appendingPathComponent("AppIcon.appiconset")
    }
}

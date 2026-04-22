import XCTest
#if canImport(UIKit)
import UIKit
#endif
@testable import SarcasmKit

final class ThemeCatalogTests: XCTestCase {

    func testExactlyTenThemes() {
        XCTAssertEqual(ThemeCatalog.allThemes.count, 10)
    }

    func testThemeOrder() {
        let ids = ThemeCatalog.allThemes.map(\.id)
        XCTAssertEqual(ids, [
            "acid", "cleanLight", "cleanDark",
            "neon", "vaporwave", "terminalGreen",
            "sunset", "paper", "y2k", "highlighter"
        ])
    }

    func testFreeThemesNotPremium() {
        let free = ThemeCatalog.allThemes.prefix(3)
        XCTAssert(free.allSatisfy { !$0.isPremium }, "First three themes must be free")
    }

    func testProThemesArePremium() {
        let pro = ThemeCatalog.allThemes.dropFirst(3)
        XCTAssert(pro.allSatisfy { $0.isPremium }, "Last seven themes must be Pro")
    }

    func testAllThemesHaveNonTransparentKeyboardTokens() throws {
        #if canImport(UIKit)
        for theme in ThemeCatalog.allThemes {
            let p = theme.palette
            let inkAlpha    = UIColor(p.ink).cgColor.alpha
            let fillAlpha   = UIColor(p.keyFill).cgColor.alpha
            let accentAlpha = UIColor(p.accent).cgColor.alpha
            XCTAssertGreaterThan(inkAlpha,    0, "\(theme.id): ink is transparent")
            XCTAssertGreaterThan(fillAlpha,   0, "\(theme.id): keyFill is transparent")
            XCTAssertGreaterThan(accentAlpha, 0, "\(theme.id): accent is transparent")
        }
        #else
        throw XCTSkip("UIKit not available on this platform")
        #endif
    }

    func testThemeLookupByID() {
        XCTAssertNotNil(ThemeCatalog.theme(id: "acid"))
        XCTAssertNil(ThemeCatalog.theme(id: "nonexistent"))
    }

    func testAcidPaletteDefaultAlias() {
        let acid = ThemeCatalog.acid.palette
        let def  = Palette.default
        XCTAssertEqual(acid, def)
    }
}

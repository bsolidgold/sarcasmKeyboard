import XCTest
@testable import SarcasmKit

final class SharedDefaultsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        SharedDefaults.defaults.removeObject(forKey: "sarcasm.selectedPatternID")
    }

    func testDefaultsToAlternatingWhenUnset() {
        XCTAssertEqual(SharedDefaults.selectedPatternID, "alternating")
    }

    func testRoundTrip() {
        SharedDefaults.selectedPatternID = "spongebob"
        XCTAssertEqual(SharedDefaults.selectedPatternID, "spongebob")
    }

    func testSelectedPatternResolves() {
        SharedDefaults.selectedPatternID = "smallCaps"
        XCTAssertEqual(SharedDefaults.selectedPattern.id, "smallCaps")
    }

    func testInvalidIDFallsBackToAlternating() {
        SharedDefaults.defaults.setValue("nonsense", forKey: "sarcasm.selectedPatternID")
        XCTAssertEqual(SharedDefaults.selectedPattern.id, "alternating")
    }

    // MARK: selectedThemeID

    func testSelectedThemeIDDefaultsToAcid() {
        SharedDefaults.defaults.removeObject(forKey: "sarcasm.selectedThemeID")
        XCTAssertEqual(SharedDefaults.selectedThemeID, "acid")
    }

    func testSelectedThemeIDRoundTrip() {
        SharedDefaults.defaults.removeObject(forKey: "sarcasm.selectedThemeID")
        SharedDefaults.selectedThemeID = "neon"
        XCTAssertEqual(SharedDefaults.selectedThemeID, "neon")
    }

    func testSelectedThemeResolvesTheme() {
        SharedDefaults.selectedThemeID = "terminalGreen"
        XCTAssertEqual(SharedDefaults.selectedTheme.id, "terminalGreen")
    }

    func testInvalidThemeIDFallsBackToAcid() {
        SharedDefaults.defaults.setValue("bogus", forKey: "sarcasm.selectedThemeID")
        XCTAssertEqual(SharedDefaults.selectedTheme.id, "acid")
    }
}

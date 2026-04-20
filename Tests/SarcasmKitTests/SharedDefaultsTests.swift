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
}

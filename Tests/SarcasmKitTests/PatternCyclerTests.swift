import XCTest
@testable import SarcasmKit

final class PatternCyclerTests: XCTestCase {
    func testCyclesToNextFreePattern() {
        let patterns = SarcasmEngine.allPatterns
        let next = PatternCycler.next(currentID: "alternating", in: patterns)
        XCTAssertEqual(next, "spongebob")
    }

    func testSkipsPremiumPatterns() {
        let patterns = SarcasmEngine.allPatterns
        // wordToggle is free; next free after wordToggle must skip smallCaps (pro) and zalgo (pro)
        // so it must wrap back to alternating.
        let next = PatternCycler.next(currentID: "wordToggle", in: patterns)
        XCTAssertEqual(next, "alternating")
    }

    func testWrapsAtEndOfFreeList() {
        let patterns = SarcasmEngine.allPatterns
        // Assume free-list ends at wordToggle; start from last free pattern → wrap.
        let lastFreeID = patterns.last(where: { !$0.isPremium })?.id ?? ""
        let next = PatternCycler.next(currentID: lastFreeID, in: patterns)
        let firstFreeID = patterns.first(where: { !$0.isPremium })?.id ?? ""
        XCTAssertEqual(next, firstFreeID)
    }

    func testUnknownCurrentIDReturnsFirstFree() {
        let patterns = SarcasmEngine.allPatterns
        let next = PatternCycler.next(currentID: "nonexistent", in: patterns)
        let firstFreeID = patterns.first(where: { !$0.isPremium })?.id ?? ""
        XCTAssertEqual(next, firstFreeID)
    }

    func testCurrentIsPremiumFallsThroughToFirstFree() {
        let patterns = SarcasmEngine.allPatterns
        let next = PatternCycler.next(currentID: "smallCaps", in: patterns)
        let firstFreeID = patterns.first(where: { !$0.isPremium })?.id ?? ""
        XCTAssertEqual(next, firstFreeID)
    }

    func testEmptyFreeListReturnsCurrent() {
        let next = PatternCycler.next(currentID: "alternating", in: [SmallCapsPattern(), ZalgoPattern()])
        XCTAssertEqual(next, "alternating")
    }
}

import XCTest
@testable import SarcasmKit

final class UwuPatternTests: XCTestCase {
    private let pattern = UwuPattern()

    func testEmptyString() {
        XCTAssertEqual(pattern.transform(""), "")
    }

    func testWhitespaceOnlyIsUnchanged() {
        XCTAssertEqual(pattern.transform("   "), "   ")
    }

    func testRSubstitution() {
        let out = pattern.transform("r")
        XCTAssertTrue(out.hasPrefix("w"), "r should become w, got \(out)")
    }

    func testLSubstitution() {
        let out = pattern.transform("l")
        XCTAssertTrue(out.hasPrefix("w"), "l should become w, got \(out)")
    }

    func testUppercaseRSubstitution() {
        let out = pattern.transform("R")
        XCTAssertTrue(out.hasPrefix("W"), "R should become W, got \(out)")
    }

    func testUppercaseLSubstitution() {
        let out = pattern.transform("L")
        XCTAssertTrue(out.hasPrefix("W"), "L should become W, got \(out)")
    }

    func testNABecomesNYA() {
        let out = pattern.transform("na")
        XCTAssertTrue(out.hasPrefix("nya"), "na should become nya, got \(out)")
    }

    func testNOBecomesNYO() {
        let out = pattern.transform("no")
        XCTAssertTrue(out.hasPrefix("nyo"), "no should become nyo, got \(out)")
    }

    func testUppercaseNVowel() {
        let out = pattern.transform("Na")
        XCTAssertTrue(out.hasPrefix("Nya"), "Na should become Nya, got \(out)")
    }

    func testSuffixIsAppended() {
        let out = pattern.transform("hello")
        let validSuffixes = [" owo", " uwu", " :3", " >w<", "~"]
        XCTAssertTrue(validSuffixes.contains(where: { out.hasSuffix($0) }),
                      "Output should end with a UwU suffix, got \(out)")
    }

    func testDeterminism() {
        let a = pattern.transform("hello world")
        let b = pattern.transform("hello world")
        XCTAssertEqual(a, b, "transform must be deterministic")
    }

    func testEmojiPassThrough() {
        let out = pattern.transform("hi 🐱")
        XCTAssertTrue(out.contains("🐱"))
    }

    // transformCharacter

    func testTransformCharRBecomesW() {
        XCTAssertEqual(pattern.transformCharacter("r", priorContext: ""), "w")
    }

    func testTransformCharLBecomesW() {
        XCTAssertEqual(pattern.transformCharacter("l", priorContext: ""), "w")
    }

    func testTransformCharAfterNAndVowelInsertsY() {
        XCTAssertEqual(pattern.transformCharacter("a", priorContext: "n"), "ya")
    }

    func testTransformCharAfterUpperNAndVowel() {
        XCTAssertEqual(pattern.transformCharacter("o", priorContext: "N"), "yo")
    }

    func testTransformCharNoYWhenNotAfterN() {
        XCTAssertEqual(pattern.transformCharacter("a", priorContext: "h"), "a")
    }

    func testMetadata() {
        XCTAssertEqual(pattern.id, "uwu")
        XCTAssertTrue(pattern.isPremium)
    }
}

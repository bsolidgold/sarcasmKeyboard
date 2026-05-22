import XCTest
@testable import SarcasmKit

final class UpsideDownPatternTests: XCTestCase {
    private let pattern = UpsideDownPattern()

    func testEmptyString() {
        XCTAssertEqual(pattern.transform(""), "")
    }

    func testSingleLetter() {
        XCTAssertEqual(pattern.transform("a"), "ɐ")
        XCTAssertEqual(pattern.transform("h"), "ɥ")
    }

    func testStringIsReversed() {
        // "ab" → flip(a)=ɐ, flip(b)=q → reversed → "qɐ"
        XCTAssertEqual(pattern.transform("ab"), "qɐ")
    }

    func testHelloWorldFlippedAndReversed() {
        let out = pattern.transform("hello")
        XCTAssertEqual(out, "oʟʟǝɥ")
    }

    func testPunctuationFlipped() {
        XCTAssertEqual(pattern.transform("?"), "¿")
        XCTAssertEqual(pattern.transform("!"), "¡")
    }

    func testParenthesesFlipped() {
        // flip: ( → ), a → ɐ, ) → (  →  reverse: ( ɐ ) → "(ɐ)"
        XCTAssertEqual(pattern.transform("(a)"), "(ɐ)")
    }

    func testNonMappedCharactersPassThrough() {
        // digits, emoji etc. pass through
        let out = pattern.transform("1")
        XCTAssertEqual(out, "1")
    }

    func testEmojiPassThrough() {
        let out = pattern.transform("hi 🙃")
        XCTAssertTrue(out.contains("🙃"))
    }

    func testDeterminism() {
        XCTAssertEqual(pattern.transform("Hello World"), pattern.transform("Hello World"))
    }

    func testUppercaseMapping() {
        XCTAssertEqual(pattern.transform("A"), "∀")
        XCTAssertEqual(pattern.transform("M"), "W")
        XCTAssertEqual(pattern.transform("W"), "M")
    }

    // transformCharacter — no reversal, just per-character flip

    func testTransformCharNoReversal() {
        // In live mode, each character is flipped but NOT reversed
        XCTAssertEqual(pattern.transformCharacter("h", priorContext: ""), "ɥ")
        XCTAssertEqual(pattern.transformCharacter("i", priorContext: ""), "ᴉ")
    }

    func testTransformCharNonMapped() {
        XCTAssertEqual(pattern.transformCharacter("3", priorContext: ""), "3")
    }

    func testTransformCharPunctuation() {
        XCTAssertEqual(pattern.transformCharacter("?", priorContext: ""), "¿")
    }

    func testMetadata() {
        XCTAssertEqual(pattern.id, "upsidedown")
        XCTAssertTrue(pattern.isPremium)
    }
}

import XCTest
@testable import SarcasmKit

final class BubblePatternTests: XCTestCase {
    private let pattern = BubblePattern()

    func testEmptyString() {
        XCTAssertEqual(pattern.transform(""), "")
    }

    func testLowercaseA() {
        XCTAssertEqual(pattern.transform("a"), "ⓐ")
    }

    func testUppercaseA() {
        XCTAssertEqual(pattern.transform("A"), "Ⓐ")
    }

    func testDigitZero() {
        XCTAssertEqual(pattern.transform("0"), "⓪")
    }

    func testDigitOne() {
        XCTAssertEqual(pattern.transform("1"), "①")
    }

    func testDigitNine() {
        XCTAssertEqual(pattern.transform("9"), "⑨")
    }

    func testAllLowercaseLetters() {
        let input = "abcdefghijklmnopqrstuvwxyz"
        let out = pattern.transform(input)
        XCTAssertEqual(out, "ⓐⓑⓒⓓⓔⓕⓖⓗⓘⓙⓚⓛⓜⓝⓞⓟⓠⓡⓢⓣⓤⓥⓦⓧⓨⓩ")
    }

    func testAllUppercaseLetters() {
        let input = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let out = pattern.transform(input)
        XCTAssertEqual(out, "ⒶⒷⒸⒹⒺⒻⒼⒽⒾⒿⓀⓁⓂⓃⓄⓅⓆⓇⓈⓉⓊⓋⓌⓍⓎⓏ")
    }

    func testNonAlphanumericPassThrough() {
        XCTAssertEqual(pattern.transform("!?.,"), "!?.,")
    }

    func testSpacePassThrough() {
        XCTAssertEqual(pattern.transform("hello world"), "ⓗⓔⓛⓛⓞ ⓦⓞⓡⓛⓓ")
    }

    func testEmojiPassThrough() {
        let out = pattern.transform("a 🎉 b")
        XCTAssertTrue(out.contains("🎉"))
        XCTAssertTrue(out.hasPrefix("ⓐ"))
    }

    func testDeterminism() {
        XCTAssertEqual(pattern.transform("Hello 123"), pattern.transform("Hello 123"))
    }

    // transformCharacter

    func testTransformCharLowercase() {
        XCTAssertEqual(pattern.transformCharacter("z", priorContext: ""), "ⓩ")
    }

    func testTransformCharUppercase() {
        XCTAssertEqual(pattern.transformCharacter("Z", priorContext: ""), "Ⓩ")
    }

    func testTransformCharDigit() {
        XCTAssertEqual(pattern.transformCharacter("5", priorContext: ""), "⑤")
    }

    func testTransformCharNonAlphanumeric() {
        XCTAssertEqual(pattern.transformCharacter("!", priorContext: ""), "!")
    }

    func testMetadata() {
        XCTAssertEqual(pattern.id, "bubble")
        XCTAssertFalse(pattern.isPremium)
    }
}

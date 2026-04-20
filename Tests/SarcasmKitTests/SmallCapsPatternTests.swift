import XCTest
@testable import SarcasmKit

final class SmallCapsPatternTests: XCTestCase {
    private let pattern = SmallCapsPattern()

    func testBasicLowercase() {
        XCTAssertEqual(pattern.transform("hello"), "ʜᴇʟʟᴏ")
    }

    func testBasicUppercaseAlsoMaps() {
        XCTAssertEqual(pattern.transform("HELLO"), "ʜᴇʟʟᴏ")
    }

    func testMixedCase() {
        XCTAssertEqual(pattern.transform("Hello"), "ʜᴇʟʟᴏ")
    }

    func testEmptyString() {
        XCTAssertEqual(pattern.transform(""), "")
    }

    func testSpacesPassThrough() {
        XCTAssertEqual(pattern.transform("hi there"), "ʜɪ ᴛʜᴇʀᴇ")
    }

    func testPunctuationPassesThrough() {
        XCTAssertEqual(pattern.transform("hi!"), "ʜɪ!")
    }

    func testNumbersPassThrough() {
        XCTAssertEqual(pattern.transform("abc123"), "ᴀʙᴄ123")
    }

    func testEmojiPassThrough() {
        let out = pattern.transform("hi 👋")
        XCTAssertTrue(out.contains("👋"))
    }

    func testAccentedCharactersPassThroughWhenNoMapping() {
        let out = pattern.transform("café")
        XCTAssertTrue(out.contains("é") || out.contains("\u{0301}") || out.contains("E"))
    }

    func testMetadataIsPremium() {
        XCTAssertEqual(pattern.id, "smallCaps")
        XCTAssertTrue(pattern.isPremium)
    }

    func testTransformCharacterLetter() {
        XCTAssertEqual(pattern.transformCharacter("h", priorContext: ""), "ʜ")
    }

    func testTransformCharacterNonLetter() {
        XCTAssertEqual(pattern.transformCharacter("!", priorContext: ""), "!")
        XCTAssertEqual(pattern.transformCharacter(" ", priorContext: "hi"), " ")
    }
}

import XCTest
@testable import SarcasmKit

final class SpongeBobPatternTests: XCTestCase {
    private let pattern = SpongeBobPattern()

    func testIsDeterministic() {
        let a = pattern.transform("hello world this is a sarcastic phrase")
        let b = pattern.transform("hello world this is a sarcastic phrase")
        XCTAssertEqual(a, b)
    }

    func testEmptyString() {
        XCTAssertEqual(pattern.transform(""), "")
    }

    func testPreservesLength() {
        let input = "hello"
        let output = pattern.transform(input)
        XCTAssertEqual(input.count, output.count)
    }

    func testPreservesNonLetterCharacters() {
        let out = pattern.transform("hi, how's it going?!")
        XCTAssertTrue(out.contains(","))
        XCTAssertTrue(out.contains("'"))
        XCTAssertTrue(out.contains("?"))
        XCTAssertTrue(out.contains("!"))
    }

    func testPreservesSpaces() {
        let out = pattern.transform("a b c d")
        XCTAssertEqual(out.count, 7)
        XCTAssertEqual(out.filter { $0 == " " }.count, 3)
    }

    func testLowercaseAndUppercaseInputProduceSameOutput() {
        XCTAssertEqual(pattern.transform("hello"), pattern.transform("HELLO"))
        XCTAssertEqual(pattern.transform("Hello"), pattern.transform("hELLO"))
    }

    func testHasMixOfCases() {
        let out = pattern.transform("this is a reasonably long sarcastic phrase")
        let hasUpper = out.contains { $0.isUppercase }
        let hasLower = out.contains { $0.isLowercase }
        XCTAssertTrue(hasUpper, "Expected at least one uppercase letter")
        XCTAssertTrue(hasLower, "Expected at least one lowercase letter")
    }

    func testEmojiPassesThrough() {
        let out = pattern.transform("hi 👋 world")
        XCTAssertTrue(out.contains("👋"))
    }

    func testTransformCharacterIsConsistent() {
        let a = pattern.transformCharacter("e", priorContext: "h")
        let b = pattern.transformCharacter("e", priorContext: "h")
        XCTAssertEqual(a, b)
    }

    func testTransformCharacterPassesNonLetters() {
        XCTAssertEqual(pattern.transformCharacter(" ", priorContext: "hi"), " ")
    }

    func testMetadata() {
        XCTAssertEqual(pattern.id, "spongebob")
        XCTAssertFalse(pattern.isPremium)
    }
}

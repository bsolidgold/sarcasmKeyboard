import XCTest
@testable import SarcasmKit

final class RandomPatternTests: XCTestCase {
    private let pattern = RandomPattern()

    func testEmptyString() {
        XCTAssertEqual(pattern.transform(""), "")
    }

    func testPreservesLength() {
        XCTAssertEqual(pattern.transform("hello world").count, "hello world".count)
    }

    func testPreservesNonLetters() {
        let out = pattern.transform("a,b!c?")
        XCTAssertTrue(out.contains(","))
        XCTAssertTrue(out.contains("!"))
        XCTAssertTrue(out.contains("?"))
    }

    func testAllOutputsAreLetterForLetterInputs() {
        let input = "abcdefghij"
        let out = pattern.transform(input)
        for c in out {
            XCTAssertTrue(c.isLetter)
        }
    }

    func testHasMixOverLargeInputSample() {
        let input = String(repeating: "a", count: 1000)
        let out = pattern.transform(input)
        let uppers = out.filter { $0.isUppercase }.count
        let lowers = out.filter { $0.isLowercase }.count
        XCTAssertGreaterThan(uppers, 200)
        XCTAssertGreaterThan(lowers, 200)
    }

    func testEmojiPassesThrough() {
        let out = pattern.transform("hi 👋")
        XCTAssertTrue(out.contains("👋"))
    }

    func testTransformCharacterPassesNonLetters() {
        XCTAssertEqual(pattern.transformCharacter(" ", priorContext: "hi"), " ")
        XCTAssertEqual(pattern.transformCharacter("!", priorContext: "hi"), "!")
    }

    func testTransformCharacterLetterIsLetter() {
        let out = pattern.transformCharacter("x", priorContext: "abc")
        XCTAssertTrue(out.first!.isLetter)
        XCTAssertEqual(out.count, 1)
    }

    func testMetadata() {
        XCTAssertEqual(pattern.id, "random")
        XCTAssertFalse(pattern.isPremium)
    }
}

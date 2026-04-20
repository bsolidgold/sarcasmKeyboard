import XCTest
@testable import SarcasmKit

final class WordTogglePatternTests: XCTestCase {
    private let pattern = WordTogglePattern()

    func testTwoWords() {
        XCTAssertEqual(pattern.transform("hello world"), "hello WORLD")
    }

    func testThreeWords() {
        XCTAssertEqual(pattern.transform("hello world there"), "hello WORLD there")
    }

    func testFourWords() {
        XCTAssertEqual(pattern.transform("one two three four"), "one TWO three FOUR")
    }

    func testEmptyString() {
        XCTAssertEqual(pattern.transform(""), "")
    }

    func testSingleWord() {
        XCTAssertEqual(pattern.transform("hello"), "hello")
    }

    func testUppercaseInputIsNormalized() {
        XCTAssertEqual(pattern.transform("HELLO WORLD"), "hello WORLD")
    }

    func testPunctuationTreatedAsWordBoundary() {
        XCTAssertEqual(pattern.transform("hello,world"), "hello,WORLD")
    }

    func testMultipleSpacesDoNotCreateExtraWords() {
        XCTAssertEqual(pattern.transform("hello    world"), "hello    WORLD")
    }

    func testLeadingSpace() {
        XCTAssertEqual(pattern.transform("  hello world"), "  hello WORLD")
    }

    func testTrailingSpace() {
        XCTAssertEqual(pattern.transform("hello world "), "hello WORLD ")
    }

    func testEmojiBetweenWords() {
        XCTAssertEqual(pattern.transform("hello 👋 world"), "hello 👋 WORLD")
    }

    func testTransformCharacterFirstWord() {
        XCTAssertEqual(pattern.transformCharacter("h", priorContext: ""), "h")
        XCTAssertEqual(pattern.transformCharacter("i", priorContext: "h"), "i")
    }

    func testTransformCharacterSecondWord() {
        XCTAssertEqual(pattern.transformCharacter("w", priorContext: "hello "), "W")
        XCTAssertEqual(pattern.transformCharacter("o", priorContext: "hello w"), "O")
    }

    func testTransformCharacterThirdWord() {
        XCTAssertEqual(pattern.transformCharacter("t", priorContext: "hello world "), "t")
    }

    func testTransformCharacterSpaceDoesNotToggleYet() {
        XCTAssertEqual(pattern.transformCharacter(" ", priorContext: "hello"), " ")
    }

    func testMetadata() {
        XCTAssertEqual(pattern.id, "wordToggle")
        XCTAssertFalse(pattern.isPremium)
    }
}

import XCTest
@testable import SarcasmKit

final class AlternatingPatternTests: XCTestCase {
    private let pattern = AlternatingPattern()

    func testClassicHelloWorld() {
        XCTAssertEqual(pattern.transform("hello world"), "hElLo WoRlD")
    }

    func testEmptyString() {
        XCTAssertEqual(pattern.transform(""), "")
    }

    func testSingleCharacter() {
        XCTAssertEqual(pattern.transform("a"), "a")
        XCTAssertEqual(pattern.transform("A"), "a")
    }

    func testOnlyPunctuation() {
        XCTAssertEqual(pattern.transform("!?,.;"), "!?,.;")
    }

    func testLeadingWhitespaceDoesNotAdvanceIndex() {
        XCTAssertEqual(pattern.transform("   abc"), "   aBc")
    }

    func testNumbersPassThroughUnchanged() {
        XCTAssertEqual(pattern.transform("abc123def"), "aBc123DeF")
    }

    func testPunctuationDoesNotAdvanceIndex() {
        XCTAssertEqual(pattern.transform("a,b.c"), "a,B.c")
    }

    func testAllUppercaseInputIsSarcasified() {
        XCTAssertEqual(pattern.transform("HELLO"), "hElLo")
    }

    func testAllLowercaseInput() {
        XCTAssertEqual(pattern.transform("hello"), "hElLo")
    }

    func testMixedCaseNormalization() {
        XCTAssertEqual(pattern.transform("HeLlO"), "hElLo")
    }

    func testAccentedCharactersAreLetters() {
        let result = pattern.transform("café")
        XCTAssertEqual(result, "cAfÉ")
    }

    func testPrecomposedAndDecomposedAccentsBothHandled() {
        let precomposed = "\u{00E9}"
        let decomposed = "e\u{0301}"
        XCTAssertEqual(pattern.transform(precomposed), precomposed.lowercased())
        XCTAssertEqual(pattern.transform(decomposed), decomposed.lowercased())
    }

    func testEmojiPassThroughUnchanged() {
        XCTAssertEqual(pattern.transform("hi 👋 there"), "hI 👋 tHeRe")
    }

    func testComplexGraphemeClusterEmoji() {
        let input = "hi 👨‍👩‍👧 yo"
        let output = pattern.transform(input)
        XCTAssertTrue(output.contains("👨‍👩‍👧"))
        XCTAssertEqual(output, "hI 👨‍👩‍👧 yO")
    }

    func testNewlinesAndTabsPassThrough() {
        XCTAssertEqual(pattern.transform("ab\ncd\tef"), "aB\ncD\teF")
    }

    func testTransformCharacterFromEmptyPriorContext() {
        XCTAssertEqual(pattern.transformCharacter("h", priorContext: ""), "h")
    }

    func testTransformCharacterContinuesAlternation() {
        XCTAssertEqual(pattern.transformCharacter("e", priorContext: "h"), "E")
        XCTAssertEqual(pattern.transformCharacter("l", priorContext: "he"), "l")
        XCTAssertEqual(pattern.transformCharacter("l", priorContext: "hel"), "L")
        XCTAssertEqual(pattern.transformCharacter("o", priorContext: "hell"), "o")
    }

    func testTransformCharacterAcrossWordBoundary() {
        XCTAssertEqual(pattern.transformCharacter("w", priorContext: "hello "), "W")
        XCTAssertEqual(pattern.transformCharacter("w", priorContext: "hellow "), "w")
    }

    func testTransformCharacterIgnoresNonLettersInCount() {
        XCTAssertEqual(pattern.transformCharacter("x", priorContext: "ab,cd!"), "x")
        XCTAssertEqual(pattern.transformCharacter("x", priorContext: "ab,c!"), "X")
    }

    func testNonLetterCharacterPassesThrough() {
        XCTAssertEqual(pattern.transformCharacter(" ", priorContext: "hi"), " ")
        XCTAssertEqual(pattern.transformCharacter("!", priorContext: "hi"), "!")
    }

    func testLongInput() {
        let long = String(repeating: "a", count: 500)
        let out = pattern.transform(long)
        XCTAssertEqual(out.count, 500)
        for (i, c) in out.enumerated() {
            XCTAssertEqual(c, i.isMultiple(of: 2) ? "a" : "A")
        }
    }

    func testPatternMetadata() {
        XCTAssertEqual(pattern.id, "alternating")
        XCTAssertFalse(pattern.isPremium)
        XCTAssertEqual(pattern.displayName, "aLtErNaTiNg")
    }
}

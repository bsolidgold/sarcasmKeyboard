import XCTest
@testable import SarcasmKit

final class ZalgoPatternTests: XCTestCase {
    private let pattern = ZalgoPattern()

    func testIsDeterministic() {
        let a = pattern.transform("hello world")
        let b = pattern.transform("hello world")
        XCTAssertEqual(a, b)
    }

    func testEmptyString() {
        XCTAssertEqual(pattern.transform(""), "")
    }

    func testOutputLengthGreaterOrEqualToInput() {
        let input = "hello"
        let out = pattern.transform(input)
        XCTAssertGreaterThanOrEqual(out.unicodeScalars.count, input.unicodeScalars.count)
    }

    func testOutputContainsOriginalLetters() {
        let out = pattern.transform("hello")
        let scalars = Set(out.unicodeScalars.map { $0 })
        XCTAssertTrue(scalars.contains("h"))
        XCTAssertTrue(scalars.contains("e"))
        XCTAssertTrue(scalars.contains("l"))
        XCTAssertTrue(scalars.contains("o"))
    }

    func testAddsCombiningMarksForSomeLetters() {
        let input = String(repeating: "a", count: 50)
        let out = pattern.transform(input)
        let combiningMarkCount = out.unicodeScalars.filter { (0x0300...0x036F).contains($0.value) }.count
        XCTAssertGreaterThan(combiningMarkCount, 0)
    }

    func testSpacesArePreserved() {
        let out = pattern.transform("a b c")
        XCTAssertEqual(out.filter { $0 == " " }.count, 2)
    }

    func testTransformCharacterLetterProducesOutput() {
        let out = pattern.transformCharacter("a", priorContext: "")
        XCTAssertTrue(out.unicodeScalars.contains("a"))
    }

    func testTransformCharacterNonLetterPassesThrough() {
        XCTAssertEqual(pattern.transformCharacter(" ", priorContext: "hi"), " ")
    }

    func testMetadataIsPremium() {
        XCTAssertEqual(pattern.id, "zalgo")
        XCTAssertTrue(pattern.isPremium)
    }
}

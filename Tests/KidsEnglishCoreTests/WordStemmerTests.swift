import XCTest
@testable import KidsEnglishCore

/// 词形还原：课文点词能不能查到原形，全靠这里。
final class WordStemmerTests: XCTestCase {

    private func candidates(_ word: String) -> [String] {
        WordStemmer.candidates(for: word)
    }

    func testIrregularVerbs() {
        XCTAssertTrue(candidates("had").contains("have"))
        XCTAssertTrue(candidates("was").contains("be"))
        XCTAssertTrue(candidates("said").contains("say"))
        XCTAssertTrue(candidates("found").contains("find"))
        XCTAssertTrue(candidates("became").contains("become"))
        XCTAssertTrue(candidates("flew").contains("fly"))
        XCTAssertTrue(candidates("did").contains("do"))
        XCTAssertTrue(candidates("forgot").contains("forget"))
    }

    func testIrregularPlurals() {
        XCTAssertTrue(candidates("children").contains("child"))
        XCTAssertTrue(candidates("people").contains("person"))
        XCTAssertTrue(candidates("teeth").contains("tooth"))
        XCTAssertTrue(candidates("mice").contains("mouse"))
    }

    func testRegularPlurals() {
        XCTAssertTrue(candidates("stars").contains("star"))
        XCTAssertTrue(candidates("boxes").contains("box"))
        XCTAssertTrue(candidates("flies").contains("fly"))
        XCTAssertTrue(candidates("leaves").contains("leaf"))
    }

    func testVerbForms() {
        XCTAssertTrue(candidates("running").contains("run"), "双写辅音")
        XCTAssertTrue(candidates("lived").contains("live"))
        XCTAssertTrue(candidates("making").contains("make"), "去 e 加 ing")
        XCTAssertTrue(candidates("stopped").contains("stop"))
    }

    func testComparatives() {
        XCTAssertTrue(candidates("deeper").contains("deep"))
        XCTAssertTrue(candidates("highest").contains("high"))
        XCTAssertTrue(candidates("easier").contains("easy"))
        XCTAssertTrue(candidates("strongest").contains("strong"))
    }

    func testPossessiveAndPunctuation() {
        XCTAssertTrue(candidates("earth's").contains("earth"))
        XCTAssertTrue(candidates("stars,").contains("star"))
        // 引号由 lookupWord 的精确匹配剥离，词形还原不应再产出原词
        XCTAssertFalse(candidates("\"apple\"").contains("apple"))
    }

    func testShortOrEmptyInputIsIgnored() {
        XCTAssertTrue(candidates("a").isEmpty)
        XCTAssertTrue(candidates("").isEmpty)
        XCTAssertTrue(candidates("I").isEmpty, "单字母不做还原")
    }

    func testOriginalWordIsNotRepeatedInCandidates() {
        for word in ["star", "run", "deep"] {
            XCTAssertFalse(candidates(word).contains(word), "候选里不应包含原词")
        }
    }
}

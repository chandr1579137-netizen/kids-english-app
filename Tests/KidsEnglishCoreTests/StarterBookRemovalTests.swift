import XCTest
@testable import KidsEnglishCore

/// 词图表意重做（2026-10-22，用户批准方案 A/B/C 第 ② 项）：
/// 21 个看图学不会的词移出启蒙词书（首页单词本、「全部单词」、单词卡主题），
/// 但词典（words-*.json）和课文保留 —— 课文里点这些词照样能查到。
final class StarterBookRemovalTests: XCTestCase {

    /// redo-list.json 里 action=remove 的 21 个词
    static let removed: [String: [String]] = [
        "adjectives": ["gentle", "careful", "clever", "smart", "interesting", "exciting",
                       "peaceful", "safe", "right", "nice", "huge"],
        "actions": ["make", "learn", "skip"],
        "family": ["cousin", "son", "daughter"],
        "animals": ["hare", "tortoise"],
        "places": ["kingdom"],
        "nature": ["air"],
    ]
    static var removedWords: Set<String> { Set(removed.values.flatMap { $0 }) }

    private var resources: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("KidsEnglish/KidsEnglish/Resources")
    }

    private func decode<T: Decodable>(_ type: T.Type, from file: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(contentsOf: resources.appendingPathComponent(file)))
    }

    private func dictionary() throws -> [WordEntry] {
        try ["a", "b", "c", "d"].flatMap { try decode([WordEntry].self, from: "words-\($0).json") }
    }

    private func lessonText() throws -> Set<String> {
        var lessons: [Lesson] = []
        for level in 1...7 { lessons += try decode([Lesson].self, from: "lessons-l\(level).json") }
        lessons += try decode([Lesson].self, from: "custom-lessons.json")
        let text = lessons.flatMap { $0.content.map { $0.text } }.joined(separator: " ").lowercased()
        let tokens = text.split { !$0.isLetter }.map(String.init)
        return Set(tokens)
    }

    func testListHas21Words() {
        XCTAssertEqual(Self.removedWords.count, 21)
    }

    func testRemovedFromStarterBooks() throws {
        let themes = try decode([WordTheme].self, from: "word-themes.json")
        let dict = try dictionary().map { $0.word }
        for theme in themes {
            for w in theme.words {
                XCTAssertFalse(Self.removedWords.contains(w.lowercased()), "\(w) 应已移出 \(theme.id)")
            }
        }
        let home = HomeBooks.allowedWords(dictionary: dict, themes: themes)
        XCTAssertTrue(home.isDisjoint(with: Self.removedWords), "「全部单词」里不应再有这 21 个词")
        let learnable = ThemeWhitelist.allowedWords(dictionary: dict, themes: themes.flatMap { $0.words })
        XCTAssertTrue(learnable.isDisjoint(with: Self.removedWords), "单词卡 / 巩固练习里不应再有这 21 个词")
    }

    func testStillInDictionaryAndLessons() throws {
        let dict = Dictionary(uniqueKeysWithValues: try dictionary().map { ($0.word.lowercased(), $0) })
        for w in Self.removedWords {
            let entry = try XCTUnwrap(dict[w], "\(w) 必须留在词典里（课文点词查词要用）")
            XCTAssertFalse((entry.meaningCn ?? "").isEmpty)
        }
        // 课文原文不改：移词前出现在课文里的 15 个词，现在仍然都在
        let inLessons = ["gentle", "careful", "clever", "exciting", "peaceful", "safe", "right", "huge",
                         "make", "learn", "son", "hare", "tortoise", "kingdom", "air"]
        let tokens = try lessonText()
        for w in inLessons {
            XCTAssertTrue(tokens.contains(w), "课文里应该还有 \(w)")
        }
    }

    func testPerBookCountsComputedFromData() throws {
        let themes = try decode([WordTheme].self, from: "word-themes.json")
        let dict = Set(try dictionary().map { $0.word.lowercased() })
        var total = Set<String>()
        for theme in themes {
            let book = HomeBooks.homeWords(themeId: theme.id, words: theme.words)
                .filter { dict.contains($0.lowercased()) }
            XCTAssertEqual(book.count, theme.words.count, "\(theme.id)：每个主题词都应能在词典里找到")
            total.formUnion(book.map { $0.lowercased() })
        }
        let home = HomeBooks.allowedWords(dictionary: Array(dict), themes: themes)
        XCTAssertEqual(home, total, "「全部单词」= 各本书词的并集")
    }
}

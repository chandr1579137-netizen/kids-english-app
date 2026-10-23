import XCTest
@testable import KidsEnglishCore

/// 模型层测试：直接吃仓库里的真实资源文件。
/// 目的不是覆盖率，而是拦住「JSON 改了但 Swift 解不出来」这类静默丢数据。
final class ModelDecodingTests: XCTestCase {

    private var resources: URL {
        URL(fileURLWithPath: #filePath)          // Tests/KidsEnglishCoreTests/xxx.swift
            .deletingLastPathComponent()          // Tests/KidsEnglishCoreTests
            .deletingLastPathComponent()          // Tests
            .deletingLastPathComponent()          // 仓库根
            .appendingPathComponent("KidsEnglish/KidsEnglish/Resources")
    }

    private func load<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        let url = resources.appendingPathComponent(name)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func allWords() throws -> [WordEntry] {
        var words: [WordEntry] = []
        for part in ["a", "b", "c", "d"] {
            words += try load("words-\(part).json", as: [WordEntry].self)
        }
        return words
    }

    // MARK: - 词库

    func testWordsDecode() throws {
        let words = try allWords()
        XCTAssertEqual(words.count, 1347, "词库总数变了，确认是有意改动")
        XCTAssertEqual(Set(words.map { $0.word }).count, words.count, "存在重复词条")
        for word in words {
            XCTAssertFalse(word.word.isEmpty)
            XCTAssertFalse((word.meaningCn ?? "").isEmpty, "\(word.word) 缺中文释义")
        }
    }

    func testThemesAreCoveredByDictionary() throws {
        let themes = try load("word-themes.json", as: [WordTheme].self)
        let index = Set(try allWords().map { $0.word.lowercased() })

        XCTAssertEqual(themes.count, 16)
        var seen = Set<String>()
        for theme in themes {
            XCTAssertFalse(theme.words.isEmpty, "\(theme.id) 是空主题")
            for word in theme.words {
                XCTAssertTrue(index.contains(word.lowercased()),
                              "主题 \(theme.id) 的 \(word) 不在词库里")
                XCTAssertTrue(seen.insert(word.lowercased()).inserted,
                              "\(word) 出现在多个主题里")
            }
        }
        // 总数从数据算，不写死：每个主题词都在词库里且不跨主题重复，所以白名单 = 各主题词数之和。
        // （历史：491 → 569 数字补到 100 → 573 服装与火补词 → 552 移出 21 个看图学不会的词）
        XCTAssertEqual(seen.count, themes.reduce(0) { $0 + $1.words.count })
    }

    // 旧课文（lessons-l*.json、audio-map.json）已删除，对应的解码测试一并移除。
}

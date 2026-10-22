import XCTest
@testable import KidsEnglishCore

/// 词图表意重做：卡片专用释义（meaning_fix）+ 游戏易混词互斥（rule_only / confusable_groups）
final class CardMeaningConfusablesTests: XCTestCase {

    private var resources: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("KidsEnglish/KidsEnglish/Resources")
    }

    private func dictionary() throws -> [String: WordEntry] {
        var map: [String: WordEntry] = [:]
        for part in ["a", "b", "c", "d"] {
            let data = try Data(contentsOf: resources.appendingPathComponent("words-\(part).json"))
            for e in try JSONDecoder().decode([WordEntry].self, from: data) { map[e.word.lowercased()] = e }
        }
        return map
    }

    private func entry(_ w: String, _ cn: String = "x") -> WordEntry {
        WordEntry(word: w, phonetic: nil, meaningCn: cn, meaningEn: nil, partOfSpeech: nil,
                  examples: nil, emoji: nil, level: 1)
    }

    // MARK: 卡片释义

    func testCardMeaningOverridesExistInDictionaryAndDiffer() throws {
        let dict = try dictionary()
        XCTAssertGreaterThanOrEqual(CardMeaning.overrides.count, 16)
        for (w, cn) in CardMeaning.overrides {
            let e = try XCTUnwrap(dict[w], "\(w) 不在词典里")
            XCTAssertFalse(cn.isEmpty)
            XCTAssertFalse(cn.contains("；") || cn.contains("/"), "\(w) 卡片释义应只有一个义项")
            XCTAssertNotEqual(e.meaningCn, cn, "\(w) 覆盖值和词典一样，没必要覆盖")
        }
    }

    func testSpecificCardMeanings() throws {
        let dict = try dictionary()
        let light = CardMeaning.applying(to: try XCTUnwrap(dict["light"]))
        XCTAssertEqual(light.meaningCn, "轻的")
        XCTAssertEqual(CardMeaning.applying(to: try XCTUnwrap(dict["sharp"])).meaningCn, "尖的")
        XCTAssertEqual(CardMeaning.applying(to: try XCTUnwrap(dict["old"])).meaningCn, "旧的")
        XCTAssertEqual(CardMeaning.applying(to: try XCTUnwrap(dict["engine"])).meaningCn, "火车头")
        XCTAssertEqual(CardMeaning.applying(to: try XCTUnwrap(dict["rough"])).meaningCn, "粗糙的")
        // 其他字段不变
        XCTAssertEqual(light.word, dict["light"]?.word)
        XCTAssertEqual(light.phonetic, dict["light"]?.phonetic)
        XCTAssertEqual(light.level, dict["light"]?.level)
        // 没有覆盖的词原样返回
        let apple = try XCTUnwrap(dict["apple"])
        XCTAssertEqual(CardMeaning.applying(to: apple), apple)
    }

    // MARK: 双格对比高亮词图

    func testPairIconsAre34KnownWordsWithIcons() throws {
        let dict = try dictionary()
        XCTAssertEqual(PairIcons.words.count, 34)
        let icons = resources.appendingPathComponent("word-icons")
        for w in PairIcons.words {
            XCTAssertNotNil(dict[w], "双格图 \(w) 不在词典里")
            XCTAssertTrue(FileManager.default.fileExists(atPath: icons.appendingPathComponent("\(w).jpg").path),
                          "双格图 \(w).jpg 不存在")
        }
    }

    func testIsHighlightedPair() {
        for w in ["big", "small", "smooth", "rough", "Light", "far"] {
            XCTAssertTrue(PairIcons.isHighlightedPair(w), w)
        }
        // 单张图保持原来的边缘渐隐
        for w in ["apple", "dream", "aunt", "cat", "engine"] {
            XCTAssertFalse(PairIcons.isHighlightedPair(w), w)
        }
    }

    // MARK: 易混组

    func testGroupsAreKnownWords() throws {
        let dict = try dictionary()
        XCTAssertEqual(Confusables.groups.count, 33)
        for g in Confusables.groups {
            XCTAssertGreaterThanOrEqual(g.count, 2)
            for w in g { XCTAssertNotNil(dict[w], "易混组里的 \(w) 不在词典里") }
        }
    }

    func testConflict() {
        XCTAssertTrue(Confusables.conflict("cat", "kitten"))
        XCTAssertTrue(Confusables.conflict("Sea", "ocean"))
        XCTAssertTrue(Confusables.conflict("small", "little"))
        XCTAssertTrue(Confusables.conflict("see", "watch"))
        XCTAssertFalse(Confusables.conflict("cat", "dog"))
        XCTAssertFalse(Confusables.conflict("cat", "cat"))
        XCTAssertFalse(Confusables.conflict("apple", "banana"))
    }

    func testDistractorsSkipSameGroup() {
        let target = entry("cat")
        let pool = ["kitten", "dog", "puppy", "apple", "banana"].map { entry($0) }
        let picked = Confusables.pickDistractors(from: pool, for: target).map { $0.word }
        XCTAssertEqual(picked, ["dog", "apple", "banana"], "kitten 和答案同组，puppy 和已选的 dog 同组")
    }

    func testDistractorsDistinctMeaning() {
        let target = entry("big", "大的")
        let pool = [entry("huge", "大的"), entry("red", "红色"), entry("blue", "蓝色"), entry("navy", "蓝色"), entry("cat", "猫")]
        let picked = Confusables.pickDistractors(from: pool, for: target, distinctMeaning: true).map { $0.word }
        XCTAssertEqual(picked, ["red", "blue", "cat"])
    }

    func testPickDistinctForMatching() {
        let pool = ["sea", "ocean", "wave", "cat", "kitten", "apple"].map { entry($0) }
        let picked = Confusables.pickDistinct(pool, count: 6).map { $0.word }
        XCTAssertEqual(picked, ["sea", "cat", "apple"])
    }

    /// 真实词表上随机出题 200 次，选项里永远没有同组的两个词
    func testRandomQuestionsNeverMixGroup() throws {
        let dict = try dictionary()
        let pool = Confusables.groups.flatMap { $0 }.compactMap { dict[$0] } + ["apple", "banana", "red", "blue"].compactMap { dict[$0] }
        for _ in 0..<200 {
            let target = pool.randomElement()!
            let options = [target] + Confusables.pickDistractors(from: pool.shuffled(), for: target)
            XCTAssertEqual(options.count, 4)
            for i in options.indices {
                for j in options.indices where i < j {
                    XCTAssertFalse(Confusables.conflict(options[i].word, options[j].word),
                                   "\(options[i].word) 和 \(options[j].word) 同组却同时出现")
                }
            }
        }
    }
}

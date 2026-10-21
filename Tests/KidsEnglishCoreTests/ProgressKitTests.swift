import Foundation
import XCTest
@testable import KidsEnglishCore

/// DataStore 里抽出来的纯逻辑：备份快照、跨天日期键、低龄白名单、重置清理规则。
/// 这些逻辑原来藏在 DataStore（依赖 SwiftUI）里，一行测试都跑不到；抽到 ProgressKit 后
/// 用 SwiftPM 直接测，不需要模拟器。
final class ProgressKitTests: XCTestCase {

    // MARK: - 工具

    private var utc: TimeZone { TimeZone(secondsFromGMT: 0)! }
    private var shanghai: TimeZone { TimeZone(secondsFromGMT: 8 * 3600)! }

    /// 用固定 UTC 字符串造 Date，避免测试结果依赖运行机器的本地时区。
    private func date(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso) ?? Date(timeIntervalSince1970: 0)
    }

    /// 一份字段齐全的快照，避免每个用例都写 14 个参数。
    private func makeSnapshot() -> ProgressSnapshot {
        return ProgressSnapshot(
            version: 1,
            exportedAt: "2026-10-18T09:00:00Z",
            completedLessons: ["l1-01"],
            learnedWords: ["apple"],
            favoriteWords: ["apple"],
            collectedCards: ["card-a"],
            quizBest: ["l1-01": 80],
            selectedThemeId: "fruits",
            dailyNewWords: 10,
            timeLimitMinutes: 20,
            showTranslationDefault: true,
            gameAnswered: 5,
            gameCorrect: 4,
            studyDates: ["2026-10-18"]
        )
    }

    // MARK: - 备份 / 恢复

    /// 全字段往返：包括 nil 主题、空数组、中文和带撇号的词。旧备份靠这条不丢数据。
    func testSnapshotRoundTripPreservesAllFields() throws {
        let snapshot = ProgressSnapshot(
            version: 1,
            exportedAt: "2026-10-18T09:00:00Z",
            completedLessons: ["l1-01", "l2-03"],
            learnedWords: ["apple", "地球", "grandma's"],
            favoriteWords: [],
            collectedCards: ["card-a", "card-b"],
            quizBest: ["l1-01": 100, "l2-03": 62.5],
            selectedThemeId: nil,
            dailyNewWords: 12,
            timeLimitMinutes: 0,
            showTranslationDefault: false,
            gameAnswered: 17,
            gameCorrect: 12,
            studyDates: ["2026-10-17", "2026-10-18"]
        )

        let decoded = try XCTUnwrap(ProgressCodec.decode(ProgressCodec.encode(snapshot)),
                                    "合法导出的备份应能原样解回")
        XCTAssertEqual(decoded, snapshot)
        XCTAssertNil(decoded.selectedThemeId, "nil 主题应保持 nil，而不是空字符串")
        XCTAssertEqual(decoded.learnedWords, ["apple", "地球", "grandma's"], "中文/撇号不应丢")
        XCTAssertTrue(decoded.favoriteWords.isEmpty)
    }

    /// 主题非 nil、quizBest 为空数组时也要能往返（可选字段与空字典的边界）。
    func testSnapshotRoundTripWithSelectedThemeAndEmptyQuizBest() throws {
        var snapshot = makeSnapshot()
        snapshot.selectedThemeId = "animals"
        snapshot.quizBest = [:]
        snapshot.studyDates = []

        let decoded = try XCTUnwrap(ProgressCodec.decode(ProgressCodec.encode(snapshot)))
        XCTAssertEqual(decoded, snapshot)
        XCTAssertEqual(decoded.selectedThemeId, "animals")
        XCTAssertTrue(decoded.quizBest.isEmpty)
    }

    /// 导出格式必须保持 prettyPrinted + sortedKeys，否则旧版本/脚本比对会变化。
    func testEncodeUsesPrettyPrintedSortedKeys() throws {
        let text = ProgressCodec.encode(makeSnapshot())
        XCTAssertTrue(text.hasPrefix("{"), "导出应是 JSON 对象")
        XCTAssertTrue(text.contains("\n"), "prettyPrinted 应带换行缩进")

        let firstQuote = try XCTUnwrap(text.range(of: "\""))
        let collectedCards = try XCTUnwrap(text.range(of: "\"collectedCards\""))
        let version = try XCTUnwrap(text.range(of: "\"version\""))
        XCTAssertEqual(firstQuote.lowerBound, collectedCards.lowerBound,
                       "sortedKeys 应让 collectedCards 成为第一个键")
        XCTAssertLessThan(collectedCards.lowerBound, version.lowerBound,
                          "sortedKeys 应按字母序输出，version 在最后")
    }

    /// 坏 JSON、缺字段、类型不符都必须返回 nil（调用方保持原进度不变）。
    func testDecodeRejectsMalformedInput() {
        XCTAssertNil(ProgressCodec.decode(""), "空字符串不是备份")
        XCTAssertNil(ProgressCodec.decode("这不是一份备份"))
        XCTAssertNil(ProgressCodec.decode("{}"), "缺全部字段的 JSON 不能当备份")
        XCTAssertNil(ProgressCodec.decode("{\"version\":1}"), "只给 version 也不算完整备份")
        XCTAssertNil(ProgressCodec.decode("{\"version\":\"one\"}"), "字段类型不对应拒绝")
    }

    /// 恢复成功文案的格式与旧实现一致。
    func testSummaryFormatsRecoveredCounts() {
        var snapshot = makeSnapshot()
        snapshot.completedLessons = ["a", "b", "c"]
        snapshot.learnedWords = ["apple", "banana"]
        XCTAssertEqual(ProgressCodec.summary(snapshot), "已恢复：3 篇课文、2 个单词")

        snapshot.completedLessons = []
        snapshot.learnedWords = []
        XCTAssertEqual(ProgressCodec.summary(snapshot), "已恢复：0 篇课文、0 个单词")
    }

    // MARK: - 跨天

    /// 同一天内任何时刻都得到同一个日期键；个位月/日要补零。
    func testDayKeySameDayAndZeroPadding() {
        let morning = date("2026-03-05T00:00:01Z")
        let night = date("2026-03-05T23:59:59Z")

        XCTAssertEqual(DayKey.key(for: morning, timeZone: utc), "2026-03-05")
        XCTAssertEqual(DayKey.key(for: night, timeZone: utc), "2026-03-05")
        XCTAssertFalse(DayKey.isNewDay(stored: "2026-03-05", now: night, timeZone: utc))
        XCTAssertTrue(DayKey.isNewDay(stored: "2026-03-04", now: morning, timeZone: utc))
    }

    /// 跨过午夜：日期键变化，rollover 需要触发。
    func testDayKeyCrossesMidnight() {
        let before = date("2026-01-15T23:59:59Z")
        let after = date("2026-01-16T00:00:00Z")

        XCTAssertEqual(DayKey.key(for: before, timeZone: utc), "2026-01-15")
        XCTAssertEqual(DayKey.key(for: after, timeZone: utc), "2026-01-16")
        XCTAssertTrue(DayKey.isNewDay(stored: "2026-01-15", now: after, timeZone: utc))
        XCTAssertFalse(DayKey.isNewDay(stored: "2026-01-16", now: after, timeZone: utc))
    }

    /// 同一时刻在不同时区可能落在不同日期：日期键必须跟着传入的时区走。
    func testDayKeyRespectsTimeZone() {
        let instant = date("2026-01-15T16:30:00Z")

        XCTAssertEqual(DayKey.key(for: instant, timeZone: utc), "2026-01-15")
        XCTAssertEqual(DayKey.key(for: instant, timeZone: shanghai), "2026-01-16")
        XCTAssertTrue(DayKey.isNewDay(stored: "2026-01-15", now: instant, timeZone: shanghai),
                      "同一时刻在东八区已经是新的一天")
        XCTAssertFalse(DayKey.isNewDay(stored: "2026-01-16", now: instant, timeZone: shanghai))
    }

    // MARK: - 低龄白名单

    /// 主题词取并集、去重、大小写不敏感，词典外的主题词被忽略。
    func testWhitelistUnionDedupAndCaseInsensitive() {
        let allowed = ThemeWhitelist.allowedWords(
            dictionary: ["apple", "banana", "cherry", "zebra"],
            themes: ["Apple", "APPLE", "banana", "cherry"]
        )
        XCTAssertEqual(allowed, Set(["apple", "banana", "cherry"]),
                       "应去重并按小写返回；词典里的 zebra 不在主题中，应被过滤")
    }

    /// 模拟 loadJSON 的用法：按词典原顺序过滤，词典外/主题外的词都不出现。
    func testWhitelistFiltersDictionaryAndKeepsOriginalOrder() {
        let dictionary = ["apple", "is", "banana", "genesis", "1000"]
        let themes = ["Banana", "apple", "zebra"]
        let allowed = ThemeWhitelist.allowedWords(dictionary: dictionary, themes: themes)

        XCTAssertEqual(allowed, Set(["apple", "banana"]), "主题里的 zebra 不在词典里，应被忽略")
        let words = dictionary.filter { allowed.contains($0.lowercased()) }
        XCTAssertEqual(words, ["apple", "banana"], "过滤后应保留词典顺序")
    }

    /// 主题为空（资源没打包好）时回退全量，不能空屏。
    func testWhitelistFallsBackToWholeDictionaryWhenThemesEmpty() {
        let dictionary = ["Apple", "is", "1000"]
        let allowed = ThemeWhitelist.allowedWords(dictionary: dictionary, themes: [])

        XCTAssertEqual(allowed, Set(["apple", "is", "1000"]))
        let words = dictionary.filter { allowed.contains($0.lowercased()) }
        XCTAssertEqual(words, ["Apple", "is", "1000"], "主题为空时保留全部词条")
    }

    // MARK: - 重置

    /// 只清理 study_ / bonus_ 前缀的按天记录；设置项和更短的前缀不误伤。
    func testResetPlanKeepsOnlyStudyAndBonusPrefixes() {
        let keys = [
            "study_2026-10-17", "bonus_2026-10-17",
            "completedLessons", "learnedWords", "selectedThemeId",
            "timeLimitMinutes", "showTranslation", "study", "bonus",
            "study_2026-10-18", "bonus_",
        ]
        XCTAssertEqual(
            ResetPlan.keysToPurge(from: keys),
            ["study_2026-10-17", "bonus_2026-10-17", "study_2026-10-18", "bonus_"],
            "应保持输入顺序，只留下两个每日前缀"
        )

        XCTAssertEqual(ResetPlan.keysToPurge(from: []), [String](), "空输入返回空")
        XCTAssertEqual(ResetPlan.keysToPurge(from: ["completedLessons"]), [String](),
                       "没有按天 key 时什么都不清理")
    }
}

// MARK: - 首页单词本（真实资源）

/// 这些用例直接读仓库里的 Resources——mock 只能证明过滤逻辑，
/// 证明不了「数据本身还是 483 词 / 数字本还是 100 词」。
final class HomeBooksTests: XCTestCase {

    /// Tests/KidsEnglishCoreTests/ProgressKitTests.swift → 仓库根
    private var resources: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("KidsEnglish/KidsEnglish/Resources")
    }

    private func decode<T: Decodable>(_ type: T.Type, from file: String) throws -> T {
        let data = try Data(contentsOf: resources.appendingPathComponent(file))
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func loadThemes() throws -> [WordTheme] {
        try decode([WordTheme].self, from: "word-themes.json")
    }

    private func loadDictionary() throws -> [String] {
        var words: [WordEntry] = []
        for file in ["words-a.json", "words-b.json", "words-c.json", "words-d.json"] {
            words += try decode([WordEntry].self, from: file)
        }
        return words.map { $0.word }
    }

    func testHomeNumbersBookIsExactlyOneToTen() throws {
        let themes = try loadThemes()
        let numbers = try XCTUnwrap(themes.first { $0.id == "numbers" })
        let home = HomeBooks.homeWords(themeId: "numbers", words: numbers.words)

        XCTAssertEqual(home, ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"])
        XCTAssertEqual(home.count, 10)
        XCTAssertEqual(numbers.words.count, 100, "数据不动：word-themes.json 的数字主题仍是 100 词")
    }

    func testHomeAllWordsExcludesElevenToHundred() throws {
        let themes = try loadThemes()
        let dictionary = try loadDictionary()

        let full = ThemeWhitelist.allowedWords(dictionary: dictionary, themes: themes.flatMap { $0.words })
        let home = HomeBooks.allowedWords(dictionary: dictionary, themes: themes)

        let numbers = try XCTUnwrap(themes.first { $0.id == "numbers" })
        let keep = Set(["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"])
        let otherThemeWords = Set(themes.filter { $0.id != "numbers" }.flatMap { $0.words }.map { $0.lowercased() })
        let excluded = Set(numbers.words.map { $0.lowercased() }).subtracting(keep).subtracting(otherThemeWords)

        XCTAssertEqual(home, full.subtracting(excluded))
        XCTAssertEqual(home.count, full.count - 90)
        XCTAssertFalse(home.contains("eleven"))
        XCTAssertFalse(home.contains("twenty"))
        XCTAssertFalse(home.contains("hundred"))
        XCTAssertTrue(home.contains("ten"))
        XCTAssertEqual(home.count, 483, "PM acceptance number from data on main 51fad39")
    }

    func testHomeFilterLeavesOtherThemesUntouched() throws {
        let themes = try loadThemes()
        let fruits = try XCTUnwrap(themes.first { $0.id == "fruits" })
        XCTAssertEqual(HomeBooks.homeWords(themeId: "fruits", words: fruits.words), fruits.words)
    }

    func testBookOrder() throws {
        let themes = try loadThemes()
        let sorted = HomeBooks.sorted(themes.map { $0.id })

        XCTAssertEqual(sorted.count, 16)
        XCTAssertEqual(Set(sorted), Set(themes.map { $0.id }))
        XCTAssertEqual(Set(sorted).count, sorted.count, "不应有重复")
        let home = try XCTUnwrap(sorted.firstIndex(of: "home"))
        let clothing = try XCTUnwrap(sorted.firstIndex(of: "clothing"))
        XCTAssertEqual(clothing, home + 1, "clothing 应紧跟在 home 后面")
        XCTAssertEqual(HomeBooks.sorted(["zzz", "home", "fruits"]), ["fruits", "home", "zzz"],
                       "未知 id 保持原顺序排最后")
    }
}

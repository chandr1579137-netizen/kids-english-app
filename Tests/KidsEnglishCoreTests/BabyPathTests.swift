import Foundation
import XCTest
@testable import KidsEnglishCore

/// 宝宝模式：直接读仓库里的 Resources/baby-path.json，检查词包、解锁、每日计划、复习间隔和出题。
final class BabyPathTests: XCTestCase {

    private var root: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    private var resources: URL { root.appendingPathComponent("KidsEnglish/KidsEnglish/Resources") }
    private let utc = TimeZone(secondsFromGMT: 0)!

    private func load() throws -> BabyPathData {
        let data = try Data(contentsOf: resources.appendingPathComponent("baby-path.json"))
        return try XCTUnwrap(BabyPathData.decode(data), "baby-path.json 解不开")
    }

    private func date(_ s: String) -> Date {
        let f = ISO8601DateFormatter()
        return f.date(from: s + "T12:00:00Z")!
    }

    // MARK: - 数据

    func testTenPacksSixtyEightUniqueWords() throws {
        let d = try load()
        XCTAssertEqual(d.packs.count, 10)
        XCTAssertEqual(d.allWords.count, 68)
        XCTAssertEqual(Set(d.allWords).count, 68, "同一个词出现在两个包里")
        XCTAssertEqual(d.packs.filter(\.locked).map(\.id), ["numbers-2", "clothes", "weather"])
    }

    /// 每个词都有平涂词图和发音；不收带字的毛绒字母图（hello / hi / bye / yes / no / I / you）
    func testEveryWordHasFlatPictureAndAudio() throws {
        let d = try load()
        let overrides = root.appendingPathComponent("assets/word-icons-overrides")
        let audioMap = try JSONDecoder().decode([String: String].self,
            from: Data(contentsOf: resources.appendingPathComponent("word-audio-map.json")))
        for w in d.allWords {
            let pic = d.picture(for: w)
            XCTAssertTrue(FileManager.default.fileExists(atPath: overrides.appendingPathComponent("\(pic).jpg").path),
                          "\(w): 没有平涂词图 \(pic).jpg")
            let file = try XCTUnwrap(audioMap[w], "\(w): 没有发音映射")
            XCTAssertTrue(FileManager.default.fileExists(atPath: resources.appendingPathComponent("audio/\(file)").path),
                          "\(w): 发音文件不存在")
        }
        for w in ["hello", "hi", "bye", "yes", "no", "i", "you"] {
            XCTAssertFalse(d.allWords.contains(w), "\(w) 的现成图是带字的毛绒字母，不进宝宝模式")
        }
        XCTAssertEqual(d.picture(for: "mom"), "mother")
    }

    // MARK: - 解锁与每日新词

    func testLockedPacksOpenInOrderAfterOpenPacksAreLearned() throws {
        let d = try load()
        XCTAssertEqual(BabyPlan.openPacks(d, known: [], unlockAll: false).count, 7)
        let firstSeven = Set(d.packs.prefix(7).flatMap(\.words))
        let open = BabyPlan.openPacks(d, known: firstSeven, unlockAll: false).map(\.id)
        XCTAssertEqual(open.count, 8)
        XCTAssertEqual(open.last, "numbers-2")
        XCTAssertEqual(BabyPlan.openPacks(d, known: [], unlockAll: true).count, 10)
    }

    func testNewWordsFollowPackOrderAndSkipKnown() throws {
        let d = try load()
        XCTAssertEqual(BabyPlan.newWords(d, known: [], unlockAll: false, count: 3), ["mom", "dad", "grandma"])
        XCTAssertEqual(BabyPlan.newWords(d, known: ["mom", "dad"], unlockAll: false, count: 3),
                       ["grandma", "grandpa", "baby"])
    }

    // MARK: - 复习间隔

    func testIntervalsGrowOnCorrectAndResetOnWrong() {
        let today = date("2026-10-22")
        let s0 = BabyPlan.learned(today: today, timeZone: utc)
        XCTAssertEqual(s0, BabyWordState(box: 0, due: "2026-10-23"))
        let s1 = BabyPlan.after(s0, correct: true, today: today, timeZone: utc)
        XCTAssertEqual(s1, BabyWordState(box: 1, due: "2026-10-24"))
        let s2 = BabyPlan.after(s1, correct: true, today: today, timeZone: utc)
        XCTAssertEqual(s2.due, "2026-10-26")
        XCTAssertEqual(BabyPlan.after(s2, correct: false, today: today, timeZone: utc),
                       BabyWordState(box: 0, due: "2026-10-23"))
        var s = s0
        for _ in 0..<10 { s = BabyPlan.after(s, correct: true, today: today, timeZone: utc) }
        XCTAssertEqual(s.box, BabyPlan.intervals.count - 1, "格子封顶，不越界")
    }

    func testDueReviewsOldestAndWeakestFirstWithLimit() {
        let states: [String: BabyWordState] = [
            "cat": BabyWordState(box: 2, due: "2026-10-20"),
            "dog": BabyWordState(box: 0, due: "2026-10-22"),
            "pig": BabyWordState(box: 1, due: "2026-10-20"),
            "cow": BabyWordState(box: 0, due: "2026-10-25"),
            "red": BabyWordState(box: 3, due: "2026-10-21"),
            "egg": BabyWordState(box: 0, due: "2026-10-19"),
        ]
        XCTAssertEqual(BabyPlan.dueReviews(states, today: "2026-10-22"), ["egg", "pig", "cat", "red"])
        XCTAssertFalse(BabyPlan.dueReviews(states, today: "2026-10-22", limit: 10).contains("cow"))
    }

    // MARK: - 出题

    func testRoundsHaveThreeOptionsWithoutConfusablesOrSamePicture() throws {
        let d = try load()
        var rng = SeededGenerator(seed: 1)
        let pool = d.allWords
        for w in d.allWords {
            for _ in 0..<5 {
                let r = BabyPlan.round(answer: w, pool: pool, data: d, using: &rng)
                XCTAssertEqual(r.options.count, BabyPlan.optionCount)
                XCTAssertTrue(r.options.contains(w))
                XCTAssertEqual(Set(r.options).count, r.options.count)
                XCTAssertEqual(Set(r.options.map(d.picture(for:))).count, r.options.count, "两个选项用了同一张图")
                for a in r.options {
                    for b in r.options where a != b {
                        XCTAssertFalse(Confusables.conflict(a, b), "\(a) / \(b) 是易混词")
                    }
                }
            }
        }
    }

    func testSessionShape() throws {
        let d = try load()
        var rng = SeededGenerator(seed: 7)
        let newWords = ["cat", "dog", "bird"]
        let reviews = ["mom", "dad"]
        let steps = BabyPlan.session(d, newWords: newWords, reviews: reviews,
                                     known: Set(d.packs[0].words), unlockAll: false, using: &rng)
        XCTAssertEqual(steps.last, .done)
        XCTAssertEqual(steps.prefix(2).map { (s: BabyStep) -> String in if case .review(let r) = s { return r.answer } else { return "" } }, reviews)
        let learn = steps.compactMap { (s: BabyStep) -> String? in if case .learn(let w) = s { return w } else { return nil } }
        XCTAssertEqual(learn, newWords)
        let game = steps.compactMap { (s: BabyStep) -> String? in if case .game(let r) = s { return r.answer } else { return nil } }
        XCTAssertEqual(game.count, BabyPlan.gameRounds)
        XCTAssertTrue(Set(newWords).isSubset(of: Set(game)), "今天的新词每个至少考一次")
        for (a, b) in zip(game, game.dropFirst()) { XCTAssertNotEqual(a, b, "同一个词连着考") }
        XCTAssertEqual(BabyPlan.sticker(for: steps), "cat")
    }

    func testReplayIsGameOnlyFromKnownWords() throws {
        let d = try load()
        var rng = SeededGenerator(seed: 3)
        let known: Set<String> = ["cat", "dog"]
        let steps = BabyPlan.replay(d, known: known, unlockAll: false, using: &rng)
        XCTAssertEqual(steps.count, BabyPlan.gameRounds + 1)
        for s in steps.dropLast() {
            guard case .game(let r) = s else { return XCTFail("再玩一次只有小游戏") }
            XCTAssertTrue(known.contains(r.answer))
        }
        XCTAssertEqual(BabyPlan.replay(d, known: [], unlockAll: false, using: &rng), [.done])
    }

    // MARK: - 备份

    func testBabyProgressRoundTripsAndOldBackupsKeepWorking() throws {
        let old = """
        {"collectedCards":[],"completedLessons":[],"dailyNewWords":10,"exportedAt":"x",
         "favoriteWords":[],"gameAnswered":0,"gameCorrect":0,"learnedWords":[],"quizBest":{},
         "showTranslationDefault":true,"studyDates":[],"timeLimitMinutes":20,"version":1}
        """
        var snap = try XCTUnwrap(ProgressCodec.decode(old))
        XCTAssertNil(snap.babyWords)
        XCTAssertEqual(ProgressCodec.summary(snap), "已恢复：0 篇课文、0 个单词")
        snap.babyWords = ["cat": BabyWordState(box: 1, due: "2026-10-24")]
        snap.babyStickers = ["2026-10-22": "cat"]
        let back = try XCTUnwrap(ProgressCodec.decode(ProgressCodec.encode(snap)))
        XCTAssertEqual(back.babyWords, snap.babyWords)
        XCTAssertEqual(back.babyStickers, snap.babyStickers)
        XCTAssertEqual(ProgressCodec.summary(back), "已恢复：0 篇课文、0 个单词、宝宝模式 1 个词")
    }
}

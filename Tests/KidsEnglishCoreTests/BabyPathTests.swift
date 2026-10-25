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

    /// 数量从数据算，不写死：原来的 10 包顺序不变排在最前，新包都锁着、按顺序打开；没有重复的词
    func testPackOrderLockingAndNoDuplicateWords() throws {
        let d = try load()
        XCTAssertEqual(Array(d.packs.prefix(10).map(\.id)),
                       ["family", "animals", "colors", "numbers", "food", "body", "actions", "numbers-2", "clothes", "weather"])
        XCTAssertEqual(Set(d.allWords).count, d.allWords.count, "同一个词出现在两个包里")
        XCTAssertEqual(d.packs.filter { !$0.locked }.count, 7, "只有前 7 包一开始就开")
        for pack in d.packs.dropFirst(10) {
            XCTAssertTrue(pack.locked, "\(pack.id): 新包要锁着")
            XCTAssertTrue((6...10).contains(pack.words.count) || pack.id == "family-2",
                          "\(pack.id): 每包 6–10 个词（家人 2 例外，5 个）")
        }
    }

    /// v2 全部 31 包：每包都有 pattern、sentences、tipZh，且每个词都有对应的句子语音和鼓点念词语音
    func testNewPacksHaveFullSentences() throws {
        let d = try load()
        let phraseAudioDir = resources.appendingPathComponent("phrases/audio")
        for pack in d.packs {
            let pattern = try XCTUnwrap(pack.pattern, "\(pack.id): 缺句型")
            XCTAssertTrue(pattern.contains("___"), "\(pack.id): 句型要有填空")
            let tip = try XCTUnwrap(pack.tipZh, "\(pack.id): 缺家长页『生活里这样用』提示")
            XCTAssertFalse(tip.isEmpty, "\(pack.id): 提示不能为空")
            for w in pack.words {
                let s = try XCTUnwrap(d.sentence(for: w), "\(pack.id)/\(w): 缺例句")
                XCTAssertFalse(s.contains("___"), "\(w): 例句里还有空")
                XCTAssertTrue(s.first?.isUppercase == true && ".!?".contains(s.last!), "\(w): 例句要完整：\(s)")
                XCTAssertTrue(FileManager.default.fileExists(atPath: phraseAudioDir.appendingPathComponent("baby_sent_\(w).mp3").path),
                              "\(w): 缺例句语音 baby_sent_\(w).mp3")
                XCTAssertTrue(FileManager.default.fileExists(atPath: phraseAudioDir.appendingPathComponent("baby_chant_\(w).mp3").path),
                              "\(w): 缺鼓点念词语音 baby_chant_\(w).mp3")
            }
        }
        for w in BabyPlan.followMeCommands.keys {
            XCTAssertTrue(FileManager.default.fileExists(atPath: phraseAudioDir.appendingPathComponent("baby_cmd_\(w).mp3").path),
                          "\(w): 缺 Tom 说你做指令音 baby_cmd_\(w).mp3")
        }
        XCTAssertEqual(d.sentence(for: "elephant"), "Look, an elephant!", "冠词写死")
        XCTAssertEqual(d.sentence(for: "eleven"), "I can count to eleven!")
        XCTAssertEqual(d.sentence(for: "happy"), "I'm happy.", "happy / sad 用 I'm")
        XCTAssertEqual(d.sentence(for: "fly"), "Birds can fly.", "人不会飞，主语写死成鸟")
        XCTAssertEqual(d.sentence(for: "teeth"), "Show me your teeth.", "不让孩子拿手摸牙")
    }

    /// 反义词：同一对同一天学，出题时互为干扰项
    func testOppositePairsAreLearnedTogetherAndUsedAsDistractors() throws {
        let d = try load()
        XCTAssertEqual(d.partner(of: "big"), "small")
        XCTAssertEqual(d.partner(of: "small"), "big")
        XCTAssertEqual(d.partner(of: "new"), "old")
        XCTAssertNil(d.partner(of: "cat"))
        let everythingBefore = Set(d.packs.prefix(while: { $0.id != "opposites-1" }).flatMap(\.words))
        for count in 3...8 {
            let today = BabyPlan.newWords(d, known: everythingBefore, unlockAll: true, count: count)
            for w in today { XCTAssertTrue(today.contains(d.partner(of: w)!), "\(w) 和它的反义词要同一天学") }
            XCTAssertTrue(today.count == count || today.count == count + 1)
        }
        var rng = SeededGenerator(seed: 5)
        for _ in 0..<20 {
            let r = BabyPlan.round(answer: "big", pool: d.allWords, data: d, using: &rng)
            XCTAssertTrue(r.options.contains("small"), "听 big 时 small 一定是选项")
        }
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
        XCTAssertEqual(BabyPlan.openPacks(d, known: [], unlockAll: true).count, d.packs.count, "全部解锁 = 所有包")
    }

    func testNewWordsFollowPackOrderAndSkipKnown() throws {
        let d = try load()
        XCTAssertEqual(BabyPlan.defaultNewPerDay, 4, "v2 默认每天学 4 个新词")
        XCTAssertEqual(BabyPlan.newWords(d, known: [], unlockAll: false), ["mom", "dad", "grandma", "grandpa"])
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

    // MARK: - 出题与 6 步流程

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

    /// 6 步流程顺序生成：唱一唱（有儿歌 vs 鼓点念词）→ 复习 → 学一学 → 玩一玩 → 句子 → 自己说 → 贴纸
    func testSessionShape() throws {
        let d = try load()
        var rng = SeededGenerator(seed: 7)
        let newWords = ["cat", "dog", "bird", "fish"]
        let reviews = ["mom", "dad"]
        let steps = BabyPlan.session(d, newWords: newWords, reviews: reviews,
                                     known: Set(d.packs[0].words), unlockAll: false,
                                     chosenGame: .listenChoice, using: &rng)

        // 1. 唱一唱：animals 包有儿歌 old-macdonald
        XCTAssertEqual(steps.first, .sing(words: newWords, songId: "old-macdonald"))

        // 无儿歌的词包（如 clothes）：songId 为 nil（走 4 拍鼓点节奏念词）
        let clothesSteps = BabyPlan.session(d, newWords: ["shirt", "pants", "shoes", "hat"], reviews: [],
                                            known: [], unlockAll: true, chosenGame: .listenChoice, using: &rng)
        XCTAssertEqual(clothesSteps.first, .sing(words: ["shirt", "pants", "shoes", "hat"], songId: nil))

        // 2. 复习
        let revAnswers = steps.compactMap { (s: BabyStep) -> String? in if case .review(let r) = s { return r.answer } else { return nil } }
        XCTAssertEqual(revAnswers, reviews)

        // 3. 学一学
        let learn = steps.compactMap { (s: BabyStep) -> String? in if case .learn(let w) = s { return w } else { return nil } }
        XCTAssertEqual(learn, newWords)

        // 4. 玩一玩
        let game = steps.compactMap { (s: BabyStep) -> String? in if case .game(let r) = s { return r.answer } else { return nil } }
        XCTAssertEqual(game.count, BabyPlan.gameRounds)
        XCTAssertTrue(Set(newWords).isSubset(of: Set(game)), "今天的新词每个至少考一次")
        for (a, b) in zip(game, game.dropFirst()) { XCTAssertNotEqual(a, b, "同一个词连着考") }

        // 5. 句子：今天词包的 1 个句型套前 2 个新词
        let sentences = steps.compactMap { (s: BabyStep) -> (String, String)? in
            if case .sentence(let w, let t) = s { return (w, t) } else { return nil }
        }
        XCTAssertEqual(sentences.map(\.0), ["cat", "dog"])
        XCTAssertEqual(sentences.map(\.1), ["It's a cat.", "It's a dog."])

        // 6. 自己说：出今天的新词
        let sayIt = steps.compactMap { (s: BabyStep) -> String? in if case .sayIt(let w) = s { return w } else { return nil } }
        XCTAssertEqual(sayIt, newWords)

        // 7. 贴纸完成页，且阶段号单调不减
        XCTAssertEqual(steps.last, .done)
        let stages = steps.compactMap(\.stage).map(\.rawValue)
        XCTAssertEqual(stages, stages.sorted(), "6 步阶段顺序必须从 1 到 6 单调递增")
        XCTAssertEqual(BabyPlan.sticker(for: steps), "cat")
    }

    /// 游戏轮换：不连着两天选同一个游戏；只选和今天这些词搭得上的游戏
    func testGameRotationNeverRepeatsAndRespectsCompatibility() {
        let colorWords = ["red", "blue", "yellow", "green"]
        let colorCompatible = BabyPlan.compatibleGames(for: colorWords)
        XCTAssertFalse(colorCompatible.contains(.followMe), "颜色词不能出『Tom 说你做』")
        XCTAssertFalse(colorCompatible.contains(.shadowDrag), "纯色块剪影都一样，不能出『影子配对』")
        XCTAssertEqual(Set(colorCompatible), Set([.listenChoice, .memoryFlip]))

        let bodyWords = ["head", "eyes", "ears", "nose"]
        let bodyCompatible = BabyPlan.compatibleGames(for: bodyWords)
        XCTAssertTrue(bodyCompatible.contains(.followMe), "身体词可以出『Tom 说你做』")
        XCTAssertTrue(bodyCompatible.contains(.shadowDrag), "身体词可以出『影子配对』")

        var rng = SeededGenerator(seed: 19)
        var last: BabyGameKind? = nil
        for _ in 0..<60 {
            let picked = BabyPlan.pickGame(words: bodyWords, lastGame: last, using: &rng)
            if let last {
                XCTAssertNotEqual(picked, last, "连着两天不能选同一个游戏")
            }
            XCTAssertTrue(bodyCompatible.contains(picked))
            last = picked
        }
    }

    /// 复习日判断：每学完 4 天新词，第 5 天出复习日（戳泡泡选游戏）
    func testReviewDayEveryFifthStudyDay() throws {
        let d = try load()
        for completed in [0, 1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 13] {
            XCTAssertFalse(BabyPlan.isReviewDay(completedDays: completed), "已完成 \(completed) 天时不应是复习日")
        }
        for completed in [4, 9, 14, 19] {
            XCTAssertTrue(BabyPlan.isReviewDay(completedDays: completed), "已完成 \(completed) 天后（第 \(completed + 1) 天）应是复习日")
        }

        var rng = SeededGenerator(seed: 11)
        let reviews = ["mom", "dad", "cat", "dog", "red", "blue"]
        let steps = BabyPlan.session(d, newWords: [], reviews: reviews,
                                     known: Set(reviews), unlockAll: false,
                                     reviewDay: true, using: &rng)
        let learnSteps = steps.filter { if case .learn = $0 { return true }; return false }
        XCTAssertTrue(learnSteps.isEmpty, "复习日不学新词")
        let pickSteps = steps.compactMap { (s: BabyStep) -> [BabyGameKind]? in
            if case .pickGame(let g) = s { return g } else { return nil }
        }
        XCTAssertEqual(pickSteps.count, 1, "复习日未指定游戏时应先出戳泡泡选游戏步骤")
        XCTAssertEqual(pickSteps.first?.count, 3, "复习日应提供 3 个游戏泡泡")
    }

    /// 3 个新游戏的出题规则：翻翻乐 3 对不撞易混词、影子配对 3 选 1、Tom 说你做只出身体和动作词
    func testThreeNewGamesQuestionGeneration() throws {
        let d = try load()
        var rng = SeededGenerator(seed: 23)

        // 1. 翻翻乐 G1：6 张卡 = 3 对，同一屏不撞易混词、不用同一张图
        for pack in d.packs {
            let cards = BabyPlan.makeMemoryCards(d, targets: pack.words, known: Set(d.allWords), using: &rng)
            XCTAssertEqual(cards.count, 6, "\(pack.id): 翻翻乐固定 6 张卡")
            let unique = Array(Set(cards))
            XCTAssertEqual(unique.count, 3, "\(pack.id): 翻翻乐应由 3 个不同词各出现 2 次组成")
            for w in unique {
                XCTAssertEqual(cards.filter { $0 == w }.count, 2)
            }
            for a in unique {
                for b in unique where a != b {
                    XCTAssertFalse(Confusables.conflict(a, b), "翻翻乐同屏出现易混词 \(a) / \(b)")
                    XCTAssertNotEqual(d.picture(for: a), d.picture(for: b), "翻翻乐同屏用了同一张图")
                }
            }
        }

        // 2. 影子配对 G2：5 题，每题 3 选 1，不出纯色或数字词，不连着两题考同一个词
        let shadowRounds = BabyPlan.makeShadowRounds(d, targets: ["cat", "dog", "bird", "fish"],
                                                     known: Set(d.packs[0].words), unlockAll: false, using: &rng)
        XCTAssertEqual(shadowRounds.count, BabyPlan.gameRounds)
        for r in shadowRounds {
            XCTAssertEqual(r.options.count, 3)
            XCTAssertTrue(r.options.contains(r.answer))
            for opt in r.options {
                XCTAssertFalse(BabyPlan.nonShadowWords.contains(opt), "影子配对不应出纯色/数字词 \(opt)")
            }
        }
        for (a, b) in zip(shadowRounds.map(\.answer), shadowRounds.dropFirst().map(\.answer)) {
            XCTAssertNotEqual(a, b)
        }

        // 3. Tom 说你做 G5：只出身体和动作词
        let followWords = BabyPlan.makeFollowMeWords(d, targets: ["head", "nose", "jump", "clap"],
                                                     known: Set(d.allWords), count: 3, using: &rng)
        XCTAssertEqual(followWords.count, 3)
        for w in followWords {
            XCTAssertTrue(BabyPlan.followMeWords.contains(w), "\(w) 必须是身体或动作词")
            XCTAssertNotNil(BabyPlan.followMeCommands[w])
        }
    }

    func testReplayIsGameOnlyFromKnownWords() throws {
        let d = try load()
        var rng = SeededGenerator(seed: 3)
        let known: Set<String> = ["cat", "dog", "bird"]
        let steps = BabyPlan.replay(d, known: known, unlockAll: false, using: &rng)
        XCTAssertEqual(steps.last, .done)
        XCTAssertTrue(steps.count >= 2, "再玩一次至少有游戏步和完成页")
        for s in steps.dropLast() {
            XCTAssertEqual(s.stage, .play, "再玩一次只出第 4 步『玩一玩』小游戏")
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
        XCTAssertEqual(ProgressCodec.summary(snap), "已恢复：0 个单词")
        snap.babyWords = ["cat": BabyWordState(box: 1, due: "2026-10-24")]
        snap.babyStickers = ["2026-10-22": "cat"]
        let back = try XCTUnwrap(ProgressCodec.decode(ProgressCodec.encode(snap)))
        XCTAssertEqual(back.babyWords, snap.babyWords)
        XCTAssertEqual(back.babyStickers, snap.babyStickers)
        XCTAssertEqual(ProgressCodec.summary(back), "已恢复：0 个单词、启蒙模式 1 个词")
    }
}

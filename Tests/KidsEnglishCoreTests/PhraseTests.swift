import Foundation
import XCTest
@testable import KidsEnglishCore

/// 「说一说」口语课：直接读仓库里的 Resources/phrases，检查数据、素材、课内流程和解锁规则。
final class PhraseTests: XCTestCase {

    private var root: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    private var phrases: URL { root.appendingPathComponent("KidsEnglish/KidsEnglish/Resources/phrases") }

    private func loadCatalog() throws -> PhraseCatalog {
        let data = try Data(contentsOf: phrases.appendingPathComponent("phrases.json"))
        return try XCTUnwrap(PhraseCatalog.decode(data), "phrases.json 解不开")
    }

    private func exists(_ url: URL) -> Bool { FileManager.default.fileExists(atPath: url.path) }

    // MARK: - 数据与素材

    func testL1AndL2HaveSixLessonsEachWithReviewsAfterEveryThird() throws {
        let catalog = try loadCatalog()
        XCTAssertEqual(catalog.levels.map(\.level), [1, 2])
        XCTAssertEqual(catalog.allScenes.map(\.id), [
            "L1-1", "L1-2", "L1-3", "L1-R1", "L1-4", "L1-5", "L1-6", "L1-R2",
            "L2-1", "L2-2", "L2-3", "L2-R1", "L2-4", "L2-5", "L2-6", "L2-R2",
        ])
        let lines = catalog.allLessons.flatMap(\.lines)
        XCTAssertEqual(catalog.levels[0].scenes.filter { !$0.isReview }.flatMap(\.lines).count, 38)
        XCTAssertEqual(catalog.levels[1].scenes.filter { !$0.isReview }.flatMap(\.lines).count, 44)
        XCTAssertEqual(Set(lines.map(\.id)).count, lines.count, "句子 id 重复")
    }

    /// D8：孩子现在 5 岁，原稿的 I'm four. 改成 I'm five.（五根蜡烛）
    func testTomIsFive() throws {
        let line = try XCTUnwrap(loadCatalog().allLessons.flatMap(\.lines).first { $0.id == "L2-1-08" })
        XCTAssertEqual(line.en, "I'm five.")
        XCTAssertEqual(line.code, "candles")
        XCTAssertEqual(PhraseCodeCardSpec.candleCount, 5)
    }

    func testEveryLineHasAudioPictureAndSpeaker() throws {
        let catalog = try loadCatalog()
        let overrides = root.appendingPathComponent("assets/word-icons-overrides")
        let codeKinds = PhraseCodeCardSpec.kinds
        for line in catalog.allLessons.flatMap(\.lines) {
            XCTAssertTrue(exists(phrases.appendingPathComponent("audio/\(line.audio)")), "\(line.id): 缺音频")
            let sources = [line.image, line.icon, line.code].compactMap { $0 }
            XCTAssertEqual(sources.count, 1, "\(line.id): 配图必须是 image / icon / code 三选一")
            if let image = line.image {
                XCTAssertTrue(exists(phrases.appendingPathComponent("img/\(image)")), "\(line.id): 缺图 \(image)")
            }
            if let icon = line.icon {
                XCTAssertTrue(exists(overrides.appendingPathComponent("\(icon).jpg")), "\(line.id): 词图 \(icon) 不在仓库里")
            }
            if let code = line.code {
                XCTAssertTrue(codeKinds.contains(code), "\(line.id): App 里没有画法 \(code)")
            }
            for codeIcon in [line.codeIcon].compactMap({ $0 }) + (line.codeIcons ?? []) {
                XCTAssertTrue(exists(overrides.appendingPathComponent("\(codeIcon).jpg")), "\(line.id): 小图 \(codeIcon) 不在仓库里")
            }
            if line.code == "yes" || line.code == "no" {
                XCTAssertNotNil(line.codeIcon, "\(line.id): 对勾 / 叉要叠在一张小图上")
            }
            if line.code == "mood" {
                XCTAssertEqual(line.codeIcons?.count, 3, "\(line.id): 心情表是三张小图")
            }
            let speaker = try XCTUnwrap(catalog.character(line.speaker), "\(line.id): 说话人 \(line.speaker) 没登记")
            XCTAssertTrue(exists(phrases.appendingPathComponent("avatars/\(speaker.avatar)")), "\(speaker.id): 缺头像")
        }
    }

    /// 每张卡片图只给一句用（和产品经理的出图方案一致），孩子不会在两张卡上看到同一张图
    func testNoPictureIsUsedTwice() throws {
        // 复习课重放的是原句，不算第二次使用
        let lines = try loadCatalog().allLessons.flatMap(\.lines)
        let pictures = lines.compactMap { $0.image ?? $0.icon }
        XCTAssertEqual(Set(pictures).count, pictures.count)
    }

    /// L1 每句最多 4 个词（定稿的级别上限）
    func testL1LinesAreShort() throws {
        for line in try loadCatalog().levels[0].scenes.flatMap(\.lines) {
            let words = line.en.split(whereSeparator: { $0 == " " })
            XCTAssertLessThanOrEqual(words.count, 4, "\(line.id): \(line.en)")
        }
    }

    /// L2 每句最多 6 个词（What color is your new book?）
    func testL2LinesAreShort() throws {
        for line in try loadCatalog().levels[1].scenes.flatMap(\.lines) {
            let words = line.en.split(whereSeparator: { $0 == " " })
            XCTAssertLessThanOrEqual(words.count, 6, "\(line.id): \(line.en)")
        }
    }

    /// 头像下的名字用 Mother / Father，句子里保留 Mom / Dad（用户原话）
    func testParentsAreNamedMotherAndFatherButSentencesKeepMomDad() throws {
        let catalog = try loadCatalog()
        XCTAssertEqual(catalog.character("mom")?.nameEn, "Mother")
        XCTAssertEqual(catalog.character("dad")?.nameEn, "Father")
        let lines = catalog.allScenes.flatMap(\.lines).map(\.en)
        XCTAssertTrue(lines.contains("Good morning, Mom!"))
        XCTAssertTrue(lines.contains("Good evening, Dad!"))
    }

    func testPromptAudioExists() {
        for name in ["prompt_say", "prompt_again", "prompt_watch", "prompt_turn",
                     "prompt_great", "prompt_well", "prompt_yay", "prompt_done", "prompt_review"] {
            XCTAssertTrue(exists(phrases.appendingPathComponent("audio/\(name).mp3")), "缺旁白 \(name)")
        }
    }

    func testMirrorCopyIsIdentical() throws {
        let inner = try Data(contentsOf: phrases.appendingPathComponent("phrases.json"))
        let outer = try Data(contentsOf: root.appendingPathComponent("KidsEnglish/Resources/phrases/phrases.json"))
        XCTAssertEqual(inner, outer, "两份 phrases.json 不一致，重新跑 scripts/gen_phrases.py")
    }

    // MARK: - 课内流程

    func testFirstSceneHasNoWarmup() throws {
        let catalog = try loadCatalog()
        let scene = catalog.allScenes[0]
        let steps = PhraseLessonPlan.steps(for: scene, previous: catalog.scene(before: scene.id))
        let n = scene.lines.count
        XCTAssertEqual(steps.count, n + 1 + n + 1)
        XCTAssertEqual(steps.first, .learn(0))
        XCTAssertEqual(steps[n], .watch)
        XCTAssertEqual(steps.last, .done)
    }

    func testLaterScenesWarmUpWithTheLastTwoLinesOfThePreviousScene() throws {
        let catalog = try loadCatalog()
        let scene = catalog.allScenes[1]
        let previous = try XCTUnwrap(catalog.scene(before: scene.id))
        XCTAssertEqual(previous.id, "L1-1")
        let steps = PhraseLessonPlan.steps(for: scene, previous: previous)
        XCTAssertEqual(Array(steps.prefix(2)), previous.lines.suffix(2).map { PhraseStep.warmup($0) })
        XCTAssertEqual(steps[2], .learn(0))
    }

    /// 每句一节课里至少出现 3 次（学、看、轮到你），其中 1 次是回想
    func testEveryLineIsHeardThreeTimesWithOneRecall() throws {
        let catalog = try loadCatalog()
        for scene in catalog.allLessons {
            let steps = PhraseLessonPlan.steps(for: scene, previous: catalog.scene(before: scene.id))
            for i in scene.lines.indices {
                XCTAssertGreaterThanOrEqual(PhraseLessonPlan.exposures(of: i, in: steps), 3, "\(scene.id) 第 \(i) 句")
                XCTAssertTrue(steps.contains(.turn(i)), "\(scene.id) 第 \(i) 句没有回想")
            }
        }
    }

    // MARK: - L3–L7 代码卡

    private func loadPreview() throws -> PhraseCodePreview {
        let data = try Data(contentsOf: phrases.appendingPathComponent("code-preview.json"))
        return try XCTUnwrap(PhraseCodePreview.decode(data), "code-preview.json 解不开")
    }

    /// 出图方案里 L3–L7 的 52 张代码卡都有画法，App 都画得出来
    func testEveryLaterCodeCardHasADrawing() throws {
        let plan = try JSONSerialization.jsonObject(
            with: Data(contentsOf: root.appendingPathComponent("docs/daily-phrases/images-plan.json"))) as? [String: Any]
        let planned = (plan?["lines"] as? [[String: Any]] ?? [])
            .filter { $0["decision"] as? String == "code" && ($0["level"] as? Int ?? 0) >= 3 }
            .compactMap { $0["line_id"] as? String }
        let preview = try loadPreview().lines
        XCTAssertEqual(planned.count, 52)
        XCTAssertEqual(preview.map(\.id), planned)
        for line in preview {
            let code = try XCTUnwrap(line.code, line.id)
            XCTAssertTrue(PhraseCodeCardSpec.kinds.contains(code), "\(line.id): App 里没有画法 \(code)")
        }
    }

    func testLaterCodeCardParamsAreInRange() throws {
        let overrides = root.appendingPathComponent("assets/word-icons-overrides")
        for line in try loadPreview().lines {
            let code = line.code ?? ""
            let p = line.codeParams ?? PhraseCodeParams()
            var words = [line.codeIcon].compactMap { $0 }
            for slot in p.slots ?? [] {
                let items = PhraseSlot.parse(slot)
                XCTAssertEqual(items.count, slot.isEmpty ? 0 : slot.split(separator: "+").count, "\(line.id): 认不出 \(slot)")
                for case .icon(let w) in items { words.append(w) }
            }
            for w in words {
                XCTAssertTrue(exists(overrides.appendingPathComponent("\(w).jpg")), "\(line.id): 小图 \(w) 不在仓库里")
            }
            let limit: Int
            switch code {
            case "calendar", "yes": limit = PhraseCodeCardSpec.calendarCells
            case "crayons": limit = PhraseCodeCardSpec.crayonCount
            default: limit = p.slots?.count ?? 0
            }
            if let most = PhraseCodeCardSpec.slotCount[code], let slots = p.slots {
                XCTAssertLessThanOrEqual(slots.count, most, "\(line.id): 格子太多")
            }
            var marked: [Int] = []
            marked.append(contentsOf: p.glow ?? [])
            marked.append(contentsOf: p.blink ?? [])
            marked.append(contentsOf: p.star ?? [])
            marked.append(contentsOf: p.sticker ?? [])
            marked.append(contentsOf: p.faded ?? [])
            for i in marked {
                XCTAssertTrue((0..<limit).contains(i), "\(line.id): 第 \(i) 格不存在")
            }
            if code == "clock" {
                XCTAssertNotNil(PhraseClock.parse(p.time ?? ""), "\(line.id): 时间写错 \(p.time ?? "")")
                for t in [p.cross, p.pair].compactMap({ $0 }) {
                    XCTAssertNotNil(PhraseClock.parse(t), "\(line.id): 时间写错 \(t)")
                }
            }
            if code == "row" { XCTAssertNotNil(line.codeIcon); XCTAssertGreaterThan(p.count ?? 0, 0) }
        }
    }

    /// 钟面不写数字，全靠指针角度：几个关键时间的角度
    func testClockHandAngles() {
        XCTAssertEqual(PhraseClock.parse("2:30")?.hour, 2)
        XCTAssertEqual(PhraseClock.parse("2:30")?.minute, 30)
        XCTAssertNil(PhraseClock.parse("25:00"))
        XCTAssertNil(PhraseClock.parse("two"))
        let twelve = PhraseClock.angles(hour: 12, minute: 0)
        XCTAssertEqual(twelve.hour, 0); XCTAssertEqual(twelve.minute, 0)
        let halfNine = PhraseClock.angles(hour: 9, minute: 30)
        XCTAssertEqual(halfNine.hour, 285); XCTAssertEqual(halfNine.minute, 180)
        let quarterFive = PhraseClock.angles(hour: 5, minute: 15)
        XCTAssertEqual(quarterFive.minute, 90)
        // 3:58：长针差一点到 12
        XCTAssertEqual(PhraseClock.angles(hour: 3, minute: 58).minute, 348)
    }

    func testSlotParsing() {
        XCTAssertEqual(PhraseSlot.parse("sun+moon"), [.sun, .moon])
        XCTAssertEqual(PhraseSlot.parse("icon:boy+icon:girl"), [.icon("boy"), .icon("girl")])
        XCTAssertEqual(PhraseSlot.parse(""), [])
        XCTAssertEqual(PhraseSlot.parse("bag"), [.bag])
    }

    /// L3–L7 上线前，代码卡预览不会混进正式课程
    func testCodePreviewIsNotInTheCourse() throws {
        let course = Set(try loadCatalog().allLessons.flatMap(\.lines).map(\.id))
        XCTAssertTrue(try loadPreview().lines.allSatisfy { !course.contains($0.id) })
    }

    // MARK: - 复习课

    func testReviewPicksTwoLinesFromEachOfTheLastThreeLessonsInterleaved() throws {
        let catalog = try loadCatalog()
        let review = try XCTUnwrap(catalog.allScenes.first { $0.id == "L1-R1" })
        XCTAssertTrue(review.isReview)
        let lessons = catalog.allLessons.prefix(3)
        let expected = (0..<2).flatMap { r in lessons.map { r == 0 ? $0.lines[0] : $0.lines[$0.lines.count / 2] } }
        XCTAssertEqual(review.lines, expected)
        // 同一课的两句不挨着
        for pair in zip(review.lines, review.lines.dropFirst()) {
            XCTAssertNotEqual(pair.0.id.prefix(4), pair.1.id.prefix(4))
        }
        // 只放学过的句子，不出新句
        let learned = Set(lessons.flatMap(\.lines).map(\.id))
        XCTAssertTrue(review.lines.allSatisfy { learned.contains($0.id) })
    }

    func testReviewIsRecallOnlyWithNoWarmup() throws {
        let catalog = try loadCatalog()
        for review in catalog.allScenes where review.isReview {
            XCTAssertNil(catalog.scene(before: review.id))
            let steps = PhraseLessonPlan.steps(for: review, previous: catalog.scene(before: review.id))
            XCTAssertEqual(steps, review.lines.indices.map { PhraseStep.turn($0) } + [.done])
            XCTAssertTrue(steps.dropLast().allSatisfy(\.isRecall))
        }
    }

    /// 复习课后面的新课照样回想上一节新课（不是复习课）的最后两句
    func testLessonAfterReviewWarmsUpFromThePreviousLesson() throws {
        let catalog = try loadCatalog()
        XCTAssertEqual(catalog.scene(before: "L1-4")?.id, "L1-3")
        XCTAssertEqual(catalog.scene(before: "L2-1")?.id, "L1-6")
        XCTAssertEqual(catalog.scene(before: "L2-4")?.id, "L2-3")
    }

    func testReviewSitsOnThePathAndMustBeDoneToGoOn() throws {
        let levels = try loadCatalog().levels
        let firstThree: Set<String> = ["L1-1", "L1-2", "L1-3"]
        XCTAssertEqual(PhraseUnlock.next(levels: levels, completed: firstThree), "L1-R1")
        XCTAssertFalse(PhraseUnlock.unlocked(levels: levels, completed: firstThree, unlockAll: false).contains("L1-4"))
        XCTAssertTrue(PhraseUnlock.unlocked(levels: levels, completed: firstThree.union(["L1-R1"]), unlockAll: false)
            .contains("L1-4"))
    }

    func testFewerThanThreeLessonsGetNoReview() {
        func scene(_ id: String) -> PhraseScene { PhraseScene(id: id, titleZh: id, titleEn: id, lines: []) }
        let levels = PhraseReview.inserting(into: [PhraseLevel(level: 9, titleZh: "九", scenes: [scene("L9-1"), scene("L9-2")])])
        XCTAssertEqual(levels[0].scenes.map(\.id), ["L9-1", "L9-2"])
        XCTAssertTrue(PhraseReview.isReview("L9-R1"))
        XCTAssertFalse(PhraseReview.isReview("L9-1"))
    }

    // MARK: - 解锁

    private func fakeLevels() -> [PhraseLevel] {
        func scene(_ id: String) -> PhraseScene { PhraseScene(id: id, titleZh: id, titleEn: id, lines: []) }
        return [
            PhraseLevel(level: 1, titleZh: "一", scenes: [scene("L1-1"), scene("L1-2")]),
            PhraseLevel(level: 2, titleZh: "二", scenes: [scene("L2-1"), scene("L2-2")]),
        ]
    }

    func testFreshStartOnlyOpensTheFirstScene() {
        XCTAssertEqual(PhraseUnlock.unlocked(levels: fakeLevels(), completed: [], unlockAll: false), ["L1-1"])
        XCTAssertEqual(PhraseUnlock.next(levels: fakeLevels(), completed: []), "L1-1")
    }

    func testNextLevelOpensOnlyAfterTheWholeLevelIsDone() {
        let levels = fakeLevels()
        XCTAssertEqual(PhraseUnlock.unlocked(levels: levels, completed: ["L1-1"], unlockAll: false),
                       ["L1-1", "L1-2"])
        XCTAssertEqual(PhraseUnlock.unlocked(levels: levels, completed: ["L1-1", "L1-2"], unlockAll: false),
                       ["L1-1", "L1-2", "L2-1"])
        XCTAssertEqual(PhraseUnlock.next(levels: levels, completed: ["L1-1", "L1-2"]), "L2-1")
    }

    func testParentUnlockAllOpensEverything() {
        XCTAssertEqual(PhraseUnlock.unlocked(levels: fakeLevels(), completed: [], unlockAll: true).count, 4)
    }

    // MARK: - 跟读判定

    func testSilenceIsNotSpeech() {
        XCTAssertFalse(SpeakCheck.didSpeak(peakDB: -50))
        XCTAssertTrue(SpeakCheck.didSpeak(peakDB: -20))
    }

    /// 没出声：第一次再邀请，第二次照样放行，不会卡住
    func testSilentChildIsInvitedOnceThenMovesOn() {
        XCTAssertFalse(SpeakCheck.shouldMoveOn(attempt: 1, spoke: false))
        XCTAssertTrue(SpeakCheck.shouldMoveOn(attempt: 2, spoke: false))
        XCTAssertTrue(SpeakCheck.shouldMoveOn(attempt: 1, spoke: true))
    }

    // MARK: - 收集卡与备份

    func testPhraseCardsShowTheSceneName() throws {
        let catalog = try loadCatalog()
        XCTAssertEqual(PhraseCards.id(for: "L1-1"), "phrase:L1-1")
        XCTAssertEqual(PhraseCards.title(for: "phrase:L1-1", catalog: catalog), "Hello!")
        XCTAssertEqual(PhraseCards.title(for: "apple", catalog: catalog), "apple")
    }

    /// 旧备份没有口语进度：解码为 nil（恢复时不覆盖本机进度），恢复文案和以前一样
    func testOldBackupDecodesWithoutPhraseProgress() throws {
        let old = """
        {"collectedCards":[],"completedLessons":["l1-01"],"dailyNewWords":10,"exportedAt":"x",
         "favoriteWords":[],"gameAnswered":0,"gameCorrect":0,"learnedWords":["apple"],"quizBest":{},
         "showTranslationDefault":true,"studyDates":[],"timeLimitMinutes":20,"version":1}
        """
        let snapshot = try XCTUnwrap(ProgressCodec.decode(old))
        XCTAssertNil(snapshot.completedPhraseScenes)
        XCTAssertEqual(ProgressCodec.summary(snapshot), "已恢复：1 个单词")
    }

    func testPhraseProgressRoundTripsAndShowsInSummary() throws {
        var snapshot = try XCTUnwrap(ProgressCodec.decode("""
        {"collectedCards":[],"completedLessons":[],"dailyNewWords":10,"exportedAt":"x",
         "favoriteWords":[],"gameAnswered":0,"gameCorrect":0,"learnedWords":[],"quizBest":{},
         "showTranslationDefault":true,"studyDates":[],"timeLimitMinutes":20,"version":1}
        """))
        snapshot.completedPhraseScenes = ["L1-1", "L1-2"]
        let back = try XCTUnwrap(ProgressCodec.decode(ProgressCodec.encode(snapshot)))
        XCTAssertEqual(back.completedPhraseScenes, ["L1-1", "L1-2"])
        XCTAssertEqual(ProgressCodec.summary(back), "已恢复：0 个单词、2 个口语场景")
    }
}

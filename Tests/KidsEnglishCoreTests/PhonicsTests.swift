import Foundation
import XCTest
@testable import KidsEnglishCore

final class PhonicsTests: XCTestCase {

    private var root: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    private var resources: URL { root.appendingPathComponent("KidsEnglish/KidsEnglish/Resources") }
    private var phraseAudioDir: URL { resources.appendingPathComponent("phrases/audio") }
    private var overridesDir: URL { root.appendingPathComponent("assets/word-icons-overrides") }

    // MARK: - 阶段 2：Group 1 字母音目录与数据完整性

    func testGroup1CatalogIntegrity() throws {
        let group1 = PhonicsCatalog.group1
        XCTAssertEqual(group1.count, 6)
        XCTAssertEqual(group1.map(\.letter), ["s", "a", "t", "i", "p", "n"])

        for letter in group1 {
            XCTAssertFalse(letter.id.isEmpty)
            XCTAssertFalse(letter.phoneme.isEmpty)
            XCTAssertFalse(letter.word.isEmpty)
            XCTAssertFalse(letter.wordZh.isEmpty)
            XCTAssertFalse(letter.actionZh.isEmpty)
            XCTAssertFalse(letter.chantEn.isEmpty)
            XCTAssertFalse(letter.audio.isEmpty)
            XCTAssertEqual(PhonicsCatalog.letter(for: letter.id), letter)
            XCTAssertEqual(PhonicsCatalog.letter(for: letter.id.uppercased()), letter, "支持大小写不敏感查找")
        }

        XCTAssertNil(PhonicsCatalog.letter(for: "z"))
    }

    // MARK: - 阶段 2：物理资源存在性（平涂大图与标准音频）

    func testAnchorWordsExistInAssetsAndAudio() throws {
        let group1 = PhonicsCatalog.group1

        for item in group1 {
            // 1. 平涂大图必须物理存在（overrides 或 word-icons 目录）
            let picInOverrides = FileManager.default.fileExists(atPath: overridesDir.appendingPathComponent("\(item.word).jpg").path)
            let picInWordIcons = FileManager.default.fileExists(atPath: resources.appendingPathComponent("word-icons/\(item.word).jpg").path)
            XCTAssertTrue(picInOverrides || picInWordIcons,
                          "\(item.word): 锚点词平涂大图不存在")

            // 2. 顺口溜音频必须物理存在
            let audioFile = phraseAudioDir.appendingPathComponent("\(item.audio).mp3")
            XCTAssertTrue(FileManager.default.fileExists(atPath: audioFile.path),
                          "\(item.audio).mp3: 顺口溜发音文件不存在")
        }

        // 3. Tom 引导音物理存在
        let welcomeFile = phraseAudioDir.appendingPathComponent("tom_phonics_island.mp3")
        XCTAssertTrue(FileManager.default.fileExists(atPath: welcomeFile.path), "tom_phonics_island.mp3 不存在")

        let findSoundFile = phraseAudioDir.appendingPathComponent("tom_find_sound.mp3")
        XCTAssertTrue(FileManager.default.fileExists(atPath: findSoundFile.path), "tom_find_sound.mp3 不存在")
    }

    // MARK: - 阶段 2：听音辨字母出题算法

    func testQuizRoundGeneration() throws {
        var rng = SeededGenerator(seed: 101)

        for _ in 0..<10 {
            let rounds = PhonicsEngine.makeQuizRounds(count: 4, using: &rng)
            XCTAssertEqual(rounds.count, 4)

            for round in rounds {
                XCTAssertEqual(round.options.count, 3, "每题固定 3 选 1")
                XCTAssertTrue(round.options.contains(round.target), "选项必须包含目标音")
                XCTAssertEqual(Set(round.options.map(\.id)).count, 3, "同一题 3 个选项不能重复")
            }
        }
    }

    // MARK: - 阶段 3：CVC 拼读词目录与数据完整性

    func testCVCGroup1CatalogIntegrity() throws {
        let cvcList = PhonicsCatalog.cvcGroup1
        XCTAssertEqual(cvcList.count, 3, "首批先锋上线 3 个核心词（sit, pan, pin）")
        XCTAssertEqual(cvcList.map(\.id), ["sit", "pan", "pin"])

        let validLetters = Set(["s", "a", "t", "i", "p", "n"])
        for item in cvcList {
            XCTAssertEqual(item.letters.count, 3, "\(item.word) 必须为 3 字母 CVC")
            XCTAssertEqual(item.phonemes.count, 3)
            XCTAssertFalse(item.meaningZh.isEmpty)
            XCTAssertFalse(item.chantEn.isEmpty)
            XCTAssertFalse(item.audio.isEmpty)
            XCTAssertFalse(item.picture.isEmpty)
            XCTAssertTrue(Set(item.letters).isSubset(of: validLetters), "\(item.word) 必须完全由 Group 1 字母组成")
            XCTAssertEqual(PhonicsCatalog.blendWord(for: item.id), item)
            XCTAssertEqual(PhonicsCatalog.blendWord(for: item.id.uppercased()), item)
        }
    }

    // MARK: - 阶段 3：CVC 专属平涂大图与拼读音频物理存在性

    func testCVCPhysicalAssetsExist() throws {
        let cvcList = PhonicsCatalog.cvcGroup1

        for item in cvcList {
            // 1. 真实平涂大图必须存在
            let picInOverrides = FileManager.default.fileExists(atPath: overridesDir.appendingPathComponent("\(item.picture)").path)
            let picInWordIcons = FileManager.default.fileExists(atPath: resources.appendingPathComponent("word-icons/\(item.picture)").path)
            XCTAssertTrue(picInOverrides || picInWordIcons, "\(item.picture): CVC 专属手绘大图不存在")

            // 2. 拼读顺口溜音频必须存在
            let audioFile = phraseAudioDir.appendingPathComponent("\(item.audio).mp3")
            XCTAssertTrue(FileManager.default.fileExists(atPath: audioFile.path), "\(item.audio).mp3 不存在")
        }

        // 3. 小火车引导与特效音频物理存在
        let introFile = phraseAudioDir.appendingPathComponent("tom_train_intro.mp3")
        XCTAssertTrue(FileManager.default.fileExists(atPath: introFile.path), "tom_train_intro.mp3 不存在")

        let missingFile = phraseAudioDir.appendingPathComponent("tom_train_missing.mp3")
        XCTAssertTrue(FileManager.default.fileExists(atPath: missingFile.path), "tom_train_missing.mp3 不存在")

        let whistleFile = phraseAudioDir.appendingPathComponent("train_whistle.mp3")
        XCTAssertTrue(FileManager.default.fileExists(atPath: whistleFile.path), "train_whistle.mp3 不存在")
    }

    // MARK: - 阶段 3：小火车装车厢拼词测验出题算法

    func testCargoQuizRoundGeneration() throws {
        var rng = SeededGenerator(seed: 202)

        for _ in 0..<10 {
            let rounds = PhonicsEngine.makeCargoRounds(count: 4, using: &rng)
            XCTAssertEqual(rounds.count, 4)

            for round in rounds {
                XCTAssertEqual(round.options.count, 3, "每题固定 3 选 1")
                XCTAssertTrue(round.missingIndex >= 0 && round.missingIndex < 3, "缺失索引必须在 0..<3 内")
                XCTAssertEqual(round.correctLetter, round.targetWord.letters[round.missingIndex])
                XCTAssertTrue(round.options.contains(round.correctLetter), "选项必须包含正确字母")
                XCTAssertEqual(Set(round.options).count, 3, "3 个备选车厢字母不能重复")
            }
        }
    }
}

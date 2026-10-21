import Foundation
import XCTest
@testable import KidsEnglishCore

/// 喂小动物：数据（feed-pairs.json）、出题、拖放判定
final class FeedGameTests: XCTestCase {

    private var root: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    private var resources: URL { root.appendingPathComponent("KidsEnglish/KidsEnglish/Resources") }

    private func loadCatalog() throws -> FeedCatalog {
        let data = try Data(contentsOf: resources.appendingPathComponent("feed-pairs.json"))
        return try XCTUnwrap(FeedCatalog.decode(data))
    }

    private func pair(_ animal: String, _ food: String) -> FeedPair {
        FeedPair(animal: animal, food: food, want: "I want a \(food)!", yummy: "Yummy \(food)!")
    }

    func testCatalogIsValidAndUsesKnownFlatWords() throws {
        let catalog = try loadCatalog()
        XCTAssertEqual(FeedGame.problems(in: catalog), [])
        XCTAssertEqual(catalog.noThanks, "No, thank you!")
        XCTAssertEqual(catalog.pairs.first?.animal, "monkey")
        XCTAssertEqual(catalog.pairs.first?.food, "banana")

        let themes = try JSONDecoder().decode([WordTheme].self,
            from: Data(contentsOf: resources.appendingPathComponent("word-themes.json")))
        let vocabulary = Set(themes.flatMap { $0.words }.map { $0.lowercased() })
        // 不碰交通、自然两类词图
        let offLimits = Set(themes.filter { ["vehicles", "nature"].contains($0.id) }.flatMap { $0.words }.map { $0.lowercased() })
        for p in catalog.pairs {
            for w in [p.animal, p.food] {
                XCTAssertTrue(vocabulary.contains(w), "\(w) 不在 word-themes.json")
                XCTAssertFalse(offLimits.contains(w), "\(w) 属于交通/自然")
                let icon = root.appendingPathComponent("assets/word-icons-overrides/\(w).jpg")
                XCTAssertTrue(FileManager.default.fileExists(atPath: icon.path), "\(w) 没有平涂词图")
            }
        }
        // 两份 Resources 必须一致
        let mirror = try Data(contentsOf: root.appendingPathComponent("KidsEnglish/Resources/feed-pairs.json"))
        XCTAssertEqual(FeedCatalog.decode(mirror), catalog)
    }

    func testArticlesInWantLines() throws {
        let byFood = Dictionary(try loadCatalog().pairs.map { ($0.food, $0.want) }, uniquingKeysWith: { a, _ in a })
        XCTAssertEqual(byFood["banana"], "I want a banana!")
        XCTAssertEqual(byFood["apple"], "I want an apple!")
        XCTAssertEqual(byFood["honey"], "I want some honey!")
        XCTAssertEqual(byFood["milk"], "I want some milk!")
        XCTAssertEqual(byFood["vegetable"], "I want some vegetables!")
    }

    func testEveryLineHasAudio() throws {
        let catalog = try loadCatalog()
        let map = try XCTUnwrap(try JSONSerialization.jsonObject(with:
            Data(contentsOf: resources.appendingPathComponent("custom-audio-map.json"))) as? [String: String])
        var keys = [FeedGame.noThanksKey]
        for p in catalog.pairs { keys += [FeedGame.wantKey(p.food), FeedGame.yummyKey(p.food)] }
        for key in keys {
            let file = try XCTUnwrap(map[key], "custom-audio-map.json 缺 \(key)")
            XCTAssertTrue(FileManager.default.fileExists(atPath: resources.appendingPathComponent("audio/\(file)").path),
                          "\(key) 的音频文件 \(file) 不存在")
        }
    }

    func testRoundsAreFiveDistinctAnimalsWithThreeOptions() throws {
        let pairs = try loadCatalog().pairs
        for seed in UInt64(0)..<300 {
            var rng = SeededGenerator(seed: seed)
            let rounds = FeedGame.makeRounds(pairs, using: &rng)
            XCTAssertEqual(rounds.count, 5)
            XCTAssertEqual(Set(rounds.map(\.pair.animal)).count, 5, "seed \(seed): 动物重复")
            for r in rounds {
                XCTAssertEqual(r.options.count, 3)
                XCTAssertEqual(Set(r.options).count, 3, "seed \(seed): 选项重复 \(r.options)")
                XCTAssertEqual(r.options.filter { $0 == r.pair.food }.count, 1, "seed \(seed): 正确答案应只有 1 个")
                XCTAssertNotNil(r.correctIndex)
            }
        }
    }

    func testSharedFoodIsNeverADistractorForItsOwnAnimal() {
        // 蜜蜂和熊都吃 honey：honey 只能当正确答案出现一次
        let pairs = [pair("bee", "honey"), pair("bear", "honey"), pair("cat", "fish"), pair("monkey", "banana")]
        for seed in UInt64(0)..<100 {
            var rng = SeededGenerator(seed: seed)
            for r in FeedGame.makeRounds(pairs, count: 4, using: &rng) {
                XCTAssertEqual(Set(r.options).count, 3)
                XCTAssertEqual(r.options.filter { $0 == r.pair.food }.count, 1)
            }
        }
    }

    func testSameSeedSameRounds() throws {
        let pairs = try loadCatalog().pairs
        var a = SeededGenerator(seed: 7), b = SeededGenerator(seed: 7)
        XCTAssertEqual(FeedGame.makeRounds(pairs, using: &a), FeedGame.makeRounds(pairs, using: &b))
        var c = SeededGenerator(seed: 7)
        let fixed = FeedGame.makeRounds(pairs, shuffleAnimals: false, using: &c)
        XCTAssertEqual(fixed.map(\.pair.animal), ["monkey", "rabbit", "cat", "dog", "mouse"])
    }

    func testDropZoneIsThirtyPercentLarger() {
        let frame = CGRect(x: 100, y: 100, width: 200, height: 200)
        let zone = FeedGame.dropZone(around: frame)
        XCTAssertEqual(Double(zone.size.width), 260, accuracy: 0.001)
        XCTAssertEqual(Double(zone.size.height), 260, accuracy: 0.001)
        XCTAssertEqual(Double(zone.origin.x), 70, accuracy: 0.001)   // 中心不变：四边各外扩 30
        XCTAssertEqual(Double(zone.origin.y), 70, accuracy: 0.001)

        let round = FeedRound(pair: pair("monkey", "banana"), options: ["apple", "banana", "fish"])
        XCTAssertEqual(round.correctIndex, 1)
        // 图框外、但在外扩 15% 以内 → 算拖到了
        XCTAssertEqual(FeedGame.outcome(dropping: "banana", at: CGPoint(x: 325, y: 200), round: round, animalFrame: frame), .eaten)
        XCTAssertEqual(FeedGame.outcome(dropping: "fish", at: CGPoint(x: 200, y: 75), round: round, animalFrame: frame), .refused)
        // 超出判定区 → 只弹回
        XCTAssertEqual(FeedGame.outcome(dropping: "banana", at: CGPoint(x: 335, y: 200), round: round, animalFrame: frame), .missed)
        XCTAssertEqual(FeedGame.outcome(dropping: "fish", at: CGPoint(x: 200, y: 500), round: round, animalFrame: frame), .missed)
    }
}

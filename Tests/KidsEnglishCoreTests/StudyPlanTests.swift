import XCTest
@testable import KidsEnglishCore

/// 每日新词计划的排序/分天规则。
/// 背景：原来「先学完一个主题再下一个」，动作(83)/形容词(81) 排在最后，
/// 每天 10 词时要到第 29 天才见到玩具、第 38 天才开始形容词。
final class StudyPlanTests: XCTestCase {

    private struct Item: Equatable {
        let word: String
        let tier: Int
        let index: Int
        let level: Int
    }

    private func order(_ items: [Item]) -> [String] {
        StudyPlan.interleavedOrder(items,
                                   rank: { StudyPlan.Rank(tier: $0.tier, index: $0.index) },
                                   level: { $0.level })
            .map(\.word)
    }

    func testInterleavesByWave() {
        let themes: [[String]] = [["a1", "a2", "a3"], ["b1"], ["c1", "c2"]]
        var items: [Item] = []
        for (tier, words) in themes.enumerated() {
            for (index, word) in words.enumerated() {
                items.append(Item(word: word, tier: tier, index: index, level: 1))
            }
        }
        // 第 0 波是每个主题的第一个词，第 1 波是第二个词……
        XCTAssertEqual(order(items), ["a1", "b1", "c1", "a2", "c2", "a3"])
    }

    func testFirstDayCoversManyThemes() {
        // 15 个主题、每个 5 个词，模拟真实词表结构
        var items: [Item] = []
        for tier in 0..<15 {
            for index in 0..<5 {
                items.append(Item(word: "t\(tier)w\(index)", tier: tier, index: index, level: 1))
            }
        }
        let days = StudyPlan.chunked(StudyPlan.interleavedOrder(
            items,
            rank: { StudyPlan.Rank(tier: $0.tier, index: $0.index) },
            level: { $0.level }), size: 10)

        XCTAssertEqual(days.count, 8)   // 75 个词 / 每天 10 个
        let firstDayThemes = Set(days[0].map(\.tier))
        XCTAssertEqual(firstDayThemes.count, 10, "第一天应该覆盖 10 个不同主题")
        // 第二天补齐剩下的 5 个主题
        let secondDayThemes = Set(days[1].map(\.tier))
        XCTAssertTrue(secondDayThemes.isSubset(of: Set(5..<15)))
    }

    func testChunkedSplitsEvenly() {
        let days = StudyPlan.chunked(Array(0..<25), size: 10)
        XCTAssertEqual(days.map(\.count), [10, 10, 5])
        XCTAssertEqual(days.flatMap { $0 }, Array(0..<25))
    }

    func testChunkedHandlesEmptyAndBadSize() {
        XCTAssertTrue(StudyPlan.chunked([Int](), size: 10).isEmpty)
        XCTAssertEqual(StudyPlan.chunked([1, 2, 3], size: 0).map(\.count), [1, 1, 1])
        XCTAssertEqual(StudyPlan.chunked([1, 2, 3], size: -5).map(\.count), [1, 1, 1])
    }

    func testTieBreakByTierThenLevel() {
        let items = [
            Item(word: "late-tier", tier: 9, index: 0, level: 1),
            Item(word: "early-tier", tier: 1, index: 0, level: 3),
            Item(word: "easy", tier: 1, index: 0, level: 1),
            Item(word: "wave1", tier: 5, index: 1, level: 1),
        ]
        XCTAssertEqual(order(items), ["easy", "early-tier", "late-tier", "wave1"])
    }

    func testStableForSameWordTwice() {
        let items = [
            Item(word: "x", tier: 2, index: 0, level: 1),
            Item(word: "y", tier: 2, index: 0, level: 1),
        ]
        XCTAssertEqual(Set(order(items)), Set(["x", "y"]))
    }
}

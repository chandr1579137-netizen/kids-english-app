import Foundation

/// 每日新词计划的排序与分天规则。
///
/// 原来的排序是「先把一个主题学完再下一个」，而 word-themes 的顺序里
/// 动作(83)、形容词(81)排在最后 —— 每天 10 个词的话，孩子要学到第 29 天
/// 才碰到玩具，第 38 天才开始学形容词之外的东西。改成按「主题内第几个词」
/// 分波交错后，第一天就能覆盖 10 个不同主题，不会连续几天只学动词。
enum StudyPlan {
    /// 主题优先级 + 主题内序号
    struct Rank: Equatable {
        let tier: Int
        let index: Int

        init(tier: Int, index: Int) {
            self.tier = tier
            self.index = index
        }
    }

    /// 交错排序：先按主题内序号分波（第 0 波是每个主题的第一个词），
    /// 同一波内再按主题优先级，最后按难度兜底。
    static func interleavedOrder<T>(_ items: [T],
                                    rank: (T) -> Rank,
                                    level: (T) -> Int) -> [T] {
        items.sorted { a, b in
            let ra = rank(a)
            let rb = rank(b)
            if ra.index != rb.index { return ra.index < rb.index }
            if ra.tier != rb.tier { return ra.tier < rb.tier }
            return level(a) < level(b)
        }
    }

    /// 按每天 size 个切分；size 至少为 1。
    static func chunked<T>(_ items: [T], size: Int) -> [[T]] {
        let perDay = max(1, size)
        guard !items.isEmpty else { return [] }
        var days: [[T]] = []
        var start = 0
        while start < items.count {
            let end = min(start + perDay, items.count)
            days.append(Array(items[start..<end]))
            start = end
        }
        return days
    }
}

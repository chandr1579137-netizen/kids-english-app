import Foundation

// MARK: - 宝宝模式（4 岁）：词包、每日计划、复习间隔、出题（纯 Foundation，便于单测）
//
// 数据在 Resources/baby-path.json。孩子每天：复习到期的旧词（听音选图）→ 学 3 个新词 →
// 听音选图小游戏 → 得一张今天的贴纸。约 5–7 分钟。设计依据见 docs/pm/baby-mode-v1.md。

struct BabyPack: Codable, Hashable, Identifiable {
    let id: String
    let nameZh: String
    let songId: String?
    /// 默认锁着的包（家长中心可全部解锁；前面的包都学完也会自动打开）
    let locked: Bool
    let words: [String]
}

struct BabyPathData: Codable, Hashable {
    let version: Int
    /// 发音用的词 → 配图用的词（mom 用 mother 的平涂图）
    let pictures: [String: String]
    let packs: [BabyPack]

    static func decode(_ data: Data) -> BabyPathData? {
        try? JSONDecoder().decode(BabyPathData.self, from: data)
    }

    func picture(for word: String) -> String { pictures[word] ?? word }

    var allWords: [String] { packs.flatMap(\.words) }

    func pack(containing word: String) -> BabyPack? {
        packs.first { $0.words.contains(word) }
    }
}

/// 一个词的复习状态：第几格（越大隔得越久）+ 下次该复习的日子（yyyy-MM-dd）
struct BabyWordState: Codable, Equatable {
    var box: Int
    var due: String
}

/// 听音选图的一道题
struct BabyRound: Equatable, Hashable {
    let answer: String
    let options: [String]
}

enum BabyStep: Equatable, Hashable {
    /// 复习：听音选图（旧词）
    case review(BabyRound)
    /// 学新词：一词一卡
    case learn(String)
    /// 小游戏：听音选图（今天的新词 + 复习词）
    case game(BabyRound)
    case done
}

enum BabyPlan {
    /// 复习间隔（天）：第 0 格明天复习，之后 2、4、7、14、30 天
    static let intervals = [1, 2, 4, 7, 14, 30]
    /// 每天最多复习几个旧词
    static let reviewLimit = 4
    /// 小游戏几道题、每题几个选项（4 岁：大图 3 选 1）
    static let gameRounds = 5
    static let optionCount = 3

    // MARK: 解锁

    /// 能学的包：没锁的 + 家长全部解锁 + 前面的包都学完后，按顺序打开下一个锁着的包
    static func openPacks(_ data: BabyPathData, known: Set<String>, unlockAll: Bool) -> [BabyPack] {
        if unlockAll { return data.packs }
        var open = data.packs.filter { !$0.locked }
        let allOpenKnown = open.allSatisfy { $0.words.allSatisfy(known.contains) }
        if allOpenKnown, let next = data.packs.first(where: { $0.locked && !$0.words.allSatisfy(known.contains) }) {
            open.append(next)
        }
        // 已经学过词的锁包也算开着（家长中途关掉「全部解锁」时，学过的不收回）
        for p in data.packs where p.locked && !open.contains(p) && p.words.contains(where: known.contains) {
            open.append(p)
        }
        return data.packs.filter { open.contains($0) }
    }

    // MARK: 每日计划

    /// 今天的新词：按包的顺序，跳过学过的，取 count 个
    static func newWords(_ data: BabyPathData, known: Set<String>, unlockAll: Bool, count: Int) -> [String] {
        let pool = openPacks(data, known: known, unlockAll: unlockAll).flatMap(\.words)
        return Array(pool.filter { !known.contains($0) }.prefix(max(0, count)))
    }

    /// 今天到期的旧词：先复习最早到期的，同一天到期的先复习格子小的（记得最不牢的）
    static func dueReviews(_ states: [String: BabyWordState], today: String, limit: Int = reviewLimit) -> [String] {
        states
            .filter { $0.value.due <= today }
            .sorted { ($0.value.due, $0.value.box, $0.key) < ($1.value.due, $1.value.box, $1.key) }
            .prefix(limit)
            .map(\.key)
    }

    /// 刚学会的新词：放进第 0 格，明天复习
    static func learned(today: Date, timeZone: TimeZone) -> BabyWordState {
        BabyWordState(box: 0, due: dayKey(today, plus: intervals[0], timeZone: timeZone))
    }

    /// 答题之后：一次答对升一格（隔得更久），答错回到第 0 格明天再来
    static func after(_ state: BabyWordState, correct: Bool, today: Date, timeZone: TimeZone) -> BabyWordState {
        let box = correct ? min(state.box + 1, intervals.count - 1) : 0
        return BabyWordState(box: box, due: dayKey(today, plus: intervals[box], timeZone: timeZone))
    }

    static func dayKey(_ date: Date, plus days: Int, timeZone: TimeZone) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let shifted = cal.date(byAdding: .day, value: days, to: date) ?? date
        return DayKey.key(for: shifted, timeZone: timeZone)
    }

    // MARK: 出题

    /// 听音选图：答案 + 从 pool 里挑干扰项（跳过易混词，配图也不能撞），选项顺序打乱
    static func round(answer: String, pool: [String], data: BabyPathData,
                      using rng: inout some RandomNumberGenerator) -> BabyRound {
        var chosen: [String] = []
        for candidate in pool.shuffled(using: &rng) {
            if chosen.count >= optionCount - 1 { break }
            if candidate == answer || chosen.contains(candidate) { continue }
            let clash = ([answer] + chosen).contains { other in
                Confusables.conflict(candidate, other)
                    || Confusables.conflict(data.picture(for: candidate), data.picture(for: other))
                    || data.picture(for: candidate) == data.picture(for: other)
            }
            if clash { continue }
            chosen.append(candidate)
        }
        return BabyRound(answer: answer, options: ([answer] + chosen).shuffled(using: &rng))
    }

    /// 一次「今天」的全部步骤
    static func session(_ data: BabyPathData, newWords: [String], reviews: [String], known: Set<String>,
                        unlockAll: Bool, using rng: inout some RandomNumberGenerator) -> [BabyStep] {
        // 干扰项从开着的包里挑：都是孩子见过或今天会见到的图
        let pool = openPacks(data, known: known.union(newWords), unlockAll: unlockAll).flatMap(\.words)
        var steps: [BabyStep] = reviews.map { .review(round(answer: $0, pool: pool, data: data, using: &rng)) }
        steps += newWords.map { .learn($0) }
        // 小游戏：新词每个至少考一次，剩下的题从复习词里补；都不够就再考新词
        var targets = newWords
        var extra = reviews.shuffled(using: &rng) + newWords.shuffled(using: &rng)
        while targets.count < gameRounds, !extra.isEmpty { targets.append(extra.removeFirst()) }
        if !targets.isEmpty {
            // 同一个词不连着考
            var ordered: [String] = []
            var rest = targets.shuffled(using: &rng)
            while !rest.isEmpty {
                let i = rest.firstIndex { $0 != ordered.last } ?? 0
                ordered.append(rest.remove(at: i))
            }
            steps += ordered.map { .game(round(answer: $0, pool: pool, data: data, using: &rng)) }
        }
        steps.append(.done)
        return steps
    }

    /// 今天已经完成后「再玩一次」：只玩听音选图，从学过的词里出题，不改复习进度
    static func replay(_ data: BabyPathData, known: Set<String>, unlockAll: Bool,
                       using rng: inout some RandomNumberGenerator) -> [BabyStep] {
        let pool = openPacks(data, known: known, unlockAll: unlockAll).flatMap(\.words)
        let learned = data.allWords.filter(known.contains)
        guard !learned.isEmpty else { return [.done] }
        var picks = Array(learned.shuffled(using: &rng).prefix(gameRounds))
        while picks.count < gameRounds { picks.append(learned.randomElement(using: &rng)!) }
        return picks.map { .game(round(answer: $0, pool: pool, data: data, using: &rng)) } + [.done]
    }

    /// 今天的贴纸：今天学的第一个新词；没有新词就用今天复习的第一个词
    static func sticker(for steps: [BabyStep]) -> String? {
        for s in steps { if case .learn(let w) = s { return w } }
        for s in steps { if case .review(let r) = s { return r.answer } }
        for s in steps { if case .game(let r) = s { return r.answer } }
        return nil
    }
}

// 可复现随机数 SeededGenerator 用 Models.swift 里已有的那份（SplitMix64）

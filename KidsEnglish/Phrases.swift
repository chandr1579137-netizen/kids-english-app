import Foundation

// MARK: - 「说一说」口语课：数据与课内流程（纯 Foundation，便于单测）
//
// 数据在 Resources/phrases/phrases.json，由 scripts/gen_phrases.py 从
// docs/daily-phrases/ 的定稿生成。一句一卡（版式 B），一次学一个场景。
// 课内流程照成熟 App 的做法定（依据见 docs/pm/phrases-lesson-v1.md）：
//   热身：回想上一个场景的 2 句（不放示范音，先让孩子说）
//   学：  每句一张卡，进卡自动播一次 → 孩子跟读 → 回放自己的声音 → 表扬
//   看：  整段对话连起来自动播一遍（被动输入）
//   轮到你：只出图和头像，先等孩子说，再放示范音
// 每句在一次课里出现 3 次，其中 1 次是回想。
// 每级每学完 3 课插一节复习课（PhraseReview）：只回想，不出新句。

struct PhraseCharacter: Codable, Hashable, Identifiable {
    let id: String
    let nameEn: String
    let nameZh: String
    let avatar: String
}

struct PhraseLine: Codable, Hashable, Identifiable {
    let id: String
    let speaker: String
    let en: String
    let zh: String
    let audio: String
    /// 配图三选一：新图 / 背景（phrases/img 里的文件名）
    var image: String? = nil
    /// 现成词图（word-icons 里的词）
    var icon: String? = nil
    /// 代码画的卡片（sunrise / afternoon / tomorrow / evening / night / candles / yes / no / mood）
    var code: String? = nil
    /// 代码卡上叠的一张现成小图
    var codeIcon: String? = nil
    /// 代码卡上并排的几张现成小图（心情表）
    var codeIcons: [String]? = nil
}

struct PhraseScene: Codable, Hashable, Identifiable {
    let id: String
    let titleZh: String
    let titleEn: String
    let lines: [PhraseLine]
    /// 复习课（App 里按 PhraseReview 生成，不在 JSON 里）
    var review: Bool? = nil

    var isReview: Bool { review == true }
}

struct PhraseLevel: Codable, Hashable, Identifiable {
    let level: Int
    let titleZh: String
    let scenes: [PhraseScene]
    var id: Int { level }
}

struct PhraseCatalog: Codable, Hashable {
    let version: Int
    let characters: [PhraseCharacter]
    let levels: [PhraseLevel]

    /// 读 JSON，并按 PhraseReview 的规则插入复习课
    static func decode(_ data: Data) -> PhraseCatalog? {
        guard let raw = try? JSONDecoder().decode(PhraseCatalog.self, from: data) else { return nil }
        return PhraseCatalog(version: raw.version, characters: raw.characters,
                             levels: PhraseReview.inserting(into: raw.levels))
    }

    /// 按学习顺序的全部课（含复习课）
    var allScenes: [PhraseScene] { levels.flatMap { $0.scenes } }

    /// 只有新课（不含复习课）
    var allLessons: [PhraseScene] { allScenes.filter { !$0.isReview } }

    func character(_ id: String) -> PhraseCharacter? {
        characters.first { $0.id == id }
    }

    /// 按学习顺序排在这个场景前面的那个场景（热身用）。复习课不算：复习课本身没有热身，
    /// 复习课后面的新课照样回想上一节新课的最后两句。
    func scene(before id: String) -> PhraseScene? {
        let all = allScenes
        guard let i = all.firstIndex(where: { $0.id == id }), !all[i].isReview else { return nil }
        return all[..<i].last { !$0.isReview }
    }
}

// MARK: - 代码画的卡片

/// App 里能画的代码卡（PhrasesView 的 PhraseCodeCard），单测用它检查 JSON 里没有画不出来的卡
enum PhraseCodeCardSpec {
    static let kinds: Set<String> = ["sunrise", "afternoon", "tomorrow", "evening", "night",
                                     "candles", "yes", "no", "mood"]
    /// I'm five.：五根蜡烛（D8 孩子 5 岁）
    static let candleCount = 5
}

// MARK: - 复习课

/// 每级每学完 3 课插一节复习课（斑马、Duolingo ABC 的「复习关」做法）：
/// 从这 3 课里各挑 2 句，交错排开，只做「轮到你」——先等孩子说，再放示范音。不出新句。
/// 复习课和新课排在同一条路上：做完才开下一课。
enum PhraseReview {
    static let every = 3
    static let perScene = 2
    static let idMarker = "-R"

    static func id(level: Int, number: Int) -> String { "L\(level)\(idMarker)\(number)" }

    static func isReview(_ sceneId: String) -> Bool { sceneId.contains(idMarker) }

    /// 每课挑哪两句：第一句和中间那句（第一句是这课的封面，中间那句离热身回想过的最后两句最远）
    static func picks(of scene: PhraseScene) -> [PhraseLine] {
        let lines = scene.lines
        guard lines.count > 1 else { return lines }
        return [lines[0], lines[lines.count / 2]].prefix(perScene).map { $0 }
    }

    /// 交错：第 1 课第 1 句、第 2 课第 1 句、第 3 课第 1 句、第 1 课第 2 句……同一课的句子不挨着
    static func lines(from scenes: [PhraseScene]) -> [PhraseLine] {
        let picked = scenes.map(picks)
        let rounds = picked.map(\.count).max() ?? 0
        return (0..<rounds).flatMap { r in picked.compactMap { r < $0.count ? $0[r] : nil } }
    }

    static func inserting(into levels: [PhraseLevel]) -> [PhraseLevel] {
        levels.map { level in
            let lessons = level.scenes.filter { !$0.isReview }
            var scenes: [PhraseScene] = []
            var number = 0
            for (i, scene) in lessons.enumerated() {
                scenes.append(scene)
                guard (i + 1) % every == 0 else { continue }
                number += 1
                scenes.append(PhraseScene(id: id(level: level.level, number: number),
                                          titleZh: "复习一下", titleEn: "Review",
                                          lines: lines(from: Array(lessons[(i + 1 - every)...i])),
                                          review: true))
            }
            return PhraseLevel(level: level.level, titleZh: level.titleZh, scenes: scenes)
        }
    }
}

// MARK: - 解锁

/// 一级里按顺序解锁：已完成的 + 第一个没完成的可以点；
/// 上一级全部完成才开下一级。家长打开「全部解锁」后都能点。
enum PhraseUnlock {
    static func unlocked(levels: [PhraseLevel], completed: Set<String>, unlockAll: Bool) -> Set<String> {
        let all = levels.flatMap { $0.scenes.map(\.id) }
        if unlockAll { return Set(all) }
        var open: Set<String> = []
        for level in levels {
            let ids = level.scenes.map(\.id)
            open.formUnion(ids.filter { completed.contains($0) })
            if let next = ids.first(where: { !completed.contains($0) }) {
                open.insert(next)
                break  // 这一级还没学完，后面的级先锁着
            }
        }
        return open
    }

    /// 孩子下一个该学的场景（列表里高亮它）
    static func next(levels: [PhraseLevel], completed: Set<String>) -> String? {
        levels.flatMap { $0.scenes.map(\.id) }.first { !completed.contains($0) }
    }
}

// MARK: - 课内流程

enum PhraseStep: Hashable {
    /// 热身：回想上一个场景的一句（先等孩子说，再放示范音）
    case warmup(PhraseLine)
    /// 学：一句一卡
    case learn(Int)
    /// 看：整段对话连播
    case watch
    /// 轮到你：回想这个场景的一句
    case turn(Int)
    /// 完成
    case done

    var isRecall: Bool {
        switch self {
        case .warmup, .turn: return true
        default: return false
        }
    }
}

enum PhraseLessonPlan {
    /// 热身最多回想几句（上一个场景的最后几句，离现在最近）
    static let warmupCount = 2

    static func steps(for scene: PhraseScene, previous: PhraseScene?) -> [PhraseStep] {
        // 复习课：只回想
        if scene.isReview {
            return scene.lines.indices.map { .turn($0) } + [.done]
        }
        var steps: [PhraseStep] = []
        if let previous {
            steps += previous.lines.suffix(warmupCount).map { .warmup($0) }
        }
        steps += scene.lines.indices.map { .learn($0) }
        steps.append(.watch)
        steps += scene.lines.indices.map { .turn($0) }
        steps.append(.done)
        return steps
    }

    /// 一句在这节课里出现几次（学 + 看 + 轮到你），用来自检「每句至少 3 次」
    static func exposures(of index: Int, in steps: [PhraseStep]) -> Int {
        steps.reduce(0) { n, step in
            switch step {
            case .learn(let i), .turn(let i): return n + (i == index ? 1 : 0)
            case .watch: return n + 1
            default: return n
            }
        }
    }
}

// MARK: - 收集卡

/// 完成一个场景得一张收集卡，id 加 `phrase:` 前缀，避免和旧课文的单词卡（如 apple）撞名。
/// 复习课只得星星，不发卡（卡片是一课一张）。
enum PhraseCards {
    static let prefix = "phrase:"

    static func id(for sceneId: String) -> String { prefix + sceneId }

    /// 「我的收藏」里显示的卡片名：口语卡显示场景英文名，其他卡原样
    static func title(for card: String, catalog: PhraseCatalog?) -> String {
        guard card.hasPrefix(prefix) else { return card }
        let sceneId = String(card.dropFirst(prefix.count))
        return catalog?.allScenes.first { $0.id == sceneId }?.titleEn ?? sceneId
    }
}

// MARK: - 跟读：只看出没出声，不打分

/// 没有语音识别，只判断孩子开口了没有：录音里最响的一段超过阈值就算说了。
/// 说了 → 回放自己的声音 + 表扬；没说 → 温和地再邀请一次（慢速示范）；
/// 第二次还没声音也照样往下走，不出现「错」。
enum SpeakCheck {
    /// AVAudioRecorder 的 peakPower（dBFS）。安静房间约 -50，孩子说话约 -25～-10。
    static let voicedPeakDB: Float = -32

    static func didSpeak(peakDB: Float) -> Bool { peakDB >= voicedPeakDB }

    /// 第几次邀请之后放行（从 1 开始数）
    static let maxInvites = 2

    static func shouldMoveOn(attempt: Int, spoke: Bool) -> Bool {
        spoke || attempt >= maxInvites
    }
}

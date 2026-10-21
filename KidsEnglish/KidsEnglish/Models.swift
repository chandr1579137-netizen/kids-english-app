import Foundation

// MARK: - 课文

struct WordTiming: Codable, Hashable {
    let word: String
    let start: Double   // 毫秒
    let end: Double     // 毫秒
}

struct Paragraph: Codable, Hashable {
    let paragraphId: String
    let text: String
    let translation: String
    let audioStart: Double
    let audioEnd: Double
    let words: [WordTiming]
}

struct QuizOption: Codable, Hashable {
    let text: String?
    let value: String?
    let image: String?
}

struct QuizItem: Codable, Identifiable, Hashable {
    let qid: String
    let type: String          // fill_blank | image_choice | sentence_order | word_builder
    let question: String
    let blank: String?
    let options: [QuizOption]?
    let correctAnswer: String?
    let shuffledWords: [String]?
    let correctOrder: [String]?

    var id: String { qid }

    enum CodingKeys: String, CodingKey {
        case qid = "id", type, question, blank, options, correctAnswer, shuffledWords, correctOrder
    }
}

struct LessonRewards: Codable, Hashable {
    let magicPower: Int?
    let cards: [String]?
}

struct LessonMeta: Codable, Hashable {
    let wordCount: Int?
    let estimatedTime: Int?
    let difficulty: Double?
}

struct Lesson: Codable, Identifiable, Hashable {
    let id: String
    let level: Int
    let title: String
    let titleCn: String
    let coverImage: String?
    let content: [Paragraph]
    let quiz: [QuizItem]
    let rewards: LessonRewards?
    let metadata: LessonMeta?
}

// MARK: - 单词

struct WordEntry: Codable, Identifiable, Hashable {
    let word: String
    let phonetic: String?
    let meaningCn: String?
    let meaningEn: String?
    let partOfSpeech: String?
    let examples: [String]?
    let emoji: String?
    let level: Int?

    var id: String { word.lowercased() }
}

// MARK: - 儿歌

struct SongLine: Codable, Hashable {
    let en: String
    let cn: String
}

struct Song: Codable, Identifiable, Hashable {
    let id: String
    let level: Int
    let title: String
    let titleCn: String
    let theme: String?
    let lines: [SongLine]
}

// MARK: - 关卡

struct LevelInfo {
    let level: Int
    let name: String
    let icon: String
    let color: String

    static let all: [LevelInfo] = [
        LevelInfo(level: 1, name: "萌芽之森", icon: "🌱", color: "green"),
        LevelInfo(level: 2, name: "回声山谷", icon: "🏔️", color: "blue"),
        LevelInfo(level: 3, name: "闪耀之海", icon: "🌊", color: "cyan"),
        LevelInfo(level: 4, name: "云端之城", icon: "☁️", color: "purple"),
        LevelInfo(level: 5, name: "永恒星空", icon: "⭐", color: "indigo"),
        LevelInfo(level: 6, name: "时光回廊", icon: "⚙️", color: "orange"),
        LevelInfo(level: 7, name: "创世之核", icon: "💎", color: "pink"),
    ]
}

// MARK: - 主题词包

struct WordTheme: Codable, Identifiable, Hashable {
    let id: String
    let nameCn: String
    let words: [String]
}

// MARK: - 听音找一找（场景）

/// 场景里空位的种类：地面 / 台面（物品底边贴台面线）/ 墙面（只放能挂墙的东西）
enum SceneSpotKind: String, Codable, Hashable {
    case ground, counter, wall
}

/// 一个空位：原图（sourceSize，2048×2048）像素坐标里的中心点，来自产品经理验收的 spots json
struct SceneSpot: Codable, Hashable {
    let id: Int
    let kind: SceneSpotKind
    let x: Double
    let y: Double
}

/// 放在某个空位上的物品（用现成词图抠的透明 PNG：Resources/scenes/items/<word>.png）
struct SceneItem: Codable, Hashable {
    let word: String
    let spot: Int
}

/// 一个场景。背景图已经裁成 `panel` 那一块（带圆角边框的面板），界面按面板宽高比等比显示，不拉伸。
struct FindScene: Codable, Identifiable, Hashable {
    let id: String
    let background: String
    let sourceSize: [Double]
    /// 面板在原图里的像素框 [x0, y0, x1, y1]
    let panel: [Double]
    /// 物品边长，占面板宽度的比例
    let itemSize: Double
    /// 台面线（原图像素 y）：counter 空位的物品底边贴在这条线上
    let counterTopY: Double?
    let spots: [SceneSpot]
    let items: [SceneItem]

    var panelWidth: Double { panel[2] - panel[0] }
    var panelHeight: Double { panel[3] - panel[1] }
    /// 面板宽 / 高
    var aspectRatio: Double { panelWidth / panelHeight }
}

/// 物品在面板里的位置，全部是比例：centerX / width 相对面板宽，centerY / height 相对面板高。
/// width 与 height 换算成点数后相等（正方形物品框）。
struct ScenePlacement: Equatable {
    let word: String
    let kind: SceneSpotKind
    let centerX: Double
    let centerY: Double
    let width: Double
    let height: Double

    var bottomY: Double { centerY + height / 2 }
}

/// 摆放规则（纯函数，单测覆盖）：
/// - 地面 / 墙面：物品框中心对准空位中心；
/// - 台面：物品「站」在台面线上 —— 画面底边（去掉 PNG 底部留白）正好落在 counterTopY；
/// - 墙面空位只能放能挂墙的东西（钟、画、镜子、地图）。
enum SceneLayout {
    /// make_scene_items.py 输出的 PNG 里，物品画面底边到图片底边的留白（占边长）
    static let itemImageBottomPadding = 0.04

    /// 能挂在墙上的词
    static let wallHangable: Set<String> = ["clock", "picture", "mirror", "map"]

    static func canPlace(_ word: String, on kind: SceneSpotKind) -> Bool {
        switch kind {
        case .wall: return wallHangable.contains(word.lowercased())
        case .ground, .counter: return true
        }
    }

    static func placements(for scene: FindScene) -> [ScenePlacement] {
        let w = scene.panelWidth, h = scene.panelHeight
        guard w > 0, h > 0 else { return [] }
        let x0 = scene.panel[0], y0 = scene.panel[1]
        let width = scene.itemSize
        let height = scene.itemSize * scene.aspectRatio
        return scene.items.compactMap { item in
            guard let spot = scene.spots.first(where: { $0.id == item.spot }) else { return nil }
            let cx = (spot.x - x0) / w
            var cy = (spot.y - y0) / h
            if spot.kind == .counter, let top = scene.counterTopY {
                let frameBottom = (top - y0) / h + itemImageBottomPadding * height
                cy = frameBottom - height / 2
            }
            return ScenePlacement(word: item.word, kind: spot.kind,
                                  centerX: cx, centerY: cy, width: width, height: height)
        }
    }

    /// 数据问题清单（空 = 没问题）：空位不存在、空位重复、词重复、墙上放了挂不上去的东西、台面缺台面线
    static func problems(in scene: FindScene) -> [String] {
        var out: [String] = []
        if scene.panel.count != 4 { out.append("\(scene.id): panel 应为 4 个数") }
        var usedSpots = Set<Int>(), usedWords = Set<String>()
        for item in scene.items {
            guard let spot = scene.spots.first(where: { $0.id == item.spot }) else {
                out.append("\(scene.id)/\(item.word): 空位 \(item.spot) 不存在"); continue
            }
            if !usedSpots.insert(item.spot).inserted { out.append("\(scene.id): 空位 \(item.spot) 放了两个物品") }
            if !usedWords.insert(item.word.lowercased()).inserted { out.append("\(scene.id): \(item.word) 重复") }
            if !canPlace(item.word, on: spot.kind) {
                out.append("\(scene.id)/\(item.word): 不能放在 \(spot.kind.rawValue) 空位")
            }
            if spot.kind == .counter && scene.counterTopY == nil {
                out.append("\(scene.id): 有台面空位但没有 counterTopY")
            }
        }
        return out
    }
}

enum SceneCatalog {
    static func decode(_ data: Data) -> [FindScene] {
        (try? JSONDecoder().decode([FindScene].self, from: data)) ?? []
    }
}

// MARK: - 喂小动物

/// feed-pairs.json 里的一组：动物、它爱吃的食物，以及两句英文台词（音频按台词生成）
struct FeedPair: Codable, Hashable {
    let animal: String
    let food: String
    let want: String     // "I want a banana!"
    let yummy: String    // "Yummy banana!"
}

struct FeedCatalog: Codable, Hashable {
    let noThanks: String // "No, thank you!"
    let pairs: [FeedPair]

    static func decode(_ data: Data) -> FeedCatalog? {
        try? JSONDecoder().decode(FeedCatalog.self, from: data)
    }
}

/// 一轮：一只动物 + 托盘里的 3 个食物（只有 1 个是对的）
struct FeedRound: Hashable {
    let pair: FeedPair
    let options: [String]
    var correctIndex: Int? { options.firstIndex(of: pair.food) }
}

/// 松手结果：喂对了 / 喂错了（动物摇头、食物弹回）/ 没拖到动物身上（只弹回）
enum FeedOutcome: Equatable {
    case eaten, refused, missed
}

/// 可复现的随机数（截图和单元测试用固定种子）
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {   // SplitMix64
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum FeedGame {
    static let roundsPerGame = 5
    static let optionCount = 3
    /// 判定区：动物图框四边各外扩 15%（宽高共放大 30%），4 岁孩子不用拖得很准
    static let dropExpansion = 0.3

    /// 出题：动物不重复；干扰项来自其他组的食物，且不会和正确答案相同（蜜蜂、熊都吃 honey 时也不会出两个 honey）
    static func makeRounds<G: RandomNumberGenerator>(_ pairs: [FeedPair],
                                                     count: Int = roundsPerGame,
                                                     optionCount: Int = optionCount,
                                                     shuffleAnimals: Bool = true,
                                                     using rng: inout G) -> [FeedRound] {
        var seenAnimals = Set<String>()
        let unique = pairs.filter { seenAnimals.insert($0.animal.lowercased()).inserted }
        let chosen = (shuffleAnimals ? unique.shuffled(using: &rng) : unique).prefix(count)
        var foods: [String] = []
        for p in pairs where !foods.contains(p.food) { foods.append(p.food) }
        return chosen.map { pair in
            let distractors = foods.filter { $0 != pair.food }.shuffled(using: &rng).prefix(max(0, optionCount - 1))
            let options = ([pair.food] + distractors).shuffled(using: &rng)
            return FeedRound(pair: pair, options: options)
        }
    }

    static func makeRounds(_ pairs: [FeedPair]) -> [FeedRound] {
        var rng = SystemRandomNumberGenerator()
        return makeRounds(pairs, using: &rng)
    }

    /// 动物图框放大 30% 后的判定区
    /// （SwiftPM 单测只链接 Foundation，没有 CoreGraphics 的 insetBy/contains，这里手算）
    static func dropZone(around frame: CGRect, expansion: Double = dropExpansion) -> CGRect {
        let dx = frame.size.width * CGFloat(expansion) / 2
        let dy = frame.size.height * CGFloat(expansion) / 2
        return CGRect(x: frame.origin.x - dx, y: frame.origin.y - dy,
                      width: frame.size.width + 2 * dx, height: frame.size.height + 2 * dy)
    }

    static func contains(_ r: CGRect, _ p: CGPoint) -> Bool {
        p.x >= r.origin.x && p.x <= r.origin.x + r.size.width
            && p.y >= r.origin.y && p.y <= r.origin.y + r.size.height
    }

    static func outcome(dropping food: String, at point: CGPoint,
                        round: FeedRound, animalFrame: CGRect) -> FeedOutcome {
        guard contains(dropZone(around: animalFrame), point) else { return .missed }
        return food == round.pair.food ? .eaten : .refused
    }

    /// custom-audio-map.json 里的键
    static func wantKey(_ food: String) -> String { "feed#want-\(food)" }
    static func yummyKey(_ food: String) -> String { "feed#yummy-\(food)" }
    static let noThanksKey = "feed#no-thanks"

    /// 数据问题清单（空 = 没问题）
    static func problems(in catalog: FeedCatalog) -> [String] {
        var out: [String] = []
        var animals = Set<String>()
        for p in catalog.pairs {
            if !animals.insert(p.animal.lowercased()).inserted { out.append("\(p.animal) 重复") }
            if p.animal == p.food { out.append("\(p.animal) 吃自己") }
            let food = p.food.lowercased()
            if !p.want.lowercased().contains(food) { out.append("\(p.animal): want 台词里没有 \(p.food)") }
            if !p.yummy.lowercased().contains(food) { out.append("\(p.animal): yummy 台词里没有 \(p.food)") }
            if !p.want.hasPrefix("I want ") || !p.want.hasSuffix("!") { out.append("\(p.animal): want 台词格式不对") }
            if !p.yummy.hasPrefix("Yummy ") || !p.yummy.hasSuffix("!") { out.append("\(p.animal): yummy 台词格式不对") }
        }
        let foods = Set(catalog.pairs.map(\.food))
        if catalog.pairs.count < roundsPerGame { out.append("动物少于 \(roundsPerGame) 个") }
        if foods.count < optionCount { out.append("不同的食物少于 \(optionCount) 种") }
        return out
    }
}

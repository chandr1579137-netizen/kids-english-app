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

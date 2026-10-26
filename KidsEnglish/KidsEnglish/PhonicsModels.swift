import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

// MARK: - 自然拼读阶段 2：Jolly Phonics 字母音（Group 1: s, a, t, i, p, n）

/// 自然拼读字母音数据结构（纯 Foundation，便于单测与跨平台复用）
public struct PhonicsLetter: Identifiable, Hashable, Codable {
    public let id: String
    public let letter: String
    public let phoneme: String
    public let word: String
    public let wordZh: String
    public let actionZh: String
    public let chantEn: String
    public let audio: String
    public let themeColorName: String

    public init(id: String, letter: String, phoneme: String, word: String, wordZh: String, actionZh: String, chantEn: String, audio: String, themeColorName: String) {
        self.id = id
        self.letter = letter
        self.phoneme = phoneme
        self.word = word
        self.wordZh = wordZh
        self.actionZh = actionZh
        self.chantEn = chantEn
        self.audio = audio
        self.themeColorName = themeColorName
    }
}

#if canImport(SwiftUI)
extension PhonicsLetter {
    public var cardTint: Color {
        switch themeColorName {
        case "emerald": return Color(red: 0.16, green: 0.65, blue: 0.45)
        case "coral":   return Color(red: 0.95, green: 0.42, blue: 0.35)
        case "gold":    return Color(red: 1.0, green: 0.76, blue: 0.08)
        case "purple":  return Color(red: 0.58, green: 0.35, blue: 0.88)
        case "pink":    return Color(red: 0.92, green: 0.40, blue: 0.65)
        case "sky":     return Color(red: 0.25, green: 0.62, blue: 0.92)
        default:        return Color.orange
        }
    }
}
#endif

/// 自然拼读 Group 1 字母音目录
public enum PhonicsCatalog {
    public static let group1: [PhonicsLetter] = [
        PhonicsLetter(
            id: "s",
            letter: "s",
            phoneme: "/s/",
            word: "snake",
            wordZh: "小蛇",
            actionZh: "双手合十，像小蛇一样游动",
            chantEn: "Snake, snake, slithering snake!",
            audio: "phonics_chant_s",
            themeColorName: "emerald"
        ),
        PhonicsLetter(
            id: "a",
            letter: "a",
            phoneme: "/æ/",
            word: "apple",
            wordZh: "苹果",
            actionZh: "手指在手臂上轻快爬爬（学小蚂蚁）",
            chantEn: "Apple, apple, crunchy red apple!",
            audio: "phonics_chant_a",
            themeColorName: "coral"
        ),
        PhonicsLetter(
            id: "t",
            letter: "t",
            phoneme: "/t/",
            word: "tiger",
            wordZh: "老虎",
            actionZh: "脑袋左右轻快转动，看网球飞来飞去",
            chantEn: "Tiger, tiger, tiptoe tiger!",
            audio: "phonics_chant_t",
            themeColorName: "gold"
        ),
        PhonicsLetter(
            id: "i",
            letter: "i",
            phoneme: "/ɪ/",
            word: "box",
            wordZh: "跳进盒子里",
            actionZh: "双手做小兔子跳进盒子的动作",
            chantEn: "In, in, jumping in the box!",
            audio: "phonics_chant_i",
            themeColorName: "purple"
        ),
        PhonicsLetter(
            id: "p",
            letter: "p",
            phoneme: "/p/",
            word: "pig",
            wordZh: "小猪",
            actionZh: "竖起食指当蜡烛，嘟嘴轻轻吹灭",
            chantEn: "Pig, pig, playful pig!",
            audio: "phonics_chant_p",
            themeColorName: "pink"
        ),
        PhonicsLetter(
            id: "n",
            letter: "n",
            phoneme: "/n/",
            word: "nose",
            wordZh: "小鼻子",
            actionZh: "双臂张开模仿滑翔小飞机，摸摸小鼻子",
            chantEn: "Nose, nose, touch your nose!",
            audio: "phonics_chant_n",
            themeColorName: "sky"
        )
    ]

    public static func letter(for id: String) -> PhonicsLetter? {
        group1.first { $0.id.lowercased() == id.lowercased() }
    }
}

/// 听音辨字母（3 选 1）题目
public struct PhonicsQuizRound: Equatable, Hashable {
    public let target: PhonicsLetter
    public let options: [PhonicsLetter]

    public init(target: PhonicsLetter, options: [PhonicsLetter]) {
        self.target = target
        self.options = options
    }
}

public enum PhonicsEngine {
    public static let defaultQuizRounds = 4

    /// 听音辨字母出题：每道题 1 个目标音 + 2 个干扰项（同组不重复）
    public static func makeQuizRounds(count: Int = defaultQuizRounds,
                                      pool: [PhonicsLetter] = PhonicsCatalog.group1,
                                      using rng: inout some RandomNumberGenerator) -> [PhonicsQuizRound] {
        guard pool.count >= 3 else { return [] }
        var targets = pool.shuffled(using: &rng)
        while targets.count < count {
            targets.append(contentsOf: pool.shuffled(using: &rng))
        }
        targets = Array(targets.prefix(count))

        return targets.map { target in
            let others = pool.filter { $0.id != target.id }.shuffled(using: &rng)
            let distractors = Array(others.prefix(2))
            let options = ([target] + distractors).shuffled(using: &rng)
            return PhonicsQuizRound(target: target, options: options)
        }
    }
}

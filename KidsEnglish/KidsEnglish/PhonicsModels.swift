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

// MARK: - 自然拼读阶段 3：CVC 拼读词（Group 1 滑音小火车）

/// CVC 拼读词数据结构（纯 Foundation）
public struct PhonicsBlendWord: Identifiable, Hashable, Codable {
    public let id: String
    public let word: String
    public let letters: [String]
    public let phonemes: [String]
    public let meaningZh: String
    public let chantEn: String
    public let audio: String
    public let picture: String
    public let themeColorName: String

    public init(id: String, word: String, letters: [String], phonemes: [String], meaningZh: String, chantEn: String, audio: String, picture: String, themeColorName: String) {
        self.id = id
        self.word = word
        self.letters = letters
        self.phonemes = phonemes
        self.meaningZh = meaningZh
        self.chantEn = chantEn
        self.audio = audio
        self.picture = picture
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

extension PhonicsBlendWord {
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

/// 自然拼读核心目录
public enum PhonicsCatalog {
    // MARK: 阶段 2：Group 1 字母音
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

    // MARK: 阶段 3：Group 1 CVC 拼读词
    public static let cvcGroup1: [PhonicsBlendWord] = [
        PhonicsBlendWord(
            id: "sit",
            word: "sit",
            letters: ["s", "i", "t"],
            phonemes: ["/s/", "/ɪ/", "/t/"],
            meaningZh: "坐下",
            chantEn: "Sit, sit, sit down please!",
            audio: "blend_word_sit",
            picture: "sit.jpg",
            themeColorName: "purple"
        ),
        PhonicsBlendWord(
            id: "pan",
            word: "pan",
            letters: ["p", "a", "n"],
            phonemes: ["/p/", "/æ/", "/n/"],
            meaningZh: "平底锅",
            chantEn: "Pan, pan, hot cooking pan!",
            audio: "blend_word_pan",
            picture: "pan.jpg",
            themeColorName: "coral"
        ),
        PhonicsBlendWord(
            id: "pin",
            word: "pin",
            letters: ["p", "i", "n"],
            phonemes: ["/p/", "/ɪ/", "/n/"],
            meaningZh: "小别针",
            chantEn: "Pin, pin, little shiny pin!",
            audio: "blend_word_pin",
            picture: "pin.jpg",
            themeColorName: "sky"
        )
    ]

    public static func blendWord(for id: String) -> PhonicsBlendWord? {
        cvcGroup1.first { $0.id.lowercased() == id.lowercased() }
    }
}

// MARK: - 测验题目模型

/// 听音辨字母（3 选 1）题目
public struct PhonicsQuizRound: Equatable, Hashable {
    public let target: PhonicsLetter
    public let options: [PhonicsLetter]

    public init(target: PhonicsLetter, options: [PhonicsLetter]) {
        self.target = target
        self.options = options
    }
}

/// 小火车装车厢拼词测验（3 选 1 缺失字母）题目
public struct PhonicsCargoRound: Equatable, Hashable {
    public let targetWord: PhonicsBlendWord
    public let missingIndex: Int
    public let correctLetter: String
    public let options: [String]

    public init(targetWord: PhonicsBlendWord, missingIndex: Int, correctLetter: String, options: [String]) {
        self.targetWord = targetWord
        self.missingIndex = missingIndex
        self.correctLetter = correctLetter
        self.options = options
    }
}

// MARK: - 自然拼读出题引擎

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

    /// 生成小火车拼词题目：随机缺失 1 个字母，提供目标字母 + 2 个干扰字母（3 选 1）
    public static func makeCargoRounds(count: Int = defaultQuizRounds,
                                       pool: [PhonicsBlendWord] = PhonicsCatalog.cvcGroup1,
                                       letterPool: [String] = ["s", "a", "t", "i", "p", "n"],
                                       using rng: inout some RandomNumberGenerator) -> [PhonicsCargoRound] {
        guard !pool.isEmpty, letterPool.count >= 3 else { return [] }
        var words = pool.shuffled(using: &rng)
        while words.count < count {
            words.append(contentsOf: pool.shuffled(using: &rng))
        }
        words = Array(words.prefix(count))

        return words.map { word in
            let missingIdx = Int.random(in: 0..<word.letters.count, using: &rng)
            let correct = word.letters[missingIdx]
            let distractors = letterPool.filter { $0 != correct }.shuffled(using: &rng).prefix(2)
            let options = ([correct] + distractors).shuffled(using: &rng)
            return PhonicsCargoRound(targetWord: word, missingIndex: missingIdx, correctLetter: correct, options: options)
        }
    }
}

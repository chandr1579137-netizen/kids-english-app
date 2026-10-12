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

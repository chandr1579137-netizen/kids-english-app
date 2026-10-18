import Foundation

// MARK: - 备份快照

/// 学习进度快照。换机或重装时靠一段 JSON 带走，不需要登录或云同步。
///
/// 字段与历史导出格式一一对应：`ProgressCodec.encode` 用 `.sortedKeys` 输出，
/// 所以这里字段的声明顺序不影响 JSON 键序；但字段名不能改，旧备份要能继续导入。
struct ProgressSnapshot: Codable, Equatable {
    var version: Int
    var exportedAt: String
    var completedLessons: [String]
    var learnedWords: [String]
    var favoriteWords: [String]
    var collectedCards: [String]
    var quizBest: [String: Double]
    var selectedThemeId: String?
    var dailyNewWords: Int
    var timeLimitMinutes: Int
    var showTranslationDefault: Bool
    var gameAnswered: Int
    var gameCorrect: Int
    var studyDates: [String]
}

/// 备份 JSON 的编解码与恢复文案。纯 Foundation，便于单测。
enum ProgressCodec {
    /// 导出格式：prettyPrinted + sortedKeys，与旧实现完全一致。
    /// 编码失败理论上不会发生；返回 "{}" 也只是沿用旧实现的兜底，不让界面拿到 nil。
    static func encode(_ snapshot: ProgressSnapshot) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snapshot),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    /// 解析备份文本。不是 UTF-8 JSON、字段缺失或类型不符都返回 nil，
    /// 调用方据此保持原进度不变，只给用户一句「不是有效的备份」。
    static func decode(_ text: String) -> ProgressSnapshot? {
        guard let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ProgressSnapshot.self, from: data)
    }

    /// 恢复成功后展示给用户的文案，格式与旧实现一致。
    static func summary(_ snapshot: ProgressSnapshot) -> String {
        return "已恢复：\(snapshot.completedLessons.count) 篇课文、\(snapshot.learnedWords.count) 个单词"
    }
}

// MARK: - 跨天

/// 每日时长按「本地日期字符串」分桶，UserDefaults key 形如 study_2026-10-18。
enum DayKey {
    /// 生成 yyyy-MM-dd 日期键。
    /// 用 en_US_POSIX 锁定公历与数字格式，避免用户切到非公历或本地化数字后 key 变形；
    /// 每次新建 DateFormatter（与旧实现一致），这样手动改系统时区后也能立刻跟上。
    static func key(for date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// 已存下的日期键是否已经不是「现在」所在的那一天（跨过午夜或改了时区）。
    /// 旧实现用 `today != todayKey` 判断；这里只是把「现在该是哪一天」抽出来。
    static func isNewDay(stored: String, now: Date, timeZone: TimeZone = .current) -> Bool {
        return key(for: now, timeZone: timeZone) != stored
    }
}

// MARK: - 低龄白名单

/// 低龄可学词表：words-*.json 是全龄语料（夹杂 is / genesis / 1000 这类词），
/// 只保留 word-themes.json 里策展过、且词典里真实存在的词；
/// 主题为空说明资源没打包好，回退全量 —— 宁可多学也不要空屏。
enum ThemeWhitelist {
    /// 返回允许学习的词集合（统一小写）。
    /// - 主题词取并集、去重、大小写不敏感；
    /// - 与词典取交集：主题里写了但词典没有的词不会出现在结果里；
    /// - `themes` 为空时返回词典里全部词（回退全量）。
    static func allowedWords(dictionary: [String], themes: [String]) -> Set<String> {
        let allWords = Set(dictionary.map { $0.lowercased() })
        let curated = Set(themes.map { $0.lowercased() })
        guard !curated.isEmpty else { return allWords }
        return curated.intersection(allWords)
    }
}

// MARK: - 重置

/// 重置进度时要清理的 UserDefaults key：
/// 按天存的 study_ / bonus_ 前缀都清掉，其余设置类 key（限时、翻译开关等）保留。
enum ResetPlan {
    private static let dailyPrefixes = ["study_", "bonus_"]

    static func keysToPurge(from keys: [String]) -> [String] {
        return keys.filter { key in
            dailyPrefixes.contains { key.hasPrefix($0) }
        }
    }
}

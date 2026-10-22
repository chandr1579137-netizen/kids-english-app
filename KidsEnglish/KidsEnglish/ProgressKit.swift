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
    /// 孩子自己设置的名字与头像；旧备份没有这两个字段，解码后为 nil
    var childName: String? = nil
    var avatarEmoji: String? = nil
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


// MARK: - 游戏题池难度

enum GamePool {
    /// 简单档只取 level 1–2 的词；命中太少时回退全量，
    /// 避免题池只剩个位数导致同一道题反复出现。
    static func filtered(_ words: [WordEntry], simple: Bool, minimum: Int = 20) -> [WordEntry] {
        guard simple else { return words }
        let easy = words.filter { ($0.level ?? 1) <= 2 }
        return easy.count >= minimum ? easy : words
    }
}

// MARK: - 每日时长

enum StudyTime {
    /// 今日可用时长 = 设置的上限 + 家长解锁追加的部分
    static func allowance(limitMinutes: Int, bonusSeconds: Double) -> Double {
        Double(limitMinutes * 60) + bonusSeconds
    }

    /// 是否已到今天的上限（limitMinutes 为 0 表示不限）
    static func isTimeUp(studiedSeconds: Double, limitMinutes: Int, bonusSeconds: Double) -> Bool {
        guard limitMinutes > 0 else { return false }
        return studiedSeconds >= allowance(limitMinutes: limitMinutes, bonusSeconds: bonusSeconds)
    }
}

// MARK: - 连续学习天数

enum Streak {
    /// 从今天（今天还没学就从昨天）往前数连续有记录的天数。
    /// 昨天也缺就直接 0 —— 一天没学就断，和界面上的「连续 N 天」一致。
    static func count(studyDates: [String],
                      today: Date,
                      timeZone: TimeZone = .current,
                      calendar: Calendar = .current) -> Int {
        let dates = Set(studyDates)
        var cursor = today
        if !dates.contains(DayKey.key(for: cursor, timeZone: timeZone)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
            guard dates.contains(DayKey.key(for: cursor, timeZone: timeZone)) else { return 0 }
        }
        var count = 0
        while dates.contains(DayKey.key(for: cursor, timeZone: timeZone)) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }
}

// MARK: - 首页单词本

enum HomeBooks {
    /// 首页单词本的词过滤（可配置）。key = 主题 id，value = 首页这本书只保留的词（小写，按主题原顺序出词）。
    /// 只影响「背单词」首页：单词本卡片词数、全部单词总数、计划卡「已学 x / 总数」、开始学习出的词。
    /// 「单词卡」页和词库数据（word-themes.json）不受影响。
    /// 目前为空：数字本在首页也是完整的 1–100（用户决定，取消了之前「首页只放 1–10」的限制）。
    /// 以后要再对某本书做首页精选，往这里加一项即可，总数会自动从数据重新算。
    static let homeBookWordFilter: [String: Set<String>] = [:]

    /// 某本书在首页上的词（保持主题内原顺序；没有配置过滤的主题原样返回）。
    static func homeWords(themeId: String, words: [String]) -> [String] {
        guard let allowed = homeBookWordFilter[themeId] else { return words }
        return words.filter { allowed.contains($0.lowercased()) }
    }

    /// 首页「全部单词」可学词集合 = ThemeWhitelist.allowedWords(dictionary:, themes: 各主题经 homeWords 过滤后的词并集)
    static func allowedWords(dictionary: [String], themes: [WordTheme]) -> Set<String> {
        let curated = themes.flatMap { homeWords(themeId: $0.id, words: $0.words) }
        return ThemeWhitelist.allowedWords(dictionary: dictionary, themes: curated)
    }

    /// 单词本排序：全部单词之后按这个顺序；不在表里的主题按原顺序排最后。
    /// clothing 放在 home 后面（以前漏了）。
    static let themeOrder = [
        "fruits", "animals", "colors", "numbers", "body", "family", "foods", "vehicles",
        "home", "clothing", "nature", "toys", "stationery", "places", "actions", "adjectives"
    ]

    static func sorted(_ ids: [String]) -> [String] {
        let rank = Dictionary(uniqueKeysWithValues: themeOrder.enumerated().map { ($1, $0) })
        let known = ids.filter { rank[$0] != nil }.sorted { rank[$0]! < rank[$1]! }
        let unknown = ids.filter { rank[$0] == nil }
        return known + unknown
    }
}

// MARK: - 卡片专用释义

/// 一词多义时，卡片和看图/释义游戏只显示与词图一致的那个义项（词图表意重做，2026-10-22）。
/// 词典里的 meaningCn 不改：课文里点词查词仍显示完整多义释义（DataStore.lookupWord 用原词条）。
enum CardMeaning {
    /// key 小写；来源 meaning-audit/redo-list.json 中 action=meaning_fix 的条目，
    /// 以及重画时要求同步改释义的 light / sharp / engine。
    static let overrides: [String: String] = [
        "train": "火车",
        "letter": "信",
        "ask": "问",
        "choose": "选择",
        "pick": "摘",
        "kind": "善良的",
        "old": "旧的",
        "short": "短的",
        "bright": "明亮的",
        "hard": "硬的",
        "young": "幼小的",
        "sweet": "甜的",
        "sharp": "尖的",
        "light": "轻的",
        // A14 双格图是粗糙的树皮；词典释义是「汹涌的」（rough sea），和图对不上
        "rough": "粗糙的",
        "turn": "转圈",
        "point": "指",
        // 交通篇：engine 改画蒸汽火车头（半写实 3D，和交通篇同风格）
        "engine": "火车头",
    ]

    static func meaning(for entry: WordEntry) -> String? {
        overrides[entry.word.lowercased()] ?? entry.meaningCn
    }

    /// 返回卡片用的词条：有覆盖就换掉 meaningCn，其余字段原样保留。
    static func applying(to entry: WordEntry) -> WordEntry {
        guard let cn = overrides[entry.word.lowercased()] else { return entry }
        return WordEntry(word: entry.word, phonetic: entry.phonetic, meaningCn: cn,
                         meaningEn: entry.meaningEn, partOfSpeech: entry.partOfSpeech,
                         examples: entry.examples, emoji: entry.emoji, level: entry.level)
    }
}

// MARK: - 易混词组

/// 看图/听音选词游戏里，同一组的词不同时出现在一道题的选项里（包括正确答案和干扰项）。
/// 例如 cat 和 kitten、sea 和 ocean 图很像或意思几乎一样，同时出现孩子没法判断。
/// 来源 meaning-audit/redo-list.json 的 confusable_groups（33 组）。
enum Confusables {
    static let groups: [[String]] = [
        ["small", "little"], ["sea", "ocean", "wave"], ["pretty", "beautiful"], ["sleepy", "tired"],
        ["look", "see", "watch"], ["hear", "listen"], ["love", "hug"], ["chicken", "hen"],
        ["cat", "kitten"], ["dog", "puppy"], ["rabbit", "hare"], ["turtle", "tortoise"],
        ["pear", "pomelo"], ["train", "subway", "engine"], ["ship", "boat", "sailboat"],
        ["van", "truck", "ambulance"], ["plane", "spaceship", "rocket"], ["yellow", "gold", "orange"],
        ["head", "face"], ["mouth", "teeth", "tongue"], ["mother", "aunt"], ["father", "uncle"],
        ["girl", "sister"], ["boy", "brother", "child"], ["draw", "paint"], ["clean", "wipe", "sweep"],
        ["jump", "hop"], ["shop", "market", "supermarket"], ["bring", "carry", "take"],
        ["cake", "delicious"], ["honey", "sticky"], ["juice", "full"], ["lemon", "sour"],
    ]

    /// 词 → 所在组号（一个词可能在多组里）
    private static let index: [String: Set<Int>] = {
        var map: [String: Set<Int>] = [:]
        for (i, group) in groups.enumerated() {
            for w in group { map[w.lowercased(), default: []].insert(i) }
        }
        return map
    }()

    /// 两个词是否在同一个易混组里（同一个词不算冲突）
    static func conflict(_ a: String, _ b: String) -> Bool {
        let x = a.lowercased(), y = b.lowercased()
        guard x != y, let ga = index[x], let gb = index[y] else { return false }
        return !ga.isDisjoint(with: gb)
    }

    /// 从（已打乱的）候选里按顺序挑干扰项：跳过答案本身、和答案或已选项同组的词；
    /// `distinctMeaning` 为 true 时（释义选择题）再跳过中文释义与已选项相同的词。
    static func pickDistractors(from pool: [WordEntry], for target: WordEntry,
                                count: Int = 3, distinctMeaning: Bool = false) -> [WordEntry] {
        var chosen: [WordEntry] = []
        var meanings: Set<String> = [target.meaningCn ?? ""]
        for candidate in pool {
            if chosen.count >= count { break }
            if candidate.word.lowercased() == target.word.lowercased() { continue }
            if conflict(candidate.word, target.word) { continue }
            if chosen.contains(where: { $0.word.lowercased() == candidate.word.lowercased()
                || conflict($0.word, candidate.word) }) { continue }
            if distinctMeaning {
                let m = candidate.meaningCn ?? ""
                if meanings.contains(m) { continue }
                meanings.insert(m)
            }
            chosen.append(candidate)
        }
        return chosen
    }

    /// 从（已打乱的）候选里挑最多 `count` 个两两不同组的词（连连看等一屏多词的玩法）。
    static func pickDistinct(_ pool: [WordEntry], count: Int) -> [WordEntry] {
        var chosen: [WordEntry] = []
        for candidate in pool {
            if chosen.count >= count { break }
            if chosen.contains(where: { $0.word.lowercased() == candidate.word.lowercased()
                || conflict($0.word, candidate.word) }) { continue }
            chosen.append(candidate)
        }
        return chosen
    }
}

// MARK: - 双格对比高亮词图

/// 词图表意重做 A 类（34 张）：左右两格对比，目标格保留原色、另一格降饱和变浅
/// （meaning-audit/tools_highlight.py 的 hl-left / hl-right 后处理，muse-batch.json 中 type=A）。
/// 学习页大卡对这类图不做径向边缘渐隐：变淡的那一格是用来对比的，必须完整看得见。
/// 词图文件名里没有标记（都是 <word>.jpg），所以这里登记词表；单张图不受影响。
enum PairIcons {
    static let words: Set<String> = [
        "big", "small", "little", "tall", "short", "long", "fast", "slow",
        "hot", "cold", "old", "new", "young", "full", "empty", "wet", "dry",
        "soft", "hard", "heavy", "light", "high", "low", "deep", "shallow",
        "smooth", "rough", "dark", "bright", "good", "bad", "dirty", "sharp", "far",
    ]

    /// 这个词的词图是不是双格对比高亮图
    static func isHighlightedPair(_ word: String) -> Bool {
        words.contains(word.lowercased())
    }
}

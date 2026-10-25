import Foundation

// MARK: - 多孩子档案（纯 Foundation，便于单测）
//
// 多个孩子共用一台手机，进度分开记（decisions.md D9；方案见 docs/pm/profiles-v1.md）。
// 存储：按孩子分开的 key 一律改成 `p.<孩子 id>.<原 key>`；profiles / currentProfileId / hasSeenGuide /
// lastBackgroundAt 共用、不加前缀。DataStore 只在读写 UserDefaults 时套一层 ProfileKeys.scoped，
// 其余逻辑不变。

struct ChildProfile: Codable, Hashable, Identifiable {
    var id: String
    var name: String
    /// 头像：ProfileRoster.avatars 里的一个词（用现成的平涂词图）
    var avatar: String
    /// 代表色：0..<ProfileRoster.colorCount
    var color: Int
}

enum ProfileRoster {
    static let maxCount = 4
    static let avatars = ["cat", "dog", "rabbit", "panda", "lion", "penguin", "monkey", "fox"]
    static let colorCount = 6

    /// 新建孩子的默认名：「孩子 N」，N 取最小的空位（删了「孩子 2」再加，新的还叫「孩子 2」）
    static func defaultName(existing: [ChildProfile]) -> String {
        let used = Set(existing.map(\.name))
        var n = 1
        while used.contains("孩子 \(n)") { n += 1 }
        return "孩子 \(n)"
    }

    static func canAdd(_ profiles: [ChildProfile]) -> Bool { profiles.count < maxCount }
    static func canDelete(_ profiles: [ChildProfile]) -> Bool { profiles.count > 1 }

    /// 新孩子：默认名、还没人用的第一个头像和颜色
    static func newProfile(existing: [ChildProfile], id: String) -> ChildProfile {
        let usedAvatars = Set(existing.map(\.avatar))
        let usedColors = Set(existing.map(\.color))
        return ChildProfile(id: id,
                            name: defaultName(existing: existing),
                            avatar: avatars.first { !usedAvatars.contains($0) } ?? avatars[0],
                            color: (0..<colorCount).first { !usedColors.contains($0) } ?? 0)
    }
}

enum ProfileKeys {
    /// 所有孩子共用的 key
    static let shared: Set<String> = ["profiles", "currentProfileId", "hasSeenGuide", "lastBackgroundAt"]

    /// 按孩子分开存的 key（和 DataStore.saveProgress 写的 key 一一对应）
    static let perChild: [String] = [
        "completedLessons", "quizBest", "favoriteWords", "collectedCards", "learnedWords",
        "selectedThemeId", "dailyNewWords", "gameIsSimple", "childName", "avatarEmoji",
        "gameCorrect", "gameAnswered", "studyDates", "completedPhraseScenes", "phraseUnlockAll",
        "phraseShowChinese", "babyWords", "babyStickers", "babyNewPerDay", "babyUnlockAll", "babyMode",
        "babyLastGame", "babyTodayWords", "babyTodayDate",
        "timeLimitMinutes", "showTranslation",
    ]

    /// 按天分桶的 key 前缀（今天学了多久 / 家长加了多少时间）
    static let dailyPrefixes = ["study_", "bonus_"]

    static func prefix(_ profileId: String) -> String { "p.\(profileId)." }

    static func scoped(_ key: String, profile profileId: String) -> String {
        shared.contains(key) ? key : prefix(profileId) + key
    }

    /// 这个没加前缀的 key 是不是旧版本里「按孩子分开」的那一类
    static func isPerChild(_ key: String) -> Bool {
        perChild.contains(key) || dailyPrefixes.contains { key.hasPrefix($0) }
    }

    /// 属于某个孩子的全部 key（删除孩子时用）
    static func keys(of profileId: String, in all: [String]) -> [String] {
        let p = prefix(profileId)
        return all.filter { $0.hasPrefix(p) }
    }

    /// 某个孩子按天分桶的 key（清除进度时只清这个孩子的）
    static func dailyKeys(of profileId: String, in all: [String]) -> [String] {
        dailyPrefixes.flatMap { d in all.filter { $0.hasPrefix(prefix(profileId) + d) } }
    }
}

enum ProfileMigration {
    static let firstId = "p1"

    /// 升级前的老用户：现有进度全部归到孩子 1。名字沿用 childName，默认的「小宝贝」改成「孩子 1」
    static func firstProfile(childName: String?) -> ChildProfile {
        let name = (childName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let keep = !name.isEmpty && name != "小宝贝"
        return ChildProfile(id: firstId, name: keep ? name : "孩子 1", avatar: ProfileRoster.avatars[0], color: 0)
    }

    /// 要复制的 key：旧 key → 孩子 1 名下的新 key。只复制、不删旧 key（出问题时旧版还能读）
    static func copies(existingKeys: [String], to profileId: String = firstId) -> [(from: String, to: String)] {
        existingKeys
            .filter(ProfileKeys.isPerChild)
            .sorted()
            .map { ($0, ProfileKeys.scoped($0, profile: profileId)) }
    }
}

/// 「谁来学？」页什么时候出现：2 个以上孩子时，打开 App 先进；从后台回来超过 10 分钟也进
enum WhoIsLearning {
    static let awayLimit: TimeInterval = 10 * 60

    static func onLaunch(profileCount: Int) -> Bool { profileCount >= 2 }

    static func onReturn(profileCount: Int, backgroundedAt: Date?, now: Date) -> Bool {
        guard profileCount >= 2, let since = backgroundedAt else { return false }
        return now.timeIntervalSince(since) > awayLimit
    }
}

// MARK: - 备份（version 2：包含所有孩子）

struct FamilyBackup: Codable, Equatable {
    struct Entry: Codable, Equatable {
        var profile: ChildProfile
        var progress: ProgressSnapshot
    }
    var version: Int = 2
    var exportedAt: String
    var profiles: [Entry]

    var childNames: [String] { profiles.map(\.profile.name) }
}

enum BackupCodec {
    enum Parsed: Equatable {
        /// 新格式：所有孩子。导入前要家长确认，确认之前不写任何数据
        case family(FamilyBackup)
        /// 旧格式：一份进度，导入到当前孩子
        case single(ProgressSnapshot)
        case invalid
    }

    static func encode(_ backup: FamilyBackup) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(backup), let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    /// 只解析，不改任何数据
    static func parse(_ text: String) -> Parsed {
        guard let data = text.data(using: .utf8) else { return .invalid }
        if let family = try? JSONDecoder().decode(FamilyBackup.self, from: data), family.version >= 2,
           !family.profiles.isEmpty {
            return .family(family)
        }
        if let single = ProgressCodec.decode(text) { return .single(single) }
        return .invalid
    }

    /// 确认框里的话
    static func confirmMessage(_ backup: FamilyBackup) -> String {
        "会用备份里的 \(backup.profiles.count) 个孩子（\(backup.childNames.joined(separator: "、"))）替换现在的全部孩子和进度，不能撤销。"
    }
}

import Foundation
import XCTest
@testable import KidsEnglishCore

/// 多孩子档案：key 规则、老数据迁移、来回切换互不影响、默认名、人数上下限、「谁来学？」时机、备份新旧格式。
final class ProfilesTests: XCTestCase {

    // MARK: - key

    func testPerChildKeysGetPrefixedAndSharedKeysDoNot() {
        XCTAssertEqual(ProfileKeys.scoped("learnedWords", profile: "p1"), "p.p1.learnedWords")
        XCTAssertEqual(ProfileKeys.scoped("study_2026-10-23", profile: "p2"), "p.p2.study_2026-10-23")
        for key in ["profiles", "currentProfileId", "hasSeenGuide", "lastBackgroundAt"] {
            XCTAssertEqual(ProfileKeys.scoped(key, profile: "p1"), key, "\(key) 是共用的")
        }
        XCTAssertTrue(ProfileKeys.isPerChild("bonus_2026-10-23"))
        XCTAssertTrue(ProfileKeys.isPerChild("babyWords"))
        XCTAssertFalse(ProfileKeys.isPerChild("hasSeenGuide"))
    }

    // MARK: - 迁移

    /// 老用户的所有进度都复制到孩子 1 名下，值一个不差；旧 key 留着；跑两遍结果一样
    func testMigrationCopiesEveryOldKeyToChildOneAndKeepsOriginals() {
        var store: [String: String] = [
            "learnedWords": "apple,cat", "completedPhraseScenes": "L1-1", "babyWords": "{}",
            "study_2026-10-22": "300", "bonus_2026-10-22": "600", "timeLimitMinutes": "30",
            "childName": "Lily", "hasSeenGuide": "true", "favoriteWords": "dog",
        ]
        let original = store
        func migrate() {
            for c in ProfileMigration.copies(existingKeys: Array(store.keys)) where store[c.to] == nil {
                store[c.to] = store[c.from]
            }
        }
        migrate()
        for (k, v) in original where ProfileKeys.isPerChild(k) {
            XCTAssertEqual(store["p.p1.\(k)"], v, "\(k) 没复制到孩子 1")
            XCTAssertEqual(store[k], v, "旧 key \(k) 不能删")
        }
        XCTAssertNil(store["p.p1.hasSeenGuide"], "共用的 key 不复制")
        let once = store
        migrate()
        XCTAssertEqual(store, once, "迁移跑两遍结果要一样")
    }

    func testFirstProfileKeepsNameButReplacesDefaultBaby() {
        XCTAssertEqual(ProfileMigration.firstProfile(childName: "Lily").name, "Lily")
        XCTAssertEqual(ProfileMigration.firstProfile(childName: "小宝贝").name, "孩子 1")
        XCTAssertEqual(ProfileMigration.firstProfile(childName: nil).name, "孩子 1")
        XCTAssertEqual(ProfileMigration.firstProfile(childName: nil).id, "p1")
    }

    /// 两个孩子来回切换，各自的 key 互不影响
    func testTwoChildrenDoNotShareProgress() {
        var store: [String: [String]] = [:]
        store[ProfileKeys.scoped("learnedWords", profile: "p1")] = ["apple"]
        store[ProfileKeys.scoped("learnedWords", profile: "p2")] = ["cat", "dog"]
        store[ProfileKeys.scoped("learnedWords", profile: "p1")]?.append("banana")
        XCTAssertEqual(store["p.p1.learnedWords"], ["apple", "banana"])
        XCTAssertEqual(store["p.p2.learnedWords"], ["cat", "dog"])
        let all = Array(store.keys) + ["p.p10.learnedWords", "hasSeenGuide"]
        XCTAssertEqual(ProfileKeys.keys(of: "p1", in: all), ["p.p1.learnedWords"], "删孩子 1 不能误删 p10")
        XCTAssertEqual(ProfileKeys.dailyKeys(of: "p1", in: ["p.p1.study_x", "p.p2.study_x", "study_x"]),
                       ["p.p1.study_x"])
    }

    // MARK: - 名字与人数

    func testDefaultNamesFillTheSmallestGap() {
        func p(_ name: String) -> ChildProfile { ChildProfile(id: name, name: name, avatar: "cat", color: 0) }
        XCTAssertEqual(ProfileRoster.defaultName(existing: []), "孩子 1")
        XCTAssertEqual(ProfileRoster.defaultName(existing: [p("孩子 1"), p("孩子 3")]), "孩子 2")
        XCTAssertEqual(ProfileRoster.defaultName(existing: [p("Lily"), p("孩子 1")]), "孩子 2")
    }

    func testAtMostFourAtLeastOne() {
        var list: [ChildProfile] = []
        for i in 0..<ProfileRoster.maxCount {
            XCTAssertTrue(ProfileRoster.canAdd(list))
            list.append(ProfileRoster.newProfile(existing: list, id: "p\(i)"))
        }
        XCTAssertFalse(ProfileRoster.canAdd(list), "最多 4 个")
        XCTAssertEqual(Set(list.map(\.avatar)).count, 4, "新孩子默认用还没人用的头像")
        XCTAssertEqual(Set(list.map(\.color)).count, 4)
        XCTAssertFalse(ProfileRoster.canDelete(Array(list.prefix(1))), "最后一个不能删")
        XCTAssertEqual(ProfileRoster.avatars.count, 8)
    }

    // MARK: - 「谁来学？」

    func testWhoIsLearningTiming() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertFalse(WhoIsLearning.onLaunch(profileCount: 1))
        XCTAssertTrue(WhoIsLearning.onLaunch(profileCount: 2))
        XCTAssertFalse(WhoIsLearning.onReturn(profileCount: 2, backgroundedAt: now.addingTimeInterval(-9 * 60), now: now))
        XCTAssertTrue(WhoIsLearning.onReturn(profileCount: 2, backgroundedAt: now.addingTimeInterval(-11 * 60), now: now))
        XCTAssertFalse(WhoIsLearning.onReturn(profileCount: 1, backgroundedAt: now.addingTimeInterval(-60 * 60), now: now))
        XCTAssertFalse(WhoIsLearning.onReturn(profileCount: 2, backgroundedAt: nil, now: now))
    }

    // MARK: - 备份

    private let oldBackup = """
    {"collectedCards":[],"completedLessons":["l1-01"],"dailyNewWords":10,"exportedAt":"x",
     "favoriteWords":[],"gameAnswered":0,"gameCorrect":0,"learnedWords":["apple"],"quizBest":{},
     "showTranslationDefault":true,"studyDates":[],"timeLimitMinutes":20,"version":1}
    """

    func testOldFormatParsesAsSingleChild() {
        guard case .single(let s) = BackupCodec.parse(oldBackup) else { return XCTFail("旧格式应导入到当前孩子") }
        XCTAssertEqual(s.learnedWords, ["apple"])
        XCTAssertEqual(s.completedLessons, ["l1-01"], "旧课文进度照样带着")
    }

    func testFamilyBackupRoundTripsAndListsNames() throws {
        guard case .single(let snap) = BackupCodec.parse(oldBackup) else { return XCTFail() }
        let family = FamilyBackup(exportedAt: "x", profiles: [
            .init(profile: ChildProfile(id: "p1", name: "Lily", avatar: "cat", color: 0), progress: snap),
            .init(profile: ChildProfile(id: "p2", name: "Leo", avatar: "dog", color: 1), progress: snap),
        ])
        let text = BackupCodec.encode(family)
        guard case .family(let back) = BackupCodec.parse(text) else { return XCTFail("新格式解析失败") }
        XCTAssertEqual(back, family)
        XCTAssertEqual(back.childNames, ["Lily", "Leo"])
        let msg = BackupCodec.confirmMessage(back)
        XCTAssertTrue(msg.contains("2 个孩子") && msg.contains("Lily") && msg.contains("Leo") && msg.contains("不能撤销"))
    }

    /// 取消导入时不改任何数据：解析是纯函数，只有家长确认后才会调用 DataStore.applyFamilyBackup
    func testParsingNeverChangesAnything() {
        let before = oldBackup
        _ = BackupCodec.parse(oldBackup)
        _ = BackupCodec.parse("{not json")
        XCTAssertEqual(oldBackup, before)
        XCTAssertEqual(BackupCodec.parse("{not json"), .invalid)
        XCTAssertEqual(BackupCodec.parse(#"{"version":2,"exportedAt":"x","profiles":[]}"#), .invalid,
                       "没有孩子的新格式备份不能用来替换")
    }
}

import XCTest
@testable import KidsEnglishCore

/// 头像 / 名字加入备份快照后，旧备份仍要能导入。
final class ProfileFieldTests: XCTestCase {

    func testSnapshotCarriesProfileFields() throws {
        let snapshot = ProgressSnapshot(
            version: 1,
            exportedAt: "2026-10-19T09:00:00Z",
            completedLessons: [],
            learnedWords: ["apple"],
            favoriteWords: [],
            collectedCards: [],
            quizBest: [:],
            selectedThemeId: nil,
            dailyNewWords: 10,
            timeLimitMinutes: 20,
            showTranslationDefault: true,
            gameAnswered: 0,
            gameCorrect: 0,
            studyDates: [],
            childName: "朵朵",
            avatarEmoji: "🐼"
        )
        let json = ProgressCodec.encode(snapshot)
        let decoded = ProgressCodec.decode(json)
        XCTAssertEqual(decoded?.childName, "朵朵")
        XCTAssertEqual(decoded?.avatarEmoji, "🐼")
    }

    func testOldSnapshotWithoutProfileFieldsStillDecodes() throws {
        let json = """
        {"version":1,"exportedAt":"2026-01-01T00:00:00Z","completedLessons":[],"learnedWords":[],
         "favoriteWords":[],"collectedCards":[],"quizBest":{},"dailyNewWords":10,
         "timeLimitMinutes":20,"showTranslationDefault":true,"gameAnswered":0,
         "gameCorrect":0,"studyDates":[]}
        """
        let decoded = ProgressCodec.decode(json)
        XCTAssertNotNil(decoded)
        XCTAssertNil(decoded?.childName)
        XCTAssertNil(decoded?.avatarEmoji)
    }
}

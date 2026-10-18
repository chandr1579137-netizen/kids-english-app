import XCTest
@testable import KidsEnglishCore

/// 游戏题池难度、每日时长、连续天数的纯逻辑。
final class UsageRulesTests: XCTestCase {

    // MARK: - 游戏题池

    private func word(_ text: String, level: Int?) -> WordEntry {
        WordEntry(word: text, phonetic: nil, meaningCn: nil, meaningEn: nil,
                  partOfSpeech: nil, examples: nil, emoji: nil, level: level)
    }

    func testSimplePoolKeepsEasyWords() {
        let words = (0..<30).map { word("easy\($0)", level: 1) }
            + (0..<10).map { word("hard\($0)", level: 3) }
        let pool = GamePool.filtered(words, simple: true)
        XCTAssertEqual(pool.count, 30)
        XCTAssertTrue(pool.allSatisfy { ($0.level ?? 1) <= 2 })
    }

    func testSimplePoolFallsBackWhenTooFew() {
        let words = (0..<10).map { word("easy\($0)", level: 2) }
            + (0..<20).map { word("hard\($0)", level: 3) }
        let pool = GamePool.filtered(words, simple: true)
        XCTAssertEqual(pool.count, 30, "简单词不足 20 个时回退全量，避免题池反复")
    }

    func testStandardPoolKeepsEverything() {
        let words = [word("a", level: 1), word("b", level: 3)]
        XCTAssertEqual(GamePool.filtered(words, simple: false).count, 2)
    }

    func testMissingLevelCountsAsEasy() {
        let words = (0..<25).map { word("noLevel\($0)", level: nil) }
        let pool = GamePool.filtered(words, simple: true)
        XCTAssertEqual(pool.count, 25, "没有 level 字段的词按 1 级处理")
    }

    // MARK: - 每日时长

    func testAllowanceAddsBonus() {
        XCTAssertEqual(StudyTime.allowance(limitMinutes: 20, bonusSeconds: 0), 1200)
        XCTAssertEqual(StudyTime.allowance(limitMinutes: 20, bonusSeconds: 600), 1800)
    }

    func testTimeUpBoundary() {
        XCTAssertFalse(StudyTime.isTimeUp(studiedSeconds: 1199, limitMinutes: 20, bonusSeconds: 0))
        XCTAssertTrue(StudyTime.isTimeUp(studiedSeconds: 1200, limitMinutes: 20, bonusSeconds: 0))
        XCTAssertTrue(StudyTime.isTimeUp(studiedSeconds: 1800, limitMinutes: 20, bonusSeconds: 600))
    }

    func testUnlimitedNeverTimeUp() {
        XCTAssertFalse(StudyTime.isTimeUp(studiedSeconds: 99999, limitMinutes: 0, bonusSeconds: 0))
    }

    // MARK: - 连续天数

    private var utc: TimeZone { TimeZone(identifier: "UTC")! }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar.date(from: components)!
    }

    private func key(_ year: Int, _ month: Int, _ day: Int) -> String {
        DayKey.key(for: self.day(year, month, day), timeZone: utc)
    }

    func testStreakCountsTodayBackwards() {
        let dates = [key(2026, 10, 16), key(2026, 10, 17), key(2026, 10, 18)]
        XCTAssertEqual(Streak.count(studyDates: dates, today: day(2026, 10, 18), timeZone: utc), 3)
    }

    func testStreakStartsFromYesterdayWhenTodayMissing() {
        let dates = [key(2026, 10, 16), key(2026, 10, 17)]
        XCTAssertEqual(Streak.count(studyDates: dates, today: day(2026, 10, 18), timeZone: utc), 2)
    }

    func testStreakBreaksOnGap() {
        let dates = [key(2026, 10, 18), key(2026, 10, 16)]
        XCTAssertEqual(Streak.count(studyDates: dates, today: day(2026, 10, 18), timeZone: utc), 1)
    }

    func testStreakZeroWhenTwoDaysMissing() {
        let dates = [key(2026, 10, 16)]
        XCTAssertEqual(Streak.count(studyDates: dates, today: day(2026, 10, 18), timeZone: utc), 0)
        XCTAssertEqual(Streak.count(studyDates: [], today: day(2026, 10, 18), timeZone: utc), 0)
    }
}

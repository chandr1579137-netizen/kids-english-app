import Foundation
import SwiftUI

@Observable
class DataStore {
    // 数据
    var lessons: [Lesson] = []
    var words: [WordEntry] = []
    var songs: [Song] = []
    var wordThemes: [WordTheme] = []
    var audioMap: [String: String] = [:]
    var wordAudioMap: [String: String] = [:]
    var wordDict: [String: WordEntry] = [:]

    // 进度（持久化）
    var completedLessons: Set<String> = []
    var quizBest: [String: Double] = [:]
    var favoriteWords: Set<String> = []
    var collectedCards: Set<String> = []
    var learnedWords: Set<String> = []
    var selectedThemeId: String? = nil
    var dailyNewWords: Int = 10
    var gameCorrect: Int = 0
    var gameAnswered: Int = 0
    var studyDates: [String] = []

    // 家长控制
    var timeLimitMinutes: Int = 20   // 0 = 不限
    var studySecondsToday: Double = 0
    var bonusSecondsToday: Double = 0
    var timeUp: Bool = false
    var showTranslationDefault = true

    private let defaults = UserDefaults.standard
    private var timer: Timer?
    private var todayKey: String = ""
    private var isForeground = true
    private var wordIndex: [String: URL] = [:]
    private var coverIndex: [String: URL] = [:]
    private var didIndexImages = false

    init() {
        loadJSON()
        loadProgress()
        startDayTracking()
    }

    // MARK: - 数据加载

    private func loadJSON() {
        var base: [Lesson] = []
        for lv in 1...7 {
            base.append(contentsOf: load("lessons-l\(lv).json", as: [Lesson].self) ?? [])
        }
        base.append(contentsOf: load("custom-lessons.json", as: [Lesson].self) ?? [])
        lessons = base
        lessons.sort { ($0.level, $0.id) < ($1.level, $1.id) }
        var allWords: [WordEntry] = []
        for part in ["a", "b", "c", "d"] {
            allWords.append(contentsOf: load("words-\(part).json", as: [WordEntry].self) ?? [])
        }
        // 全量词典：课文里点任意词都能查到（不受低龄白名单影响）
        for w in allWords { wordDict[w.word.lowercased()] = w }
        var baseSongs = load("songs.json", as: [Song].self) ?? []
        baseSongs.append(contentsOf: load("custom-songs.json", as: [Song].self) ?? [])
        songs = baseSongs
        var am = load("audio-map.json", as: [String: String].self) ?? [:]
        for (k, v) in (load("custom-audio-map.json", as: [String: String].self) ?? [:]) { am[k] = v }
        audioMap = am
        wordAudioMap = load("word-audio-map.json", as: [String: String].self) ?? [:]
        wordThemes = load("word-themes.json", as: [WordTheme].self) ?? []

        // 低龄白名单：words-*.json 是全龄语料（夹杂 is / genesis / 1000 这类词），
        // 可学词表只保留 word-themes.json 里策展过的词。主题空了就说明资源没打包好，
        // 这时回退到全量，宁可多学也不要空屏。
        let curated = Set(wordThemes.flatMap { $0.words.map { $0.lowercased() } })
        words = curated.isEmpty
            ? allWords
            : allWords.filter { curated.contains($0.word.lowercased()) }
    }

    private func load<T: Decodable>(_ name: String, as type: T.Type) -> T? {
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        guard let url = Bundle.main.url(forResource: base, withExtension: ext),
              let data = try? Data(contentsOf: url) else {
            print("⚠️ 找不到资源: \(name)")
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - 资源路径

    func audioURL(forLesson lessonId: String, paragraphId: String) -> URL? {
        guard let file = audioMap["\(lessonId)#\(paragraphId)"] else { return nil }
        return Bundle.main.resourceURL?.appendingPathComponent("audio/\(file)")
    }

    func audioURL(forWord word: String) -> URL? {
        guard let file = wordAudioMap[word.lowercased()] else { return nil }
        return Bundle.main.resourceURL?.appendingPathComponent("audio/\(file)")
    }

    func bestAudioURL(forWord word: String) -> URL? {
        audioURL(forWord: word)
    }

    /// 预生成的慢速文件。没有时界面改用同一条音频的 0.75 倍速。
    func slowAudioURL(forWord word: String) -> URL? {
        guard let file = wordAudioMap[word.lowercased()],
              let root = Bundle.main.resourceURL else { return nil }
        let url = root.appendingPathComponent("audio-slow/\(file)")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func songAudioURL(_ songId: String) -> URL? {
        guard let root = Bundle.main.resourceURL else { return nil }
        let nested = root.appendingPathComponent("audio/songs/\(songId).mp3")
        if FileManager.default.fileExists(atPath: nested.path) { return nested }
        let flat = root.appendingPathComponent("audio/\(songId).mp3")
        if FileManager.default.fileExists(atPath: flat.path) { return flat }
        return nil
    }

    func coverURL(forLesson lessonId: String) -> URL? {
        ensureImageIndex()
        if let lesson = lessons.first(where: { $0.id == lessonId }),
           let cover = lesson.coverImage {
            let base = URL(fileURLWithPath: cover).deletingPathExtension().lastPathComponent.lowercased()
            if let url = coverIndex[base] { return url }
        }
        return coverIndex[lessonId.lowercased()]
    }

    func iconURL(forWord word: String) -> URL? {
        ensureImageIndex()
        return wordIndex[word.lowercased()]
    }

    private func ensureImageIndex() {
        guard !didIndexImages, let root = Bundle.main.resourceURL else { return }
        didIndexImages = true
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return }
        let exts: Set<String> = ["png", "jpg", "jpeg", "webp"]
        for case let url as URL in enumerator {
            let ext = url.pathExtension.lowercased()
            guard exts.contains(ext) else { continue }
            let base = url.deletingPathExtension().lastPathComponent.lowercased()
            let path = url.path
            if path.contains("/word-icons/") {
                wordIndex[base] = url
            } else if path.contains("/ui-icons/") {
                continue
            } else if path.contains("/covers/") || path.contains("/lesson-illustrations/") {
                if coverIndex[base] == nil { coverIndex[base] = url }
            }
        }
    }

    func lookupWord(_ raw: String) -> WordEntry? {
        let w = raw.lowercased().trimmingCharacters(in: .punctuationCharacters)
        return wordDict[w]
    }

    // MARK: - 主题与今日计划

    func words(forTheme themeId: String) -> [WordEntry] {
        guard let theme = wordThemes.first(where: { $0.id == themeId }) else { return [] }
        return theme.words.compactMap { wordDict[$0.lowercased()] }
    }

    func themeProgress(themeId: String) -> (done: Int, total: Int) {
        let list = words(forTheme: themeId)
        let done = list.filter { learnedWords.contains($0.id) }.count
        return (done, list.count)
    }

    func wordsForCurrentBook() -> [WordEntry] {
        if let id = selectedThemeId {
            return words(forTheme: id)
        }
        return words
    }

    /// 全部单词时先学能看图的主题（水果、动物、颜色…），虚词和抽象词靠后。
    /// 选了某一本词书时，按这本书自己的顺序。
    static let picturableThemeOrder = [
        "fruits", "animals", "colors", "numbers", "body", "family", "foods", "vehicles",
        "home", "nature", "toys", "stationery", "places", "actions", "adjectives"
    ]

    private var wordThemeRank: [String: (tier: Int, index: Int)] = [:]
    private var didRankThemes = false

    private func ensureThemeRank() {
        guard !didRankThemes else { return }
        didRankThemes = true
        for (tier, themeId) in Self.picturableThemeOrder.enumerated() {
            guard let theme = wordThemes.first(where: { $0.id == themeId }) else { continue }
            for (index, word) in theme.words.enumerated() {
                let key = word.lowercased()
                if wordThemeRank[key] == nil {
                    wordThemeRank[key] = (tier, index)
                }
            }
        }
    }

    func planDays() -> [[WordEntry]] {
        let pool: [WordEntry]
        if selectedThemeId != nil {
            pool = wordsForCurrentBook().filter { !learnedWords.contains($0.id) }
        } else {
            ensureThemeRank()
            pool = words
                .filter { !learnedWords.contains($0.id) }
                .sorted { a, b in
                    let ra = wordThemeRank[a.id] ?? (tier: 900, index: 0)
                    let rb = wordThemeRank[b.id] ?? (tier: 900, index: 0)
                    if ra.tier != rb.tier { return ra.tier < rb.tier }
                    if ra.index != rb.index { return ra.index < rb.index }
                    return (a.level ?? 1) < (b.level ?? 1)
                }
        }
        let size = max(1, dailyNewWords)
        guard !pool.isEmpty else { return [] }
        var days: [[WordEntry]] = []
        var index = 0
        while index < pool.count {
            let end = min(index + size, pool.count)
            days.append(Array(pool[index..<end]))
            index = end
        }
        return days
    }

    /// 课文没有封面文件时，用课里最具体的那个词的 emoji。
    func coverEmoji(for lessonId: String) -> String {
        ensureThemeRank()
        guard let lesson = lessons.first(where: { $0.id == lessonId }) else { return "📖" }
        var best: (tier: Int, emoji: String)?
        for para in lesson.content {
            for timing in para.words {
                let key = timing.word.lowercased().trimmingCharacters(in: .punctuationCharacters)
                guard let emoji = wordDict[key]?.emoji, !emoji.isEmpty else { continue }
                let tier = wordThemeRank[key]?.tier ?? 900
                guard tier < 14 else { continue }
                if best == nil || tier < best!.tier {
                    best = (tier, emoji)
                }
            }
        }
        return best?.emoji ?? "📖"
    }

    func markLearned(_ word: String) {
        learnedWords.insert(word.lowercased())
    }

    func noteAttempt(correct: Bool) {
        gameAnswered += 1
        if correct { gameCorrect += 1 }
        saveProgress()
    }

    var gameAccuracy: Int {
        guard gameAnswered > 0 else { return 0 }
        return Int((Double(gameCorrect) / Double(gameAnswered) * 100).rounded())
    }

    // MARK: - 关卡解锁

    func isUnlocked(_ lesson: Lesson) -> Bool {
        guard let idx = lessons.firstIndex(where: { $0.id == lesson.id }) else { return false }
        if idx == 0 { return true }
        return completedLessons.contains(lessons[idx - 1].id)
    }

    func lessons(for level: Int) -> [Lesson] {
        lessons.filter { $0.level == level }
    }

    func completeLesson(_ id: String, quizScore: Double?) {
        completedLessons.insert(id)
        if let s = quizScore {
            let old = quizBest[id] ?? 0
            quizBest[id] = max(old, s)
        }
        saveProgress()
    }

    // MARK: - 持久化

    private func loadProgress() {
        completedLessons = Set(defaults.stringArray(forKey: "completedLessons") ?? [])
        if let d = defaults.dictionary(forKey: "quizBest") as? [String: Double] { quizBest = d }
        favoriteWords = Set(defaults.stringArray(forKey: "favoriteWords") ?? [])
        collectedCards = Set(defaults.stringArray(forKey: "collectedCards") ?? [])
        learnedWords = Set(defaults.stringArray(forKey: "learnedWords") ?? [])
        let theme = defaults.string(forKey: "selectedThemeId") ?? ""
        selectedThemeId = theme.isEmpty ? nil : theme
        dailyNewWords = defaults.object(forKey: "dailyNewWords") as? Int ?? 10
        gameCorrect = defaults.integer(forKey: "gameCorrect")
        gameAnswered = defaults.integer(forKey: "gameAnswered")
        studyDates = defaults.stringArray(forKey: "studyDates") ?? []
        timeLimitMinutes = defaults.object(forKey: "timeLimitMinutes") as? Int ?? 20
        showTranslationDefault = defaults.object(forKey: "showTranslation") as? Bool ?? true
        todayKey = dayString()
        studySecondsToday = defaults.double(forKey: "study_\(todayKey)")
        bonusSecondsToday = defaults.double(forKey: "bonus_\(todayKey)")
        refreshTimeUp()
    }

    func saveProgress() {
        defaults.set(Array(completedLessons), forKey: "completedLessons")
        defaults.set(quizBest, forKey: "quizBest")
        defaults.set(Array(favoriteWords), forKey: "favoriteWords")
        defaults.set(Array(collectedCards), forKey: "collectedCards")
        defaults.set(Array(learnedWords), forKey: "learnedWords")
        defaults.set(selectedThemeId ?? "", forKey: "selectedThemeId")
        defaults.set(dailyNewWords, forKey: "dailyNewWords")
        defaults.set(gameCorrect, forKey: "gameCorrect")
        defaults.set(gameAnswered, forKey: "gameAnswered")
        defaults.set(studyDates, forKey: "studyDates")
        defaults.set(timeLimitMinutes, forKey: "timeLimitMinutes")
        defaults.set(showTranslationDefault, forKey: "showTranslation")
        defaults.set(bonusSecondsToday, forKey: "bonus_\(todayKey)")
    }

    // MARK: - 每日时长（只统计前台）

    private func dayString(_ date: Date = Date()) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    func setForeground(_ active: Bool) {
        isForeground = active
        if active { markStudyDay() }
    }

    private func markStudyDay() {
        let key = dayString()
        if !studyDates.contains(key) {
            studyDates.append(key)
            defaults.set(studyDates, forKey: "studyDates")
        }
    }

    var studyDayCount: Int { studyDates.count }

    var streakDays: Int {
        let dates = Set(studyDates)
        let cal = Calendar.current
        var day = Date()
        if !dates.contains(dayString(day)) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
            if !dates.contains(dayString(day)) { return 0 }
        }
        var count = 0
        while dates.contains(dayString(day)) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    private func allowanceSeconds() -> Double {
        Double(timeLimitMinutes * 60) + bonusSecondsToday
    }

    private func refreshTimeUp() {
        if timeLimitMinutes > 0, studySecondsToday >= allowanceSeconds() {
            timeUp = true
        }
    }

    private func startDayTracking() {
        todayKey = dayString()
        markStudyDay()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.dayString() != self.todayKey {
                self.todayKey = self.dayString()
                self.studySecondsToday = 0
                self.bonusSecondsToday = 0
                self.timeUp = false
                self.markStudyDay()
            }
            guard self.isForeground, !self.timeUp else { return }
            self.studySecondsToday += 1
            self.defaults.set(self.studySecondsToday, forKey: "study_\(self.todayKey)")
            if self.timeLimitMinutes > 0,
               self.studySecondsToday >= self.allowanceSeconds() {
                self.timeUp = true
            }
        }
    }

    /// 家长验证通过后，再给一整段限时，而不是马上又被锁上。
    func grantExtraTime() {
        let minutes = timeLimitMinutes > 0 ? timeLimitMinutes : 20
        bonusSecondsToday += Double(minutes * 60)
        timeUp = false
        defaults.set(bonusSecondsToday, forKey: "bonus_\(todayKey)")
    }

    func resetTimeUp() {
        grantExtraTime()
    }

    // MARK: - 学习报告

    var completedCount: Int { completedLessons.count }

    func wrongWordsToday() -> [String] { [] }

    func studyMinutesToday() -> Int { Int(studySecondsToday / 60) }

    // MARK: - 跨天与重置

    /// App 长时间挂在前台跨过零点时，今日计数必须换到新的一天，
    /// 否则「每日限时」会把昨天的用量算到今天，一睁眼就被锁。
    func rolloverDayIfNeeded() {
        let today = dayString()
        guard today != todayKey else { return }
        todayKey = today
        studySecondsToday = defaults.double(forKey: "study_\(today)")
        bonusSecondsToday = defaults.double(forKey: "bonus_\(today)")
        timeUp = false
        refreshTimeUp()
    }

    /// 清空全部学习进度（家长中心用）。保留每日限时的设置本身。
    func resetAllProgress() {
        completedLessons.removeAll()
        learnedWords.removeAll()
        favoriteWords.removeAll()
        collectedCards.removeAll()
        gameAnswered = 0
        gameCorrect = 0
        studySecondsToday = 0
        bonusSecondsToday = 0
        timeUp = false

        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix("study_") || key.hasPrefix("bonus_") {
            defaults.removeObject(forKey: key)
        }
        saveProgress()
    }

    // MARK: - 备份与恢复

    /// 进度快照。换机或重装时靠一段 JSON 带走，不需要登录或云同步。
    private struct ProgressSnapshot: Codable {
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

    func exportSnapshotJSON() -> String {
        let snapshot = ProgressSnapshot(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: Date()),
            completedLessons: completedLessons.sorted(),
            learnedWords: learnedWords.sorted(),
            favoriteWords: favoriteWords.sorted(),
            collectedCards: collectedCards.sorted(),
            quizBest: quizBest,
            selectedThemeId: selectedThemeId,
            dailyNewWords: dailyNewWords,
            timeLimitMinutes: timeLimitMinutes,
            showTranslationDefault: showTranslationDefault,
            gameAnswered: gameAnswered,
            gameCorrect: gameCorrect,
            studyDates: studyDates
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snapshot),
              let text = String(data: data, encoding: .utf8) else { return "{}" }
        return text
    }

    /// 返回给界面显示的结果文案；解析失败时不做任何修改。
    @discardableResult
    func importSnapshotJSON(_ text: String) -> String {
        guard let data = text.data(using: .utf8),
              let snapshot = try? JSONDecoder().decode(ProgressSnapshot.self, from: data) else {
            return "这段文字不是有效的进度备份"
        }
        completedLessons = Set(snapshot.completedLessons)
        learnedWords = Set(snapshot.learnedWords)
        favoriteWords = Set(snapshot.favoriteWords)
        collectedCards = Set(snapshot.collectedCards)
        quizBest = snapshot.quizBest
        selectedThemeId = snapshot.selectedThemeId
        dailyNewWords = snapshot.dailyNewWords
        timeLimitMinutes = snapshot.timeLimitMinutes
        showTranslationDefault = snapshot.showTranslationDefault
        gameAnswered = snapshot.gameAnswered
        gameCorrect = snapshot.gameCorrect
        studyDates = snapshot.studyDates
        saveProgress()
        refreshTimeUp()
        return "已恢复：\(snapshot.completedLessons.count) 篇课文、\(snapshot.learnedWords.count) 个单词"
    }
}

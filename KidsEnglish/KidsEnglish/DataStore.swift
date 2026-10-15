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
    var selectedBookId: String? = nil
    var wordBookGroups: [WordBookGroup] = []
    var bookCitation: String = ""
    var memories: [String: WordMemory] = [:]
    var progressToken: Int = 0
    var dailyNewWords: Int = 3
    var age4: Age4Catalog?
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
        for part in ["a", "b", "c", "d", "e"] {
            allWords.append(contentsOf: load("words-\(part).json", as: [WordEntry].self) ?? [])
        }
        words = allWords
        var baseSongs = load("songs.json", as: [Song].self) ?? []
        baseSongs.append(contentsOf: load("custom-songs.json", as: [Song].self) ?? [])
        songs = baseSongs
        var am = load("audio-map.json", as: [String: String].self) ?? [:]
        for (k, v) in (load("custom-audio-map.json", as: [String: String].self) ?? [:]) { am[k] = v }
        audioMap = am
        wordAudioMap = load("word-audio-map.json", as: [String: String].self) ?? [:]
        wordThemes = load("word-themes.json", as: [WordTheme].self) ?? []
        if let catalog = load("word-books.json", as: WordBookCatalog.self) {
            wordBookGroups = catalog.groups
            bookCitation = catalog.citation
        }
        age4 = load("age4-path.json", as: Age4Catalog.self)
        for w in words { wordDict[w.word.lowercased()] = w }
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
        guard let id = selectedBookId else { return words }
        return entries(forBook: id)
    }

    func entries(forBook id: String) -> [WordEntry] {
        guard let book = wordBookGroups.flatMap(\.books).first(where: { $0.id == id }) else { return [] }
        if let themeId = book.themeId {
            return words(forTheme: themeId)
        }
        var seen = Set<String>()
        var result: [WordEntry] = []
        for word in book.words ?? [] {
            let key = word.lowercased()
            guard seen.insert(key).inserted, let entry = wordDict[key] else { continue }
            result.append(entry)
        }
        return result
    }

    func currentBookTitle() -> String {
        guard let id = selectedBookId,
              let book = wordBookGroups.flatMap(\.books).first(where: { $0.id == id }) else {
            return "全部单词"
        }
        return book.nameCn
    }

    func selectBook(_ id: String?) {
        selectedBookId = id
        saveProgress()
    }

    /// 全部单词时先学能看图的主题（水果、动物、颜色…），虚词和抽象词靠后。
    /// 选了某一本词书时，按这本书自己的顺序。
    static let picturableThemeOrder = [
        "fruits", "animals", "colors", "numbers", "body", "family", "foods", "vehicles",
        "home", "nature", "toys", "stationery", "places", "time", "actions", "adjectives",
        "functions", "others"
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
        if selectedBookId != nil {
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
        let key = word.lowercased()
        learnedWords.insert(key)
        var memory = memories[key] ?? WordMemory()
        memory.wrong = false
        memory.mastered = true
        scheduleForward(&memory)
        memories[key] = memory
        saveProgress()
    }

    func markWrong(_ word: String) {
        let key = word.lowercased()
        var memory = memories[key] ?? WordMemory()
        memory.wrong = true
        memory.mastered = false
        memory.wrongDay = dayString()
        memory.lapses += 1
        memory.interval = 0
        memory.due = dayString()
        memory.ease = max(1.3, memory.ease - 0.2)
        memories[key] = memory
        saveProgress()
    }

    func noteAttempt(correct: Bool, word: String? = nil) {
        gameAnswered += 1
        if correct {
            gameCorrect += 1
            saveProgress()
        } else if let word, !word.isEmpty {
            markWrong(word)
        } else {
            saveProgress()
        }
    }

    func reviewEntries() -> [WordEntry] {
        let today = dayString()
        var seen = Set<String>()
        var result: [WordEntry] = []
        func add(_ key: String) {
            guard seen.insert(key).inserted, let entry = wordDict[key] else { return }
            result.append(entry)
        }
        for (key, memory) in memories {
            let activeWrong = memory.wrong && !memory.mastered
            let dueLearned = learnedWords.contains(key) && (memory.due.isEmpty || memory.due <= today)
            if activeWrong || dueLearned { add(key) }
        }
        for key in learnedWords where memories[key] == nil { add(key) }
        return result.sorted { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
    }

    func wrongBookEntries() -> [WordEntry] {
        memories.compactMap { key, memory in
            guard memory.wrong && !memory.mastered else { return nil }
            return wordDict[key]
        }
        .sorted { $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
    }

    func wrongWordsToday() -> [String] {
        let today = dayString()
        return memories.compactMap { key, memory in
            guard memory.wrong && !memory.mastered, memory.wrongDay == today else { return nil }
            return key
        }
        .sorted()
    }

    var wrongBookCount: Int {
        memories.values.filter { $0.wrong && !$0.mastered }.count
    }

    // MARK: - 4 岁启蒙

    func age4UnlockedPacks() -> [Age4Pack] {
        (age4?.packs ?? []).filter { !$0.locked }
    }

    func age4LockedPacks() -> [Age4Pack] {
        (age4?.packs ?? []).filter(\.locked)
    }

    func age4UnlockedWords() -> [WordEntry] {
        var seen = Set<String>()
        var result: [WordEntry] = []
        for pack in age4UnlockedPacks() {
            for word in pack.words {
                let key = word.lowercased()
                guard seen.insert(key).inserted, let entry = wordDict[key] else { continue }
                result.append(entry)
            }
        }
        return result
    }

    func age4Today() -> [WordEntry] {
        let size = max(1, dailyNewWords)
        return Array(age4UnlockedWords().filter { !learnedWords.contains($0.id) }.prefix(size))
    }

    func age4Review() -> [WordEntry] {
        let allowed = Set(age4UnlockedWords().map(\.id))
        return reviewEntries().filter { allowed.contains($0.id) }
    }

    func age4Pack(for entry: WordEntry) -> Age4Pack? {
        let key = entry.id
        return (age4?.packs ?? []).first { pack in
            pack.words.contains { $0.lowercased() == key }
        }
    }

    func age4Sentence(for entry: WordEntry) -> String {
        guard let pack = age4Pack(for: entry) else { return entry.word }
        let shown = entry.word
        let lower = shown.lowercased()
        switch pack.id {
        case "greet":
            return "\(capitalized(shown))!"
        case "family":
            return "This is \(capitalized(shown))."
        case "animals", "clothes":
            return "It's \(article(lower)) \(lower)."
        case "colors":
            return "It's \(lower)."
        case "numbers":
            return "One, two, three."
        case "numbers-2":
            return "Six, seven, eight."
        case "food":
            if ["milk", "water", "rice", "bread"].contains(lower) {
                return "I see \(lower)."
            }
            return "I see \(article(lower)) \(lower)."
        case "body":
            return "Touch your \(lower)."
        case "actions":
            return "I can \(lower)."
        case "weather":
            return "I see \(lower)."
        default:
            return pack.pattern
        }
    }

    func age4PackWords(_ pack: Age4Pack) -> [WordEntry] {
        pack.words.compactMap { wordDict[$0.lowercased()] }
    }

    func childLessons() -> [Lesson] {
        let ids = age4?.childLessonIds ?? []
        return ids.compactMap { id in lessons.first { $0.id == id } }
    }

    func childSongs() -> [Song] {
        let ids = age4?.childSongIds ?? []
        return ids.compactMap { id in songs.first { $0.id == id } }
    }

    func laterSongs() -> [Song] {
        let open = Set(age4?.childSongIds ?? [])
        return songs.filter { !open.contains($0.id) }
    }

    func age4Song() -> Song? {
        let seed = age4Today().first ?? age4UnlockedWords().first
        if let seed, let pack = age4Pack(for: seed),
           let song = songs.first(where: { $0.id == pack.songId }) {
            return song
        }
        return childSongs().first
    }

    private func article(_ word: String) -> String {
        guard let first = word.lowercased().first else { return "a" }
        return "aeiou".contains(first) ? "an" : "a"
    }

    private func capitalized(_ word: String) -> String {
        guard let first = word.first else { return word }
        return String(first).uppercased() + word.dropFirst()
    }

    private func scheduleForward(_ memory: inout WordMemory) {
        if memory.interval <= 0 {
            memory.interval = 1
        } else if memory.interval == 1 {
            memory.interval = 3
        } else {
            let next = Int((Double(memory.interval) * memory.ease).rounded())
            memory.interval = min(60, max(1, next))
        }
        memory.ease = min(3.0, memory.ease + 0.1)
        memory.due = dateByAdding(days: memory.interval)
    }

    private func dateByAdding(days: Int) -> String {
        let next = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return dayString(next)
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
        let book = defaults.string(forKey: "selectedBookId") ?? ""
        if book.isEmpty {
            let theme = defaults.string(forKey: "selectedThemeId") ?? ""
            selectedBookId = theme.isEmpty ? nil : theme
        } else {
            selectedBookId = book
        }
        if let data = defaults.data(forKey: "wordMemories"),
           let decoded = try? JSONDecoder().decode([String: WordMemory].self, from: data) {
            memories = decoded
        }
        if let stored = defaults.object(forKey: "dailyNewWords") as? Int, (3...8).contains(stored) {
            dailyNewWords = stored
        } else {
            dailyNewWords = age4?.dailyNew ?? 3
        }
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
        progressToken += 1
        defaults.set(Array(completedLessons), forKey: "completedLessons")
        defaults.set(quizBest, forKey: "quizBest")
        defaults.set(Array(favoriteWords), forKey: "favoriteWords")
        defaults.set(Array(collectedCards), forKey: "collectedCards")
        defaults.set(Array(learnedWords), forKey: "learnedWords")
        defaults.set(selectedBookId ?? "", forKey: "selectedBookId")
        if let data = try? JSONEncoder().encode(memories) {
            defaults.set(data, forKey: "wordMemories")
        }
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

    func studyMinutesToday() -> Int { Int(studySecondsToday / 60) }
}

struct WordMemory: Codable, Equatable {
    var ease: Double = 2.5
    var interval: Int = 0
    var due: String = ""
    var lapses: Int = 0
    var wrong: Bool = false
    var wrongDay: String = ""
    var mastered: Bool = false
}

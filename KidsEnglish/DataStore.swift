import Foundation
import SwiftUI

@Observable
class DataStore {
    // 数据
    var lessons: [Lesson] = []
    var words: [WordEntry] = []
    var songs: [Song] = []
    var audioMap: [String: String] = [:]       // "lessonId#paragraphId" -> mp3 文件名
    var wordAudioMap: [String: String] = [:]   // "apple" -> mp3 文件名
    var wordDict: [String: WordEntry] = [:]    // 小写单词 -> 词条
    var wordThemes: [WordTheme] = []           // 主题词包

    // 进度（持久化）
    var completedLessons: Set<String> = []
    var quizBest: [String: Double] = [:]
    var favoriteWords: Set<String> = []
    var collectedCards: Set<String> = []

    // 家长控制
    var timeLimitMinutes: Int = 20   // 0 = 不限
    var studySecondsToday: Double = 0
    var timeUp: Bool = false
    var showTranslationDefault = true

    private let defaults = UserDefaults.standard
    private var timer: Timer?
    private var todayKey: String = ""

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
        words = allWords
        var baseSongs = load("songs.json", as: [Song].self) ?? []
        baseSongs.append(contentsOf: load("custom-songs.json", as: [Song].self) ?? [])
        songs = baseSongs
        var am = load("audio-map.json", as: [String: String].self) ?? [:]
        for (k, v) in (load("custom-audio-map.json", as: [String: String].self) ?? [:]) { am[k] = v }
        audioMap = am
        wordAudioMap = load("word-audio-map.json", as: [String: String].self) ?? [:]
        for w in words { wordDict[w.word.lowercased()] = w }
        wordThemes = load("word-themes.json", as: [WordTheme].self) ?? []
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

    func songAudioURL(_ songId: String) -> URL? {
        Bundle.main.resourceURL?.appendingPathComponent("audio/songs/\(songId).mp3")
    }

    func coverURL(forLesson lessonId: String) -> URL? {
        Bundle.main.resourceURL?.appendingPathComponent("covers/\(lessonId).jpg")
    }

    func lookupWord(_ raw: String) -> WordEntry? {
        let w = raw.lowercased().trimmingCharacters(in: .punctuationCharacters)
        return wordDict[w]
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
        timeLimitMinutes = defaults.object(forKey: "timeLimitMinutes") as? Int ?? 20
        showTranslationDefault = defaults.object(forKey: "showTranslation") as? Bool ?? true
    }

    func saveProgress() {
        defaults.set(Array(completedLessons), forKey: "completedLessons")
        defaults.set(quizBest, forKey: "quizBest")
        defaults.set(Array(favoriteWords), forKey: "favoriteWords")
        defaults.set(Array(collectedCards), forKey: "collectedCards")
        defaults.set(timeLimitMinutes, forKey: "timeLimitMinutes")
        defaults.set(showTranslationDefault, forKey: "showTranslation")
    }

    // MARK: - 每日时长统计

    private func dayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func startDayTracking() {
        todayKey = dayString()
        studySecondsToday = defaults.double(forKey: "study_\(todayKey)")
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.dayString() != self.todayKey {
                self.todayKey = self.dayString()
                self.studySecondsToday = 0
                self.timeUp = false
            }
            self.studySecondsToday += 1
            self.defaults.set(self.studySecondsToday, forKey: "study_\(self.todayKey)")
            if self.timeLimitMinutes > 0,
               self.studySecondsToday >= Double(self.timeLimitMinutes * 60),
               !self.timeUp {
                self.timeUp = true
            }
        }
    }

    func resetTimeUp() {
        timeUp = false
    }

    // MARK: - 学习报告

    var completedCount: Int { completedLessons.count }

    func wrongWordsToday() -> [String] { [] }  // v1 占位，后续记录错词

    func studyMinutesToday() -> Int { Int(studySecondsToday / 60) }

    // MARK: - 主题词包

    func words(forTheme themeId: String) -> [WordEntry] {
        guard let theme = wordThemes.first(where: { $0.id == themeId }) else { return [] }
        return theme.words.compactMap { wordDict[$0.lowercased()] }
    }

    func themeProgress(themeId: String) -> (done: Int, total: Int) {
        let list = words(forTheme: themeId)
        let done = list.filter { collectedCards.contains($0.id) }.count
        return (done, list.count)
    }
}

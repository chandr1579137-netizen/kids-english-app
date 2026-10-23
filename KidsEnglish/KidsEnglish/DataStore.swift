import Foundation
import SwiftUI

@Observable
class DataStore {
    // 数据
    var words: [WordEntry] = []
    var songs: [Song] = []
    var wordThemes: [WordTheme] = []
    var audioMap: [String: String] = [:]
    var wordAudioMap: [String: String] = [:]
    /// 卡片/游戏/收藏用的词条（一词多义只显示与词图一致的义项）
    var wordDict: [String: WordEntry] = [:]
    /// 首页可学词表（数字本只留 one..ten；「单词卡」和巩固练习仍用全量 words）
    var homeWords: [WordEntry] = []
    /// 「说一说」口语课（Resources/phrases/phrases.json）
    var phraseCatalog: PhraseCatalog? = nil
    /// 宝宝模式词包（Resources/baby-path.json）
    var babyData: BabyPathData? = nil

    // 进度（持久化）
    var completedLessons: Set<String> = []
    var quizBest: [String: Double] = [:]
    var favoriteWords: Set<String> = []
    var collectedCards: Set<String> = []
    var learnedWords: Set<String> = []
    var selectedThemeId: String? = nil
    var dailyNewWords: Int = 10
    /// 首次启动的家长说明卡是否看过
    var hasSeenGuide: Bool = false
    /// 巩固练习是否只出简单档（level 1–2）的词
    var gameIsSimple: Bool = true
    /// 孩子自己设置的名字与头像（「我的」页可改）
    var childName: String = "小宝贝"
    var avatarEmoji: String = "🧒"
    var gameCorrect: Int = 0
    var gameAnswered: Int = 0
    var studyDates: [String] = []
    /// 口语课已完成的场景（id 如 L1-1）。
    /// 旧课文已删除；completedLessons / quizBest 仍从存储读出、随备份导出导入，只是界面不再显示（老数据不丢）。
    var completedPhraseScenes: Set<String> = []
    /// 宝宝模式：每个学过的词的复习状态（key 是词）
    var babyWords: [String: BabyWordState] = [:]
    /// 宝宝模式：每天完成后得到的贴纸（日期 → 那天的贴纸词）
    var babyStickers: [String: String] = [:]

    // 家长控制
    var timeLimitMinutes: Int = 20   // 0 = 不限
    var studySecondsToday: Double = 0
    var bonusSecondsToday: Double = 0
    var timeUp: Bool = false
    var showTranslationDefault = true
    /// 口语课：家长打开后所有场景都能点（默认按顺序解锁）
    var phraseUnlockAll = false
    /// 口语课：卡片下方显示中文（给不会英语的家长陪学；孩子界面默认不显示）
    var phraseShowChinese = false
    /// 宝宝模式（4 岁）：开着时整个 App 换成宝宝底栏（今天 / 图画 / 说一说 / 儿歌 / 家长）
    var babyMode = false
    /// 启蒙模式（代码里仍叫 baby）每天学几个新词（3–8，默认 4；孩子 5 岁，见 decisions.md D8）
    var babyNewPerDay = 4
    /// 宝宝模式：家长打开后所有词包都能学
    var babyUnlockAll = false

    private let defaults = UserDefaults.standard
    private var timer: Timer?
    private var todayKey: String = ""
    private var isForeground = true
    private var wordIndex: [String: URL] = [:]
    private var didIndexImages = false

    init() {
        loadJSON()
        loadProgress()
        startDayTracking()
    }

    // MARK: - 数据加载

    private func loadJSON() {
        var allWords: [WordEntry] = []
        for part in ["a", "b", "c", "d"] {
            allWords.append(contentsOf: load("words-\(part).json", as: [WordEntry].self) ?? [])
        }
        // 卡片/游戏用的词条：一词多义的只显示与词图一致的义项（CardMeaning，见 ProgressKit.swift）
        allWords = allWords.map { CardMeaning.applying(to: $0) }
        for w in allWords { wordDict[w.word.lowercased()] = w }
        var baseSongs = load("songs.json", as: [Song].self) ?? []
        baseSongs.append(contentsOf: load("custom-songs.json", as: [Song].self) ?? [])
        songs = baseSongs
        // 小游戏的句子音频（找一找 / 喂小动物）。旧课文的 audio-map.json 已随课文删除
        audioMap = load("custom-audio-map.json", as: [String: String].self) ?? [:]
        wordAudioMap = load("word-audio-map.json", as: [String: String].self) ?? [:]
        wordThemes = load("word-themes.json", as: [WordTheme].self) ?? []
        if let url = Bundle.main.url(forResource: "baby-path", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            babyData = BabyPathData.decode(data)
        }
        if let url = Bundle.main.url(forResource: "phrases", withExtension: "json", subdirectory: "phrases"),
           let data = try? Data(contentsOf: url) {
            phraseCatalog = PhraseCatalog.decode(data)
        }

        // 低龄白名单：words-*.json 是全龄语料（夹杂 is / genesis / 1000 这类词），
        // 可学词表只保留 word-themes.json 里策展过的词。主题空了就说明资源没打包好，
        // 这时回退到全量，宁可多学也不要空屏。规则与测试见 ProgressKit.swift。
        let allowed = ThemeWhitelist.allowedWords(
            dictionary: allWords.map { $0.word },
            themes: wordThemes.flatMap { $0.words }
        )
        words = allWords.filter { allowed.contains($0.word.lowercased()) }

        // 首页词表：数字本只留 one..ten；「单词卡」和巩固练习仍用全量 words。
        let homeAllowed = HomeBooks.allowedWords(dictionary: allWords.map { $0.word }, themes: wordThemes)
        homeWords = allWords.filter { homeAllowed.contains($0.word.lowercased()) }
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

    func audioURL(forWord word: String) -> URL? {
        guard let file = wordAudioMap[word.lowercased()],
              let url = Bundle.main.resourceURL?.appendingPathComponent("audio/\(file)"),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    func bestAudioURL(forWord word: String) -> URL? {
        audioURL(forWord: word)
    }

    /// 慢速朗读统一用「正常音频 0.7 倍速」：预生成的 audio-slow 不在响度归一化范围内，
    /// 和正文音频混着放会忽大忽小，所以不再使用。
    func slowAudioURL(forWord word: String) -> URL? {
        nil
    }

    func songAudioURL(_ songId: String) -> URL? {
        guard let root = Bundle.main.resourceURL else { return nil }
        let nested = root.appendingPathComponent("audio/songs/\(songId).mp3")
        if FileManager.default.fileExists(atPath: nested.path) { return nested }
        let flat = root.appendingPathComponent("audio/\(songId).mp3")
        if FileManager.default.fileExists(atPath: flat.path) { return flat }
        return nil
    }

    /// 口语课资源：phrases/audio、phrases/img、phrases/avatars（文件夹引用，原样进包）
    func phraseFileURL(_ folder: String, _ file: String) -> URL? {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("phrases/\(folder)/\(file)"),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    func iconURL(forWord word: String) -> URL? {
        ensureImageIndex()
        let key = word.lowercased()
        if let hit = wordIndex[key] { return hit }
        // 多词词条（fire engine / pencil case）的文件名用下划线，避免空格
        return wordIndex[key.replacingOccurrences(of: " ", with: "_")]
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
            }
        }
    }

    // MARK: - 主题与今日计划

    func words(forTheme themeId: String) -> [WordEntry] {
        guard let theme = wordThemes.first(where: { $0.id == themeId }) else { return [] }
        return theme.words.compactMap { wordDict[$0.lowercased()] }
    }

    /// 首页某本书的可学词（数字本只留 one..ten）
    func homeWords(forTheme themeId: String) -> [WordEntry] {
        guard let theme = wordThemes.first(where: { $0.id == themeId }) else { return [] }
        return HomeBooks.homeWords(themeId: themeId, words: theme.words)
            .compactMap { wordDict[$0.lowercased()] }
    }

    /// 首页计划卡上的「已学」计数（跟首页可学词表同口径）
    var homeLearnedCount: Int {
        homeWords.filter { learnedWords.contains($0.id) }.count
    }

    func themeProgress(themeId: String) -> (done: Int, total: Int) {
        let list = words(forTheme: themeId)
        let done = list.filter { learnedWords.contains($0.id) }.count
        return (done, list.count)
    }

    func wordsForCurrentBook() -> [WordEntry] {
        if let id = selectedThemeId {
            return homeWords(forTheme: id)
        }
        return homeWords
    }

    /// 全部单词时先学能看图的主题（水果、动物、颜色…），虚词和抽象词靠后。
    /// 选了某一本词书时，按这本书自己的顺序。
    /// 顺序表在 HomeBooks.themeOrder（17 本词书共用一份），这里只是别名。
    static let picturableThemeOrder = HomeBooks.themeOrder

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
            let unlearned = homeWords.filter { !learnedWords.contains($0.id) }
            // 跨主题交错：第 0 波是每个主题的第一个词，避免大主题独占前 30 天
            pool = StudyPlan.interleavedOrder(unlearned) { entry in
                let r = wordThemeRank[entry.id] ?? (tier: 900, index: 0)
                return StudyPlan.Rank(tier: r.tier, index: r.index)
            } level: { $0.level ?? 1 }
        }
        return StudyPlan.chunked(pool, size: dailyNewWords)
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

    // MARK: - 口语课进度

    /// 记下完成一个场景。第一次完成返回 true（发星星和收集卡），重复学不再发奖励。
    @discardableResult
    func completePhraseScene(_ id: String) -> Bool {
        let first = completedPhraseScenes.insert(id).inserted
        if first { collectedCards.insert(PhraseCards.id(for: id)) }
        saveProgress()
        return first
    }

    // MARK: - 宝宝模式进度

    var babyKnown: Set<String> { Set(babyWords.keys) }

    var todayKeyString: String { dayString() }

    /// 学完一张新词卡：放进第 0 格，明天复习（已经学过的不重置）
    func babyLearn(_ word: String) {
        guard babyWords[word] == nil else { return }
        babyWords[word] = BabyPlan.learned(today: Date(), timeZone: .current)
        learnedWords.insert(word)
        saveProgress()
    }

    /// 复习题第一次就答对 → 升一格；答错 → 回第 0 格明天再来
    func babyReviewed(_ word: String, correct: Bool) {
        guard let state = babyWords[word] else { return }
        babyWords[word] = BabyPlan.after(state, correct: correct, today: Date(), timeZone: .current)
        saveProgress()
    }

    /// 完成今天：发今天的贴纸。一天只发一张，返回是不是今天第一次完成
    @discardableResult
    func babyFinishToday(sticker: String) -> Bool {
        let key = dayString()
        guard babyStickers[key] == nil else { return false }
        babyStickers[key] = sticker
        saveProgress()
        return true
    }

    var babyDoneToday: Bool { babyStickers[dayString()] != nil }

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
        hasSeenGuide = defaults.bool(forKey: "hasSeenGuide")
        gameIsSimple = defaults.object(forKey: "gameIsSimple") as? Bool ?? true
        childName = defaults.string(forKey: "childName") ?? "小宝贝"
        avatarEmoji = defaults.string(forKey: "avatarEmoji") ?? "🧒"
        gameCorrect = defaults.integer(forKey: "gameCorrect")
        gameAnswered = defaults.integer(forKey: "gameAnswered")
        studyDates = defaults.stringArray(forKey: "studyDates") ?? []
        completedPhraseScenes = Set(defaults.stringArray(forKey: "completedPhraseScenes") ?? [])
        phraseUnlockAll = defaults.bool(forKey: "phraseUnlockAll")
        phraseShowChinese = defaults.bool(forKey: "phraseShowChinese")
        if let data = defaults.data(forKey: "babyWords"),
           let states = try? JSONDecoder().decode([String: BabyWordState].self, from: data) {
            babyWords = states
        }
        babyStickers = defaults.dictionary(forKey: "babyStickers") as? [String: String] ?? [:]
        babyNewPerDay = min(max(defaults.object(forKey: "babyNewPerDay") as? Int ?? 4, 3), 8)
        babyUnlockAll = defaults.bool(forKey: "babyUnlockAll")
        // 宝宝模式默认值：全新安装打开；已经有学习进度的老用户保持原来的模式，家长中心可切换
        if let saved = defaults.object(forKey: "babyMode") as? Bool {
            babyMode = saved
        } else {
            babyMode = learnedWords.isEmpty && completedLessons.isEmpty && completedPhraseScenes.isEmpty
        }
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
        defaults.set(hasSeenGuide, forKey: "hasSeenGuide")
        defaults.set(gameIsSimple, forKey: "gameIsSimple")
        defaults.set(childName, forKey: "childName")
        defaults.set(avatarEmoji, forKey: "avatarEmoji")
        defaults.set(gameCorrect, forKey: "gameCorrect")
        defaults.set(gameAnswered, forKey: "gameAnswered")
        defaults.set(studyDates, forKey: "studyDates")
        defaults.set(Array(completedPhraseScenes), forKey: "completedPhraseScenes")
        defaults.set(phraseUnlockAll, forKey: "phraseUnlockAll")
        defaults.set(phraseShowChinese, forKey: "phraseShowChinese")
        if let data = try? JSONEncoder().encode(babyWords) { defaults.set(data, forKey: "babyWords") }
        defaults.set(babyStickers, forKey: "babyStickers")
        defaults.set(babyNewPerDay, forKey: "babyNewPerDay")
        defaults.set(babyUnlockAll, forKey: "babyUnlockAll")
        defaults.set(babyMode, forKey: "babyMode")
        defaults.set(timeLimitMinutes, forKey: "timeLimitMinutes")
        defaults.set(showTranslationDefault, forKey: "showTranslation")
        defaults.set(bonusSecondsToday, forKey: "bonus_\(todayKey)")
    }

    // MARK: - 每日时长（只统计前台）

    private func dayString(_ date: Date = Date()) -> String {
        return DayKey.key(for: date, timeZone: .current)
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

    /// 连续学习天数；规则与单测见 ProgressKit.swift 的 Streak。
    var streakDays: Int { Streak.count(studyDates: studyDates, today: Date()) }

    private func allowanceSeconds() -> Double {
        StudyTime.allowance(limitMinutes: timeLimitMinutes, bonusSeconds: bonusSecondsToday)
    }

    private func refreshTimeUp() {
        if StudyTime.isTimeUp(studiedSeconds: studySecondsToday,
                              limitMinutes: timeLimitMinutes,
                              bonusSeconds: bonusSecondsToday) {
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


    func wrongWordsToday() -> [String] { [] }

    func studyMinutesToday() -> Int { Int(studySecondsToday / 60) }

    // MARK: - 跨天与重置

    /// App 长时间挂在前台跨过零点时，今日计数必须换到新的一天，
    /// 否则「每日限时」会把昨天的用量算到今天，一睁眼就被锁。
    func rolloverDayIfNeeded() {
        let now = Date()
        guard DayKey.isNewDay(stored: todayKey, now: now, timeZone: .current) else { return }
        let today = DayKey.key(for: now, timeZone: .current)
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
        completedPhraseScenes.removeAll()
        babyWords.removeAll()
        babyStickers.removeAll()
        gameAnswered = 0
        gameCorrect = 0
        studySecondsToday = 0
        bonusSecondsToday = 0
        timeUp = false

        let staleKeys = ResetPlan.keysToPurge(from: Array(defaults.dictionaryRepresentation().keys))
        for key in staleKeys {
            defaults.removeObject(forKey: key)
        }
        saveProgress()
    }

    /// 记下「家长说明卡已看过」，之后不再自动弹出。
    func markGuideSeen() {
        hasSeenGuide = true
        defaults.set(true, forKey: "hasSeenGuide")
    }

    // MARK: - 备份与恢复

    /// 进度快照的数据结构见 ProgressKit.swift 的 ProgressSnapshot。
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
            studyDates: studyDates,
            childName: childName,
            avatarEmoji: avatarEmoji,
            completedPhraseScenes: completedPhraseScenes.sorted(),
            babyWords: babyWords,
            babyStickers: babyStickers
        )
        return ProgressCodec.encode(snapshot)
    }

    /// 返回给界面显示的结果文案；解析失败时不做任何修改。
    @discardableResult
    func importSnapshotJSON(_ text: String) -> String {
        guard let snapshot = ProgressCodec.decode(text) else {
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
        if let name = snapshot.childName, !name.isEmpty { childName = name }
        if let emoji = snapshot.avatarEmoji, !emoji.isEmpty { avatarEmoji = emoji }
        // 旧备份没有口语进度（nil）：保留本机现有的，不覆盖成空
        if let scenes = snapshot.completedPhraseScenes { completedPhraseScenes = Set(scenes) }
        if let words = snapshot.babyWords { babyWords = words }
        if let stickers = snapshot.babyStickers { babyStickers = stickers }
        saveProgress()
        refreshTimeUp()
        return ProgressCodec.summary(snapshot)
    }
}

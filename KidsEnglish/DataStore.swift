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
    /// 真实打卡日期记录（按当前孩子持久化，格式 yyyy-MM-dd）
    var checkInDates: [String] = []
    /// 口语课已完成的场景（id 如 L1-1）。
    /// 旧课文已删除；completedLessons / quizBest 仍从存储读出、随备份导出导入，只是界面不再显示（老数据不丢）。
    var completedPhraseScenes: Set<String> = []
    /// 宝宝模式：每个学过的词的复习状态（key 是词）
    var babyWords: [String: BabyWordState] = [:]
    /// 宝宝模式：每天完成后得到的贴纸（日期 → 那天的贴纸词）
    var babyStickers: [String: String] = [:]
    /// 启蒙模式 v2：上一次玩的游戏种类（同一个游戏不连着两天出现）
    var babyLastGame: BabyGameKind? = nil
    /// 启蒙模式 v2：今天这节课学的词（供家长中心「今天」卡片展示，即便今天已学完也不变）
    var babyTodayWords: [String] = []
    var babyTodayDate: String = ""

    // 多孩子档案（Profiles.swift）：按孩子分开的 key 一律经 k(_:) 加前缀 `p.<id>.`
    var profiles: [ChildProfile] = []
    var currentProfileId: String = ProfileMigration.firstId
    /// 「谁来学？」页是否正在显示（ContentView 盖在最上层）
    var whoIsLearningVisible = false

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
        loadProfiles()
        loadProgress()
        whoIsLearningVisible = LaunchOptions.isUIScreenshotRun ? LaunchOptions.forceWho
            : WhoIsLearning.onLaunch(profileCount: profiles.count)
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
        if first && !PhraseReview.isReview(id) { collectedCards.insert(PhraseCards.id(for: id)) }
        saveProgress()
        return first
    }

    // MARK: - 宝宝模式进度

    var babyKnown: Set<String> { Set(babyWords.keys) }

    var todayKeyString: String { dayString() }

    /// 已完成贴纸的天数（不含今天），用来判断今天是不是每 4 天一次的复习日
    var babyCompletedDaysBeforeToday: Int {
        let today = dayString()
        return babyStickers.keys.filter { $0 != today }.count
    }

    /// 记下今天课上学的词与玩过的游戏
    func babyNoteTodaySession(words: [String], game: BabyGameKind) {
        let today = dayString()
        if babyTodayDate != today || babyTodayWords.isEmpty {
            babyTodayDate = today
            babyTodayWords = words
        }
        babyLastGame = game
        saveProgress()
    }

    /// 学完一张新词卡：放进第 0 格，明天复习（已经学过的不重置）
    func babyLearn(_ word: String) {
        guard babyWords[word] == nil else { return }
        babyWords[word] = BabyPlan.learned(today: Date(), timeZone: .current)
        learnedWords.insert(word)
        let today = dayString()
        if babyTodayDate != today {
            babyTodayDate = today
            babyTodayWords = []
        }
        if !babyTodayWords.contains(word) {
            babyTodayWords.append(word)
        }
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

    // MARK: - 多孩子档案

    /// 按孩子分开的 key：`p.<当前孩子 id>.<原 key>`（共用的 key 原样返回）
    func k(_ key: String) -> String { ProfileKeys.scoped(key, profile: currentProfileId) }

    var currentProfile: ChildProfile? { profiles.first { $0.id == currentProfileId } }

    /// 截图用的假档案只在内存里，不写进存储（截图之间共用一个安装）
    private var profilesAreDemo: Bool { LaunchOptions.demoProfiles > 0 }

    private func loadProfiles() {
        if let data = defaults.data(forKey: "profiles"),
           let list = try? JSONDecoder().decode([ChildProfile].self, from: data), !list.isEmpty {
            profiles = list
        } else {
            // 第一次用多孩子档案：现有进度全部复制到孩子 1 名下（旧 key 不删，能回退）
            let first = ProfileMigration.firstProfile(childName: defaults.string(forKey: "childName"))
            for c in ProfileMigration.copies(existingKeys: Array(defaults.dictionaryRepresentation().keys),
                                             to: first.id) where defaults.object(forKey: c.to) == nil {
                defaults.set(defaults.object(forKey: c.from), forKey: c.to)
            }
            profiles = [first]
            currentProfileId = first.id
            saveProfiles()
        }
        let saved = defaults.string(forKey: "currentProfileId") ?? profiles[0].id
        currentProfileId = profiles.contains { $0.id == saved } ? saved : profiles[0].id
        if profilesAreDemo { profiles = LaunchOptions.demoProfileList(profiles) }
    }

    private func saveProfiles() {
        guard !profilesAreDemo else { return }
        if let data = try? JSONEncoder().encode(profiles) { defaults.set(data, forKey: "profiles") }
        defaults.set(currentProfileId, forKey: "currentProfileId")
    }

    /// 换孩子：先存当前孩子，再读新孩子的全部进度
    func switchProfile(_ id: String) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        if id != currentProfileId {
            saveProgress()
            currentProfileId = id
            saveProfiles()
            loadProgress()
        }
        whoIsLearningVisible = false
    }

    /// 添加孩子：默认值和全新安装一样（启蒙模式开、每天 4 个新词、从第一课开始、每日限时 20 分钟）——
    /// 新孩子名下还没有任何 key，loadProgress 读到的都是默认值
    @discardableResult
    func addProfile(name: String?, avatar: String, color: Int) -> ChildProfile? {
        guard ProfileRoster.canAdd(profiles) else { return nil }
        var p = ProfileRoster.newProfile(existing: profiles, id: "p" + UUID().uuidString.prefix(8).lowercased())
        let trimmed = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { p.name = String(trimmed.prefix(10)) }
        p.avatar = avatar
        p.color = color
        profiles.append(p)
        saveProfiles()
        return p
    }

    func updateProfile(_ p: ChildProfile) {
        guard let i = profiles.firstIndex(where: { $0.id == p.id }) else { return }
        profiles[i] = p
        if p.id == currentProfileId { childName = p.name }
        saveProfiles()
    }

    /// 删除孩子：连同他名下的全部 key 一起删。最后一个孩子不能删
    func deleteProfile(_ id: String) {
        guard ProfileRoster.canDelete(profiles), profiles.contains(where: { $0.id == id }) else { return }
        for key in ProfileKeys.keys(of: id, in: Array(defaults.dictionaryRepresentation().keys)) {
            defaults.removeObject(forKey: key)
        }
        profiles.removeAll { $0.id == id }
        if id == currentProfileId {
            currentProfileId = profiles[0].id
            loadProgress()
        }
        saveProfiles()
    }

    func noteBackground(_ date: Date = Date()) {
        defaults.set(date.timeIntervalSince1970, forKey: "lastBackgroundAt")
    }

    /// 回到前台：离开超过 10 分钟、有 2 个以上孩子，就先问「谁来学？」
    func noteForeground(_ now: Date = Date()) {
        let t = defaults.double(forKey: "lastBackgroundAt")
        let since = t > 0 ? Date(timeIntervalSince1970: t) : nil
        if WhoIsLearning.onReturn(profileCount: profiles.count, backgroundedAt: since, now: now) {
            whoIsLearningVisible = true
        }
    }

    // MARK: - 持久化

    private func loadProgress() {
        completedLessons = Set(defaults.stringArray(forKey: k("completedLessons")) ?? [])
        if let d = defaults.dictionary(forKey: k("quizBest")) as? [String: Double] { quizBest = d }
        favoriteWords = Set(defaults.stringArray(forKey: k("favoriteWords")) ?? [])
        collectedCards = Set(defaults.stringArray(forKey: k("collectedCards")) ?? [])
        learnedWords = Set(defaults.stringArray(forKey: k("learnedWords")) ?? [])
        let theme = defaults.string(forKey: k("selectedThemeId")) ?? ""
        selectedThemeId = theme.isEmpty ? nil : theme
        dailyNewWords = defaults.object(forKey: k("dailyNewWords")) as? Int ?? 10
        hasSeenGuide = defaults.bool(forKey: "hasSeenGuide")
        gameIsSimple = defaults.object(forKey: k("gameIsSimple")) as? Bool ?? true
        childName = currentProfile?.name ?? defaults.string(forKey: k("childName")) ?? "孩子 1"
        avatarEmoji = defaults.string(forKey: k("avatarEmoji")) ?? "🧒"
        gameCorrect = defaults.integer(forKey: k("gameCorrect"))
        gameAnswered = defaults.integer(forKey: k("gameAnswered"))
        studyDates = defaults.stringArray(forKey: k("studyDates")) ?? []
        checkInDates = defaults.stringArray(forKey: k("checkInDates")) ?? []
        completedPhraseScenes = Set(defaults.stringArray(forKey: k("completedPhraseScenes")) ?? [])
        phraseUnlockAll = defaults.bool(forKey: k("phraseUnlockAll"))
        phraseShowChinese = defaults.bool(forKey: k("phraseShowChinese"))
        if let data = defaults.data(forKey: k("babyWords")),
           let states = try? JSONDecoder().decode([String: BabyWordState].self, from: data) {
            babyWords = states
        } else {
            babyWords = [:]
        }
        babyStickers = defaults.dictionary(forKey: k("babyStickers")) as? [String: String] ?? [:]
        babyLastGame = defaults.string(forKey: k("babyLastGame")).flatMap { BabyGameKind(rawValue: $0) }
        babyTodayWords = defaults.stringArray(forKey: k("babyTodayWords")) ?? []
        babyTodayDate = defaults.string(forKey: k("babyTodayDate")) ?? ""
        babyNewPerDay = min(max(defaults.object(forKey: k("babyNewPerDay")) as? Int ?? 4, 3), 8)
        babyUnlockAll = defaults.bool(forKey: k("babyUnlockAll"))
        // 宝宝模式默认值：全新安装打开；已经有学习进度的老用户保持原来的模式，家长中心可切换
        if let saved = defaults.object(forKey: k("babyMode")) as? Bool {
            babyMode = saved
        } else {
            babyMode = learnedWords.isEmpty && completedLessons.isEmpty && completedPhraseScenes.isEmpty
        }
        timeLimitMinutes = defaults.object(forKey: k("timeLimitMinutes")) as? Int ?? 20
        showTranslationDefault = defaults.object(forKey: k("showTranslation")) as? Bool ?? true
        todayKey = dayString()
        studySecondsToday = defaults.double(forKey: k("study_\(todayKey)"))
        bonusSecondsToday = defaults.double(forKey: k("bonus_\(todayKey)"))
        refreshTimeUp()
    }

    func saveProgress() {
        // 「我的」页改的名字就是这个孩子档案的名字
        if let i = profiles.firstIndex(where: { $0.id == currentProfileId }), profiles[i].name != childName {
            profiles[i].name = childName
            saveProfiles()
        }
        defaults.set(Array(completedLessons), forKey: k("completedLessons"))
        defaults.set(quizBest, forKey: k("quizBest"))
        defaults.set(Array(favoriteWords), forKey: k("favoriteWords"))
        defaults.set(Array(collectedCards), forKey: k("collectedCards"))
        defaults.set(Array(learnedWords), forKey: k("learnedWords"))
        defaults.set(selectedThemeId ?? "", forKey: k("selectedThemeId"))
        defaults.set(dailyNewWords, forKey: k("dailyNewWords"))
        defaults.set(hasSeenGuide, forKey: "hasSeenGuide")
        defaults.set(gameIsSimple, forKey: k("gameIsSimple"))
        defaults.set(childName, forKey: k("childName"))
        defaults.set(avatarEmoji, forKey: k("avatarEmoji"))
        defaults.set(gameCorrect, forKey: k("gameCorrect"))
        defaults.set(gameAnswered, forKey: k("gameAnswered"))
        defaults.set(studyDates, forKey: k("studyDates"))
        defaults.set(checkInDates, forKey: k("checkInDates"))
        defaults.set(Array(completedPhraseScenes), forKey: k("completedPhraseScenes"))
        defaults.set(phraseUnlockAll, forKey: k("phraseUnlockAll"))
        defaults.set(phraseShowChinese, forKey: k("phraseShowChinese"))
        if let data = try? JSONEncoder().encode(babyWords) { defaults.set(data, forKey: k("babyWords")) }
        defaults.set(babyStickers, forKey: k("babyStickers"))
        defaults.set(babyLastGame?.rawValue ?? "", forKey: k("babyLastGame"))
        defaults.set(babyTodayWords, forKey: k("babyTodayWords"))
        defaults.set(babyTodayDate, forKey: k("babyTodayDate"))
        defaults.set(babyNewPerDay, forKey: k("babyNewPerDay"))
        defaults.set(babyUnlockAll, forKey: k("babyUnlockAll"))
        defaults.set(babyMode, forKey: k("babyMode"))
        defaults.set(timeLimitMinutes, forKey: k("timeLimitMinutes"))
        defaults.set(showTranslationDefault, forKey: k("showTranslation"))
        defaults.set(bonusSecondsToday, forKey: k("bonus_\(todayKey)"))
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
            defaults.set(studyDates, forKey: k("studyDates"))
        }
    }

    var studyDayCount: Int { studyDates.count }

    /// 连续学习天数；规则与单测见 ProgressKit.swift 的 Streak。
    var streakDays: Int { Streak.count(studyDates: studyDates, today: Date()) }

    // MARK: - 真实日历与每日打卡

    /// 今日公历中文文本，例如 "10月27日 星期二"
    var todayCalendarString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: Date())
    }

    /// 今天是否已打卡
    var isCheckedInToday: Bool {
        checkInDates.contains(dayString())
    }

    /// 连续打卡天数
    var checkInStreakDays: Int {
        let dates = checkInDates.isEmpty ? studyDates : checkInDates
        return max(1, Streak.count(studyDates: dates, today: Date()))
    }

    /// 真实打卡动作：返回是否为首次今日打卡
    @discardableResult
    func checkInToday() -> Bool {
        let key = dayString()
        var updated = false
        if !checkInDates.contains(key) {
            checkInDates.append(key)
            defaults.set(checkInDates, forKey: k("checkInDates"))
            updated = true
        }
        markStudyDay()
        saveProgress()
        return updated
    }

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
            self.defaults.set(self.studySecondsToday, forKey: self.k("study_\(self.todayKey)"))
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
        defaults.set(bonusSecondsToday, forKey: k("bonus_\(todayKey)"))
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
        studySecondsToday = defaults.double(forKey: k("study_\(today)"))
        bonusSecondsToday = defaults.double(forKey: k("bonus_\(today)"))
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
        babyLastGame = nil
        babyTodayWords.removeAll()
        babyTodayDate = ""
        gameAnswered = 0
        gameCorrect = 0
        studySecondsToday = 0
        bonusSecondsToday = 0
        timeUp = false

        // 只清当前孩子按天分桶的用时，别的孩子不动
        let staleKeys = ProfileKeys.dailyKeys(of: currentProfileId, in: Array(defaults.dictionaryRepresentation().keys))
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

    /// 当前孩子的进度快照（结构见 ProgressKit.swift 的 ProgressSnapshot）
    private func currentSnapshot() -> ProgressSnapshot {
        ProgressSnapshot(
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
    }

    /// 把一份快照写进当前孩子（旧备份缺的字段保留本机现有的，不覆盖成空）
    private func apply(_ snapshot: ProgressSnapshot) {
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
        if let scenes = snapshot.completedPhraseScenes { completedPhraseScenes = Set(scenes) }
        if let words = snapshot.babyWords { babyWords = words }
        if let stickers = snapshot.babyStickers { babyStickers = stickers }
        saveProgress()
        refreshTimeUp()
    }

    /// 别的孩子的进度：直接从存储读，不切换当前孩子（导出会在 SwiftUI 渲染时调用，不能改状态）
    private func storedSnapshot(of id: String) -> ProgressSnapshot {
        func key(_ k: String) -> String { ProfileKeys.scoped(k, profile: id) }
        var words: [String: BabyWordState]? = nil
        if let data = defaults.data(forKey: key("babyWords")) {
            words = try? JSONDecoder().decode([String: BabyWordState].self, from: data)
        }
        let theme = defaults.string(forKey: key("selectedThemeId")) ?? ""
        return ProgressSnapshot(
            version: 1,
            exportedAt: ISO8601DateFormatter().string(from: Date()),
            completedLessons: (defaults.stringArray(forKey: key("completedLessons")) ?? []).sorted(),
            learnedWords: (defaults.stringArray(forKey: key("learnedWords")) ?? []).sorted(),
            favoriteWords: (defaults.stringArray(forKey: key("favoriteWords")) ?? []).sorted(),
            collectedCards: (defaults.stringArray(forKey: key("collectedCards")) ?? []).sorted(),
            quizBest: defaults.dictionary(forKey: key("quizBest")) as? [String: Double] ?? [:],
            selectedThemeId: theme.isEmpty ? nil : theme,
            dailyNewWords: defaults.object(forKey: key("dailyNewWords")) as? Int ?? 10,
            timeLimitMinutes: defaults.object(forKey: key("timeLimitMinutes")) as? Int ?? 20,
            showTranslationDefault: defaults.object(forKey: key("showTranslation")) as? Bool ?? true,
            gameAnswered: defaults.integer(forKey: key("gameAnswered")),
            gameCorrect: defaults.integer(forKey: key("gameCorrect")),
            studyDates: defaults.stringArray(forKey: key("studyDates")) ?? [],
            childName: profiles.first { $0.id == id }?.name,
            avatarEmoji: defaults.string(forKey: key("avatarEmoji")),
            completedPhraseScenes: (defaults.stringArray(forKey: key("completedPhraseScenes")) ?? []).sorted(),
            babyWords: words ?? [:],
            babyStickers: defaults.dictionary(forKey: key("babyStickers")) as? [String: String] ?? [:]
        )
    }

    /// 导出：version 2，包含所有孩子。只读，不改任何状态
    func exportSnapshotJSON() -> String {
        let entries = profiles.map { p in
            FamilyBackup.Entry(profile: p, progress: p.id == currentProfileId ? currentSnapshot() : storedSnapshot(of: p.id))
        }
        return BackupCodec.encode(FamilyBackup(exportedAt: ISO8601DateFormatter().string(from: Date()),
                                               profiles: entries))
    }

    /// 只解析、不写入：新格式要先让家长确认（见 ParentView 的导入确认框）
    func parseBackup(_ text: String) -> BackupCodec.Parsed { BackupCodec.parse(text) }

    /// 旧格式（一份进度）导入到当前孩子。返回给界面显示的结果文案；解析失败时不做任何修改。
    @discardableResult
    func importSnapshotJSON(_ text: String) -> String {
        guard case .single(let snapshot) = BackupCodec.parse(text) else {
            return "这段文字不是有效的进度备份"
        }
        apply(snapshot)
        return ProgressCodec.summary(snapshot)
    }

    /// 新格式：家长确认后，用备份里的孩子整体替换现在的全部孩子和进度
    @discardableResult
    func applyFamilyBackup(_ backup: FamilyBackup) -> String {
        let all = Array(defaults.dictionaryRepresentation().keys)
        for p in profiles {
            for key in ProfileKeys.keys(of: p.id, in: all) { defaults.removeObject(forKey: key) }
        }
        profiles = backup.profiles.map(\.profile)
        for entry in backup.profiles {
            currentProfileId = entry.profile.id
            loadProgress()
            apply(entry.progress)
        }
        currentProfileId = profiles[0].id
        saveProfiles()
        loadProgress()
        return "已恢复：\(backup.profiles.count) 个孩子（\(backup.childNames.joined(separator: "、"))）"
    }
}

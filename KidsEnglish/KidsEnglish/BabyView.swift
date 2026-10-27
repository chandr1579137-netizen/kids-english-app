import SwiftUI
import UIKit

// MARK: - 宝宝模式（4 岁）v2「每天一课更好玩」
//
// 孩子看到五个页签：今天 / 图画 / 说一说 / 儿歌 / 家长。不识字也能自己玩：
// 页面上只有大图、喇叭和会跳的按钮，所有提示都靠声音。
// 「今天」一次约 6–8 分钟，固定 6 步 + 贴纸：
//   1. 唱一唱（儿歌 35 秒，或 4 拍鼓点节奏念词）
//   2. 复习（最多 4 个到期旧词，听音选图）
//   3. 学一学（4 个新词，一词一卡，听 → 录 → 放自己声音）
//   4. 玩一玩（游戏池每天换 1 个：听音选图 / 翻翻乐 G1 / 影子配对 G2 / Tom 说你做 G5，连着两天不重样）
//   5. 句子（今天这一包的 1 个句型套 2 个新词，Tom 先说 → 孩子跟读）
//   6. 自己说（出今天的新词图，不先放音，等孩子先开口 → 再放示范音）
//   7. 贴纸（得今天的贴纸 + Tom 拍手庆祝）
// 每学完 4 天新词，第 5 天是「复习日」：不学新词，戳泡泡自己选今天玩哪个游戏。
// 设计依据见 docs/pm/daily-lesson-v2.md。

// MARK: 启动参数（CI 截图用）

extension LaunchOptions {
    /// `-uiBaby` 截图时进入宝宝模式（截图默认是正常模式，免得改掉原有截图）
    static var forceBaby: Bool { ProcessInfo.processInfo.arguments.contains("-uiBaby") }

    /// `-uiBabyTab 0..4` 宝宝模式首屏页签
    static var babyTab: BabyTab {
        value(for: "-uiBabyTab").flatMap { Int($0) }.flatMap { BabyTab(rawValue: $0) } ?? .today
    }

    /// `-uiBabyStep N` 直接打开「今天」并停在第 N 步，不放声音、不写进度
    static var babyStep: Int? { value(for: "-uiBabyStep").flatMap { Int($0) } }

    /// `-uiBabyDemo correct|wrong|recording|praised|solved` 停在某个状态
    static var babyDemo: String? { value(for: "-uiBabyDemo") }

    /// `-uiBabyKnown N` 截图时假装前 N 个词已经学过、今天都到期（让复习步骤出现）
    static var babyKnown: Int { value(for: "-uiBabyKnown").flatMap { Int($0) } ?? 0 }

    /// `-uiBabyPack <id>` 图画页直接打开某个词包
    static var babyPack: String? { value(for: "-uiBabyPack") }

    /// `-uiBabyDoneToday` 截图时假装今天已经完成（首页显示贴纸和「再玩一次」）
    static var babyDoneToday: Bool { ProcessInfo.processInfo.arguments.contains("-uiBabyDoneToday") }

    /// `-uiBabyStickers N` 截图时假装前 N 天都得了贴纸（贴纸本截图用，不写进度）
    static var babyStickerDemo: Int { value(for: "-uiBabyStickers").flatMap { Int($0) } ?? 0 }

    /// `-uiBabyGame listen|memory|shadow|follow` 截图时强制指定第 4 步的小游戏类型
    static var babyGame: BabyGameKind? {
        switch value(for: "-uiBabyGame") {
        case "listen", "listenChoice": return .listenChoice
        case "memory", "memoryFlip": return .memoryFlip
        case "shadow", "shadowDrag": return .shadowDrag
        case "follow", "followMe": return .followMe
        case "rhyme", "rhymeMatch": return .rhymeMatch
        case "syllable", "syllableClap": return .syllableClap
        default: return nil
        }
    }

    /// `-uiBabyReviewDay` 截图时强制进入第 5 天「复习日」（戳泡泡选游戏）
    static var babyReviewDay: Bool { ProcessInfo.processInfo.arguments.contains("-uiBabyReviewDay") }

    /// `-uiBabyIntro` 截图时停在步骤切换的 Tom 小过场画面
    static var babyIntro: Bool { ProcessInfo.processInfo.arguments.contains("-uiBabyIntro") }

    /// `-uiPhonics` 截图时直接打开自然拼读探索岛
    static var forcePhonics: Bool { ProcessInfo.processInfo.arguments.contains("-uiPhonics") }

    /// `-uiPhonicsLetter <letter>` 打开特定字母详情
    static var phonicsLetter: String? { value(for: "-uiPhonicsLetter") }

    /// `-uiPhonicsQuiz` 打开自然拼读测验
    static var phonicsQuiz: Bool { ProcessInfo.processInfo.arguments.contains("-uiPhonicsQuiz") }

    /// `-uiPhonicsTrain` 截图时直接打开滑音小火车
    static var forcePhonicsTrain: Bool { ProcessInfo.processInfo.arguments.contains("-uiPhonicsTrain") }

    /// `-uiPhonicsCargo` 打开装车厢拼词挑战
    static var phonicsCargoQuiz: Bool { ProcessInfo.processInfo.arguments.contains("-uiPhonicsCargo") }

    /// `-uiPhonicsGroup2` 截图或测试时默认切换至第 2 组字母音
    static var phonicsGroup2: Bool { ProcessInfo.processInfo.arguments.contains("-uiPhonicsGroup2") }

    /// 现在是不是宝宝模式：截图默认走正常模式（原有截图不受影响），加 `-uiBaby` 才进宝宝模式
    static func isBaby(_ store: DataStore) -> Bool {
        isUIScreenshotRun ? forceBaby : store.babyMode
    }
}

// MARK: 页签

enum BabyTab: Int, CaseIterable, Identifiable, KidTabItem {
    case today, pictures, talk, songs, parent

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today: return "今天"
        case .pictures: return "图画"
        case .talk: return "说一说"
        case .songs: return "儿歌"
        case .parent: return "家长"
        }
    }

    var icon: String {
        switch self {
        case .today: return "sun.max"
        case .pictures: return "square.grid.2x2"
        case .talk: return "bubble.left.and.bubble.right"
        case .songs: return "music.note"
        case .parent: return "lock"
        }
    }

    var selectedIcon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .pictures: return "square.grid.2x2.fill"
        case .talk: return "bubble.left.and.bubble.right.fill"
        case .songs: return "music.note"
        case .parent: return "lock.fill"
        }
    }
}

struct BabyRootView: View {
    @State private var tab: BabyTab = LaunchOptions.babyTab

    var body: some View {
        if LaunchOptions.forcePhonicsTrain {
            PhonicsBlendingTrainView()
        } else if LaunchOptions.forcePhonics {
            PhonicsIslandView()
        } else {
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case .today: BabyTodayView()
                    case .pictures: BabyPicturesView()
                    case .talk: PhrasesHomeView()
                    case .songs: SongsView(asTabRoot: true)
                    case .parent:
                        // 截图用 `-uiProfile parent-dash` 跳过数学题，直接拍家长中心
                        if LaunchOptions.profilePage == "parent-dash" {
                            NavigationStack { ParentDashboardView() }
                        } else {
                            NavigationStack { ParentGateView() }
                        }
                    }
                }
                .frame(maxWidth: KidLayout.readableWidth)
                KidTabBar(selection: $tab)
            }
        }
    }
}

// MARK: - 截图用的假数据（只在内存里，不写进度）

enum BabyDemo {
    /// 截图固定在 2026-10-22，结果可复现
    static let today = "2026-10-22"

    static func states(_ data: BabyPathData) -> [String: BabyWordState]? {
        let n = LaunchOptions.babyKnown
        guard n > 0 else { return nil }
        var s: [String: BabyWordState] = [:]
        for (i, w) in data.allWords.prefix(n).enumerated() {
            s[w] = BabyWordState(box: i % 3, due: today)
        }
        return s
    }
}

// MARK: - Tom 三种表情组件

/// Tom 的三种情绪状态：开心（微笑）、歪头想（点错或等孩子开口）、拍手（答对或得贴纸）
struct TomMoodView: View {
    let mood: TomMood
    var size: CGFloat = 68

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PhraseAvatarView(speaker: "tom", size: size, active: mood == .clap)
                .rotationEffect(.degrees(mood == .thinking ? -12 : 0))
                .scaleEffect(mood == .clap ? 1.08 : 1.0)
                .overlay {
                    if mood == .clap {
                        Circle().strokeBorder(PhraseColors.gold, lineWidth: 3.5)
                    }
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.5), value: mood)

            badge
                .offset(x: 4, y: 4)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var badge: some View {
        let badgeSize = max(24, size * 0.38)
        switch mood {
        case .normal, .happy:
            ZStack {
                Circle().fill(Func.positiveDeep)
                Image(systemName: "face.smiling.inverse")
                    .font(.system(size: badgeSize * 0.6, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: badgeSize, height: badgeSize)
            .overlay { Circle().strokeBorder(Color.white, lineWidth: 2) }
        case .thinking:
            ZStack {
                Circle().fill(Func.infoDeep)
                Text("?")
                    .font(.system(size: badgeSize * 0.62, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: badgeSize, height: badgeSize)
            .overlay { Circle().strokeBorder(Color.white, lineWidth: 2) }
        case .clap:
            ZStack {
                Circle().fill(PhraseColors.gold)
                Image(systemName: "hands.clap.fill")
                    .font(.system(size: badgeSize * 0.56, weight: .bold))
                    .foregroundStyle(Palette.ink)
            }
            .frame(width: badgeSize, height: badgeSize)
            .overlay { Circle().strokeBorder(Color.white, lineWidth: 2) }
        }
    }
}

// MARK: - 今天（首页）

struct BabyTodayView: View {
    @Environment(DataStore.self) private var store
    @State private var controller: BabySessionController?
    @State private var bounce = false

    private var known: Set<String> {
        if let d = store.babyData, let s = BabyDemo.states(d) { return Set(s.keys) }
        return store.babyKnown
    }

    private var doneToday: Bool { LaunchOptions.babyDoneToday || store.babyDoneToday }

    private var isReviewDay: Bool {
        if LaunchOptions.babyReviewDay { return true }
        return BabyPlan.isReviewDay(completedDays: store.babyCompletedDaysBeforeToday)
    }

    private var preview: [String] {
        guard let data = store.babyData else { return [] }
        return BabyPlan.newWords(data, known: known, unlockAll: store.babyUnlockAll, count: store.babyNewPerDay)
    }

    var body: some View {
        Group {
            if let controller {
                BabySessionView(c: controller) { self.controller = nil }
            } else {
                home
            }
        }
        .creamBackground()
        .overlay(alignment: .topLeading) {
            if controller == nil {
                HomeProfileButton(size: 52).padding(.leading, 16).padding(.top, 8)
            }
        }
        .onChange(of: store.currentProfileId) { _, _ in
            controller?.stopAll()
            controller = nil
        }
        .onAppear {
            if LaunchOptions.babyStep != nil || LaunchOptions.babyIntro || LaunchOptions.babyGame != nil || LaunchOptions.babyReviewDay,
               controller == nil {
                start(replay: false)
            }
        }
    }

    private var home: some View {
        GeometryReader { geo in
            VStack(spacing: 18) {
                Spacer(minLength: 0)
                // Tom 和今天要学的四张图（或复习日泡泡预告）
                HStack(alignment: .center, spacing: 14) {
                    TomMoodView(mood: doneToday ? .clap : .happy, size: preview.count > 3 ? 84 : 104)
                        .offset(y: bounce ? -10 : 0)
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            if doneToday, let w = todaySticker {
                                BabyPicture(word: pic(w), size: 76)
                                Image(systemName: "checkmark.circle.fill")
                                    .kidFont(34, .bold, maxScale: 1.1)
                                    .foregroundStyle(Func.positiveDeep)
                            } else if isReviewDay {
                                ForEach([("square.grid.2x2.fill", Func.accent),
                                         ("circle.lefthalf.filled", Func.infoDeep),
                                         ("speaker.wave.2.fill", Func.positiveDeep)], id: \.0) { icon, tint in
                                    ZStack {
                                        Circle().fill(tint.opacity(0.18))
                                        Circle().strokeBorder(tint, lineWidth: 2.5)
                                        Image(systemName: icon)
                                            .kidFont(24, .bold)
                                            .foregroundStyle(tint)
                                    }
                                    .frame(width: 58, height: 58)
                                }
                            } else {
                                // 每天 4 个新词时小图缩一点，不然 Tom 会被挤出屏幕
                                ForEach(preview, id: \.self) { w in
                                    BabyPicture(word: pic(w), size: preview.count > 3 ? 56 : 70)
                                }
                            }
                        }
                        .padding(12)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .elevationGround()
                    }
                }

                // 大大的开始按钮
                Button { start(replay: doneToday) } label: {
                    ZStack {
                        Circle().fill(doneToday ? Func.infoDeep : Func.positiveDeep)
                        Image(systemName: doneToday ? "arrow.counterclockwise" : "play.fill")
                            .kidFont(70, .black, maxScale: 1.0)
                            .foregroundStyle(.white)
                            .offset(x: doneToday ? 0 : 6)
                    }
                    .frame(width: min(200, geo.size.width * 0.5), height: min(200, geo.size.width * 0.5))
                    .overlay { Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: 6).padding(6) }
                    .elevationRaised()
                    .scaleEffect(bounce ? 1.06 : 1.0)
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(doneToday ? "再玩一次" : "开始")

                Text(homeSubtitle)
                    .kidFont(18, .bold)
                    .foregroundStyle(Palette.inkMuted)

                stickerWeek
                    .padding(.top, 6)
                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            guard !LaunchOptions.isUIScreenshotRun else { return }
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { bounce = true }
        }
    }

    private var homeSubtitle: String {
        if doneToday { return "今天完成啦！再玩一次？" }
        if isReviewDay { return "今天是复习日！戳泡泡选游戏" }
        return "今天学 \(preview.count) 个新词"
    }

    /// 词 → 配图用的词（mom 用平涂的 mother 图）。资源包里同名的 mom / dad 是旧 3D 图，不能直接用
    private func pic(_ w: String) -> String { store.babyData?.picture(for: w) ?? w }

    private var todaySticker: String? {
        if LaunchOptions.babyDoneToday { return preview.first ?? store.babyData?.allWords.first }
        return store.babyStickers[store.todayKeyString]
    }

    /// 截图用：前 N 天的假贴纸，按词包顺序取词
    private func demoSticker(_ i: Int, of count: Int) -> String? {
        let n = LaunchOptions.babyStickerDemo
        guard n > 0, i >= count - 1 - n, let words = store.babyData?.allWords else { return nil }
        return words[(i * 5) % words.count]
    }

    /// 这一周的贴纸：完成的日子是那天的贴纸，没完成的是虚线圆圈
    private var stickerWeek: some View {
        let cal = Calendar(identifier: .gregorian)
        let days: [String] = (0..<7).reversed().map { back in
            let d = cal.date(byAdding: .day, value: -back, to: Date()) ?? Date()
            return DayKey.key(for: d, timeZone: .current)
        }
        return HStack(spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                let isToday = i == days.count - 1
                let w = isToday ? (doneToday ? todaySticker : nil) : (store.babyStickers[day] ?? demoSticker(i, of: days.count))
                ZStack {
                    if let w {
                        Circle().fill(PhraseColors.gold.opacity(0.25))
                        BabyPicture(word: pic(w), size: 38)
                            .clipShape(Circle())
                    } else {
                        Circle().strokeBorder(Palette.inkSubtle,
                                              style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    }
                }
                .frame(width: 44, height: 44)
                .overlay {
                    if isToday { Circle().strokeBorder(Func.accent, lineWidth: 3) }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("这周的贴纸")
    }

    private func start(replay: Bool) {
        guard let data = store.babyData else { return }
        controller = BabySessionController(data: data, store: store, replay: replay)
        controller?.start()
    }
}

// MARK: - 一次「今天」的流程控制（6 步 + 贴纸）

@Observable
final class BabySessionController {
    enum Phase: Equatable {
        case idle, listening, inviting, recording, playingBack, praised, solved
    }

    private(set) var steps: [BabyStep]
    let frozen: Bool
    let replay: Bool
    let reviewDay: Bool
    private let data: BabyPathData
    private let store: DataStore
    private let words = AudioPlayer()
    let audio = PhraseAudio()
    let recorder = PhraseVoiceRecorder()
    private let drumPlayer = AudioPlayer()

    /// 拍手数音节实时拍数
    private(set) var drumTaps = 0
    /// 押韵配对中正在播放示范音的卡片（高亮放大）
    private(set) var activeSpeakingWord: String? = nil
    /// 押韵配对答题反馈状态（true: 答对高亮; false: 答错提示）
    private(set) var rhymeFeedback: Bool? = nil
    /// 拍手数音节答题反馈
    private(set) var syllableFeedback: Int? = nil

    private(set) var index = 0
    private(set) var phase: Phase = .idle
    private(set) var tomMood: TomMood = .happy
    private(set) var showingIntro = false
    private(set) var wrong: Set<String> = []
    private(set) var wrongTick = 0
    private(set) var praiseTick = 0
    private(set) var firstTry = true
    private(set) var firstCompletion = false

    /// 第 1 步「唱一唱」当前正在念第几个词（无儿歌词包的 4 拍鼓点节奏念词）
    private(set) var chantIndex = 0

    /// 翻翻乐 G1 状态：当前翻开的卡下标、已配对成功的单词集合、开局偷看正面阶段
    private(set) var memoryFlipped: [Int] = []
    private(set) var memoryMatched: Set<String> = []
    private(set) var memoryPeeking = false

    private let sessionFocusWords: [String]
    private let sessionKnownWords: Set<String>
    private let sessionUnlockAll: Bool
    let sticker: String?
    private var token = 0

    init(data: BabyPathData, store: DataStore, replay: Bool) {
        self.data = data
        self.store = store
        self.replay = replay
        let isFrozen = LaunchOptions.babyStep != nil || LaunchOptions.babyIntro || LaunchOptions.babyGame != nil || LaunchOptions.babyReviewDay
        frozen = isFrozen
        let states = BabyDemo.states(data) ?? store.babyWords
        let known = Set(states.keys)
        let today = isFrozen ? BabyDemo.today : store.todayKeyString
        let isRevDay = LaunchOptions.babyReviewDay || (!isFrozen && !replay && BabyPlan.isReviewDay(completedDays: store.babyCompletedDaysBeforeToday))
        reviewDay = isRevDay

        let forcedGame = LaunchOptions.babyGame
        var newList: [String]
        if isRevDay {
            newList = []
        } else if forcedGame == .followMe {
            // 截图强制测「Tom 说你做」时，如果前几个词不是身体/动作词，取 body 包前 4 个词展示
            let bodyPack = data.packs.first(where: { $0.id == "body" })?.words ?? []
            newList = Array(bodyPack.prefix(BabyPlan.defaultNewPerDay))
        } else {
            let count = isFrozen ? BabyPlan.defaultNewPerDay : store.babyNewPerDay
            newList = BabyPlan.newWords(data, known: known, unlockAll: isFrozen ? false : store.babyUnlockAll, count: count)
        }

        let dueList: [String]
        if isRevDay {
            let source = known.isEmpty ? Array(data.allWords.prefix(16)) : Array(known.prefix(16))
            dueList = source
        } else {
            dueList = BabyPlan.dueReviews(states, today: today)
        }

        sessionFocusWords = newList.isEmpty ? dueList : newList
        sessionKnownWords = known
        sessionUnlockAll = isFrozen ? false : store.babyUnlockAll

        var plan: [BabyStep]
        if isFrozen {
            var rng = SeededGenerator(seed: 7)
            plan = BabyPlan.session(
                data,
                newWords: newList,
                reviews: dueList,
                known: known,
                unlockAll: false,
                gameKind: forcedGame ?? .listenChoice,
                reviewDay: isRevDay,
                using: &rng
            )
        } else {
            var rng = SystemRandomNumberGenerator()
            let picked = BabyPlan.pickGame(for: sessionFocusWords, data: data, lastGame: store.babyLastGame, using: &rng)
            if replay {
                plan = BabyPlan.replay(data, known: known, unlockAll: store.babyUnlockAll, gameKind: picked, using: &rng)
            } else {
                plan = BabyPlan.session(
                    data,
                    newWords: newList,
                    reviews: dueList,
                    known: known,
                    unlockAll: store.babyUnlockAll,
                    gameKind: picked,
                    reviewDay: isRevDay,
                    using: &rng
                )
                store.babyNoteTodaySession(words: Array(sessionFocusWords.prefix(4)), game: picked)
            }
        }

        steps = plan
        sticker = BabyPlan.sticker(for: plan) ?? sessionFocusWords.first
        if let s = LaunchOptions.babyStep {
            index = min(max(s, 0), plan.count - 1)
        } else if let forcedGame {
            // 如果指定了 -uiBabyGame 而没指定 -uiBabyStep，直接跳到该游戏那一步
            if let gameIdx = plan.firstIndex(where: { step in
                switch (forcedGame, step) {
                case (.listenChoice, .game): return true
                case (.memoryFlip, .memoryGame): return true
                case (.shadowDrag, .shadowGame): return true
                case (.followMe, .followMe): return true
                case (.rhymeMatch, .rhymeGame): return true
                case (.syllableClap, .syllableGame): return true
                default: return false
                }
            }) {
                index = gameIdx
            }
        } else if LaunchOptions.babyReviewDay {
            if let pickIdx = plan.firstIndex(where: {
                if case .pickGame = $0 { return true }
                return false
            }) {
                index = pickIdx
            }
        }
    }

    var step: BabyStep { steps[index] }
    var progress: Double { Double(index) / Double(max(steps.count - 1, 1)) }

    func picture(_ word: String) -> String { data.picture(for: word) }
    func sentence(for word: String) -> String? { data.sentence(for: word) }

    func start() {
        if frozen {
            applyDemo()
        } else {
            enter(previousStage: nil)
        }
    }

    private func applyDemo() {
        showingIntro = LaunchOptions.babyIntro
        tomMood = .happy
        switch step {
        case .sing:
            chantIndex = 0
            phase = .listening
        case .review(let r), .game(let r):
            switch LaunchOptions.babyDemo {
            case "correct", "solved":
                phase = .solved
                praiseTick = 1
                tomMood = .clap
            case "wrong":
                phase = .listening
                wrong = Set(r.options.filter { $0 != r.answer }.prefix(1))
                firstTry = false
                tomMood = .thinking
            default:
                phase = .listening
            }
        case .learn:
            switch LaunchOptions.babyDemo {
            case "recording": phase = .recording
            case "praised", "correct": phase = .praised; praiseTick = 1; tomMood = .clap
            default: phase = .inviting
            }
        case .pickGame:
            phase = .inviting
        case .memoryGame(let cards):
            memoryPeeking = false
            switch LaunchOptions.babyDemo {
            case "solved", "correct":
                let unique = Array(Set(cards)).sorted()
                memoryMatched = Set(unique.prefix(2))
                memoryFlipped = [0, 1]
                phase = .solved
                praiseTick = 1
                tomMood = .clap
            default:
                // 默认截图：翻开前两张卡，其余四张盖着，既能看到正面又能看到背面
                memoryMatched = []
                memoryFlipped = [0, 1]
                phase = .listening
            }
        case .shadowGame(let r):
            switch LaunchOptions.babyDemo {
            case "correct", "solved":
                phase = .solved
                praiseTick = 1
                tomMood = .clap
            case "wrong":
                phase = .listening
                wrong = Set(r.options.filter { $0 != r.answer }.prefix(1))
                tomMood = .thinking
            default:
                phase = .listening
            }
        case .followMe:
            switch LaunchOptions.babyDemo {
            case "correct", "solved", "praised":
                phase = .solved
                praiseTick = 1
                tomMood = .clap
            default:
                phase = .inviting
            }
        case .rhymeGame:
            switch LaunchOptions.babyDemo {
            case "correct", "solved":
                phase = .solved
                praiseTick = 1
                tomMood = .clap
            case "wrong":
                phase = .inviting
                tomMood = .thinking
            default:
                phase = .inviting
            }
        case .syllableGame(let r):
            switch LaunchOptions.babyDemo {
            case "correct", "solved":
                phase = .solved
                praiseTick = 1
                tomMood = .clap
                drumTaps = r.count
            case "wrong":
                phase = .inviting
                tomMood = .thinking
            default:
                phase = .inviting
            }
        case .sentence:
            switch LaunchOptions.babyDemo {
            case "recording": phase = .recording
            case "praised", "correct": phase = .praised; praiseTick = 1; tomMood = .clap
            default: phase = .inviting
            }
        case .sayIt:
            switch LaunchOptions.babyDemo {
            case "praised", "correct", "solved":
                phase = .praised
                praiseTick = 1
                tomMood = .clap
            default:
                phase = .inviting
                tomMood = .thinking
            }
        case .done:
            firstCompletion = true
            tomMood = .clap
        }
    }

    // MARK: 音频播放辅助

    func sayWord(_ w: String, rate: Float = 1.0, then: (() -> Void)? = nil) {
        let my = token
        words.onTimeUpdate = { [weak self] t in
            guard t >= 999999, let self, self.token == my else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard self.token == my else { return }
                then?()
            }
        }
        audio.stop()
        let url = store.audioURL(forWord: w)
        words.playWord(w, url: url, rate: rate)
        if url == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                guard let self, self.token == my else { return }
                then?()
            }
        }
    }

    func prompt(_ name: String, then: (() -> Void)? = nil) {
        words.stop()
        let url = store.phraseFileURL("audio", "\(name).mp3")
        if url != nil {
            audio.play(url, onEnd: then)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { then?() }
        }
    }

    // MARK: 进入一步（含阶段切换的 Tom 小过场）

    private func enter(previousStage: BabyStage?) {
        token += 1
        let my = token
        recorder.cancel()
        audio.stop()
        words.stop()
        wrong = []
        firstTry = true
        tomMood = .happy
        drumTaps = 0
        activeSpeakingWord = nil
        rhymeFeedback = nil
        syllableFeedback = nil

        let currentStage = step.stage
        if let stage = currentStage, stage != previousStage {
            showingIntro = true
            let audioName: String
            if case .pickGame = step {
                audioName = "tom_pick_bubble"
            } else {
                audioName = stage.promptAudio
            }
            prompt(audioName) { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    guard let self, self.token == my else { return }
                    self.showingIntro = false
                    self.enterStepBody(token: my)
                }
            }
        } else {
            showingIntro = false
            enterStepBody(token: my)
        }
    }

    /// 孩子等不及小过场时，点一下直接进正题
    func skipIntro() {
        guard !frozen, showingIntro else { return }
        token += 1
        let my = token
        audio.stop()
        words.stop()
        showingIntro = false
        enterStepBody(token: my)
    }

    private func enterStepBody(token my: Int) {
        guard self.token == my else { return }
        switch step {
        case .sing(_, let songId, let ws):
            phase = .listening
            chantIndex = 0
            if let songId, let url = store.songAudioURL(songId) {
                audio.play(url) { [weak self] in
                    guard let self, self.token == my else { return }
                    self.next()
                }
                // 儿歌最长放 35 秒就自动进下一步
                DispatchQueue.main.asyncAfter(deadline: .now() + 35) { [weak self] in
                    guard let self, self.token == my else { return }
                    self.next()
                }
            } else {
                playChantSequence(words: ws, at: 0, token: my)
            }

        case .review(let r), .game(let r), .shadowGame(let r):
            phase = .listening
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                guard let self, self.token == my else { return }
                self.sayWord(r.answer)
            }

        case .learn(let w):
            // 一词一卡：说两遍，然后话筒跳起来请孩子跟着说
            phase = .listening
            sayWord(w) { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    guard let self, self.token == my else { return }
                    self.sayWord(w) { [weak self] in
                        guard let self, self.token == my else { return }
                        self.phase = .inviting
                    }
                }
            }

        case .pickGame:
            phase = .inviting

        case .memoryGame:
            phase = .listening
            memoryMatched = []
            memoryFlipped = []
            memoryPeeking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                guard let self, self.token == my else { return }
                self.memoryPeeking = false
            }

        case .followMe(let w):
            phase = .listening
            prompt("baby_cmd_\(w)") { [weak self] in
                guard let self, self.token == my else { return }
                self.sayWord(w) { [weak self] in
                    guard let self, self.token == my else { return }
                    self.phase = .inviting
                }
            }

        case .rhymeGame(let r):
            phase = .listening
            prompt("tom_do_they_rhyme") { [weak self] in
                guard let self, self.token == my else { return }
                self.playRhymeComparison(r, token: my)
            }

        case .syllableGame(let r):
            phase = .listening
            drumTaps = 0
            prompt("tom_clap_with_me") { [weak self] in
                guard let self, self.token == my else { return }
                self.sayWord(r.word) { [weak self] in
                    guard let self, self.token == my else { return }
                    self.phase = .inviting
                }
            }

        case .sentence(let w, _):
            phase = .listening
            prompt("baby_sent_\(w)") { [weak self] in
                guard let self, self.token == my else { return }
                self.phase = .inviting
            }

        case .sayIt(let w):
            // 第 6 步「自己说」：先不放音！话筒直接跳，等孩子自己说；6 秒没开口再放示范音
            phase = .inviting
            tomMood = .thinking
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
                guard let self, self.token == my, self.phase == .inviting else { return }
                self.revealSayItAnswer(word: w)
            }

        case .done:
            phase = .idle
            tomMood = .clap
            if !replay, let s = sticker {
                firstCompletion = store.babyFinishToday(sticker: s)
            }
            prompt("tom_you_did_it")
        }
    }

    // MARK: 第 1 步「唱一唱」鼓点节奏念词

    private func playChantSequence(words ws: [String], at idx: Int, token my: Int) {
        guard self.token == my else { return }
        guard idx < ws.count else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, self.token == my else { return }
                self.next()
            }
            return
        }
        chantIndex = idx
        let w = ws[idx]
        prompt("baby_chant_\(w)") { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard let self, self.token == my else { return }
                self.playChantSequence(words: ws, at: idx + 1, token: my)
            }
        }
    }

    func tapSingWord(_ w: String, index idx: Int) {
        guard !frozen else { return }
        token += 1
        let my = token
        chantIndex = idx
        prompt("baby_chant_\(w)") { [weak self] in
            guard let self, self.token == my else { return }
        }
    }

    // MARK: 复习日戳泡泡选游戏

    func pickBubbleGame(_ kind: BabyGameKind) {
        guard !frozen, case .pickGame = step else { return }
        var rng = SystemRandomNumberGenerator()
        let pool = BabyPlan.openPacks(data, known: sessionKnownWords.union(sessionFocusWords), unlockAll: sessionUnlockAll).flatMap(\.words)
        var gSteps = BabyPlan.gameSteps(kind: kind, newWords: sessionFocusWords, reviews: sessionFocusWords, pool: pool, data: data, using: &rng)
        if gSteps.isEmpty {
            gSteps = BabyPlan.gameSteps(kind: .listenChoice, newWords: sessionFocusWords, reviews: sessionFocusWords, pool: pool, data: data, using: &rng)
        }
        store.babyNoteTodaySession(words: Array(sessionFocusWords.prefix(4)), game: kind)
        var endIdx = index
        while endIdx + 1 < steps.count, steps[endIdx + 1].stage == .game {
            endIdx += 1
        }
        steps.replaceSubrange(index...endIdx, with: gSteps)
        enterStepBody(token: token)
    }

    // MARK: 听音选图 & 影子配对：选择答案

    func choose(_ option: String) {
        guard !frozen, phase != .solved else { return }
        let r: BabyRound
        switch step {
        case .review(let x), .game(let x), .shadowGame(let x): r = x
        default: return
        }
        let my = token
        if option == r.answer {
            phase = .solved
            praiseTick += 1
            tomMood = .clap
            if case .review = step, !replay { store.babyReviewed(r.answer, correct: firstTry) }
            sayWord(r.answer) { [weak self] in
                guard let self, self.token == my else { return }
                self.prompt(["prompt_great", "prompt_well", "prompt_yay"][self.praiseTick % 3]) { [weak self] in
                    guard let self, self.token == my else { return }
                    self.next()
                }
            }
        } else {
            firstTry = false
            wrong.insert(option)
            wrongTick += 1
            tomMood = .thinking
            sayWord(r.answer)
        }
    }

    // MARK: 翻翻乐 G1：翻牌配对

    func flipMemoryCard(at cardIndex: Int, cards: [String]) {
        guard !frozen, !memoryPeeking, cardIndex >= 0, cardIndex < cards.count else { return }
        let word = cards[cardIndex]
        guard !memoryMatched.contains(word), !memoryFlipped.contains(cardIndex), memoryFlipped.count < 2 else { return }

        memoryFlipped.append(cardIndex)
        sayWord(word)

        guard memoryFlipped.count == 2 else { return }
        let firstIdx = memoryFlipped[0]
        let secondIdx = memoryFlipped[1]
        let my = token

        if cards[firstIdx] == cards[secondIdx] {
            memoryMatched.insert(word)
            praiseTick += 1
            tomMood = .clap
            let allDone = memoryMatched.count * 2 >= cards.count
            if allDone { phase = .solved }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
                guard let self, self.token == my else { return }
                self.memoryFlipped = []
                if allDone {
                    self.prompt("prompt_yay") { [weak self] in
                        guard let self, self.token == my else { return }
                        self.next()
                    }
                }
            }
        } else {
            tomMood = .thinking
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
                guard let self, self.token == my else { return }
                self.memoryFlipped = []
                self.tomMood = .happy
            }
        }
    }

    // MARK: Tom 说你做 G5：完成动作

    func completeFollowMe() {
        guard !frozen, case .followMe(let w) = step, phase != .solved else { return }
        let my = token
        phase = .solved
        praiseTick += 1
        tomMood = .clap
        sayWord(w) { [weak self] in
            guard let self, self.token == my else { return }
            self.prompt(["prompt_great", "prompt_well", "prompt_yay"][self.praiseTick % 3]) { [weak self] in
                guard let self, self.token == my else { return }
                self.next()
            }
        }
    }

    // MARK: 押韵配对：两词对比发音与选择答案

    func playRhymeComparison(_ r: BabyRhymeRound, token my: Int) {
        activeSpeakingWord = r.word1
        sayWord(r.word1) { [weak self] in
            guard let self, self.token == my else { return }
            self.activeSpeakingWord = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard self.token == my else { return }
                self.activeSpeakingWord = r.word2
                self.sayWord(r.word2) { [weak self] in
                    guard let self, self.token == my else { return }
                    self.activeSpeakingWord = nil
                    self.phase = .inviting
                }
            }
        }
    }

    func chooseRhyme(_ childRhymeAnswer: Bool) {
        guard !frozen, case .rhymeGame(let r) = step, phase != .solved else { return }
        let my = token
        if childRhymeAnswer == r.rhymes {
            phase = .solved
            praiseTick += 1
            tomMood = .clap
            rhymeFeedback = true
            prompt(["prompt_great", "prompt_well", "prompt_yay"][praiseTick % 3]) { [weak self] in
                guard let self, self.token == my else { return }
                self.rhymeFeedback = nil
                self.next()
            }
        } else {
            tomMood = .thinking
            rhymeFeedback = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, self.token == my else { return }
                self.rhymeFeedback = nil
                self.playRhymeComparison(r, token: my)
            }
        }
    }

    // MARK: 拍手数音节：敲小鼓与选择音节数

    func tapSyllableDrum() {
        guard !frozen else { return }
        drumTaps = min(drumTaps + 1, 3)
        if let url = store.phraseFileURL("audio", "drum_beat.mp3") {
            drumPlayer.play(url: url)
        }
    }

    func chooseSyllable(_ count: Int) {
        guard !frozen, case .syllableGame(let r) = step, phase != .solved else { return }
        let my = token
        if count == r.count {
            phase = .solved
            praiseTick += 1
            tomMood = .clap
            syllableFeedback = count
            playDrumBeats(count: count, token: my) { [weak self] in
                guard let self, self.token == my else { return }
                self.prompt(["prompt_great", "prompt_well", "prompt_yay"][self.praiseTick % 3]) { [weak self] in
                    guard let self, self.token == my else { return }
                    self.syllableFeedback = nil
                    self.next()
                }
            }
        } else {
            tomMood = .thinking
            syllableFeedback = count
            playDrumBeats(count: r.count, token: my) { [weak self] in
                guard let self, self.token == my else { return }
                self.syllableFeedback = nil
                self.tomMood = .happy
            }
        }
    }

    private func playDrumBeats(count: Int, token my: Int, completion: (() -> Void)? = nil) {
        func beat(i: Int) {
            guard i < count else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { completion?() }
                return
            }
            drumTaps = i + 1
            if let url = store.phraseFileURL("audio", "drum_beat.mp3") {
                drumPlayer.play(url: url)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { beat(i: i + 1) }
        }
        beat(i: 0)
    }

    // MARK: 重播示范音

    func replayWord(rate: Float = 1.0) {
        guard !frozen else { return }
        switch step {
        case .sing(_, let songId, let ws):
            if let songId, let url = store.songAudioURL(songId) {
                audio.play(url)
            } else if chantIndex < ws.count {
                prompt("baby_chant_\(ws[chantIndex])")
            }
        case .review(let r), .game(let r), .shadowGame(let r):
            sayWord(r.answer, rate: rate)
        case .learn(let w), .sayIt(let w):
            sayWord(w, rate: rate)
        case .followMe(let w):
            prompt("baby_cmd_\(w)") { [weak self] in
                self?.sayWord(w, rate: rate)
            }
        case .rhymeGame(let r):
            playRhymeComparison(r, token: token)
        case .syllableGame(let r):
            sayWord(r.word, rate: rate)
        case .sentence(let w, _):
            prompt("baby_sent_\(w)")
        case .pickGame, .memoryGame, .done:
            break
        }
    }

    // MARK: 录音（学一学 / 句子 / 自己说）

    func tapMic() {
        guard !frozen else { return }
        if phase == .recording { recorder.finish(); return }

        switch step {
        case .learn(let w):
            recordAndPlayback(key: "\(store.currentProfileId)-baby-\(w)", afterModelWord: nil)
        case .sentence(let w, _):
            recordAndPlayback(key: "\(store.currentProfileId)-baby-sent-\(w)", afterModelWord: nil)
        case .sayIt(let w):
            recordAndPlayback(key: "\(store.currentProfileId)-baby-\(w)", afterModelWord: w)
        default:
            break
        }
    }

    private func recordAndPlayback(key: String, afterModelWord: String?) {
        words.stop()
        audio.stop()
        phase = .recording
        tomMood = .happy
        let my = token
        recorder.start(key: key) { [weak self] spoke in
            guard let self, self.token == my else { return }
            if let modelWord = afterModelWord {
                // 第 6 步「自己说」：孩子说完后，先放一遍标准示范音，再表扬
                self.sayWord(modelWord) { [weak self] in
                    guard let self, self.token == my else { return }
                    self.praiseTick += 1
                    self.phase = .praised
                    self.tomMood = .clap
                    self.prompt(["prompt_great", "prompt_well", "prompt_yay"][self.praiseTick % 3])
                }
            } else if spoke {
                self.phase = .playingBack
                self.recorder.playBack(key) { [weak self] in
                    guard let self, self.token == my else { return }
                    self.praiseTick += 1
                    self.phase = .praised
                    self.tomMood = .clap
                    self.prompt(["prompt_great", "prompt_well", "prompt_yay"][self.praiseTick % 3])
                }
            } else {
                // 没出声也不说错：「下一个」照样跳起来
                self.phase = .praised
                self.tomMood = .clap
            }
        }
    }

    private func revealSayItAnswer(word: String) {
        let my = token
        sayWord(word) { [weak self] in
            guard let self, self.token == my else { return }
            self.phase = .praised
            self.tomMood = .happy
        }
    }

    func next() {
        guard !frozen else { return }
        let prevStage = step.stage
        if case .learn(let w) = step, !replay { store.babyLearn(w) }
        guard index < steps.count - 1 else { return }
        index += 1
        enter(previousStage: prevStage)
    }

    func stopAll() {
        token += 1
        audio.stop()
        words.stop()
        drumPlayer.stop()
        recorder.cancel()
    }
}

// MARK: - 课内主视图（顶栏 6 圆点 + 小过场 + 6 步内容）

struct BabySessionView: View {
    let c: BabySessionController
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            topBar
            if c.showingIntro, let stage = c.step.stage {
                BabyStageIntroView(stage: stage, isBubblePick: isBubblePickStep) {
                    c.skipIntro()
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                stepContent
            }
        }
        .padding(.bottom, 8)
        .onDisappear { c.stopAll() }
    }

    private var isBubblePickStep: Bool {
        if case .pickGame = c.step { return true }
        return false
    }

    @ViewBuilder
    private var stepContent: some View {
        switch c.step {
        case .sing(_, let songId, let ws):
            BabySingView(c: c, words: ws, songId: songId).id(c.index)
        case .review(let r), .game(let r):
            BabyChoiceView(c: c, round: r).id(c.index)
        case .learn(let w):
            BabyLearnCard(c: c, word: w).id(c.index)
        case .pickGame(let choices):
            BabyBubblePickView(c: c, choices: choices).id(c.index)
        case .memoryGame(let cards):
            BabyMemoryFlipView(c: c, cards: cards).id(c.index)
        case .shadowGame(let r):
            BabyShadowDragView(c: c, round: r).id(c.index)
        case .followMe(let w):
            BabyFollowMeView(c: c, word: w).id(c.index)
        case .rhymeGame(let r):
            BabyRhymeMatchView(c: c, round: r).id(c.index)
        case .syllableGame(let r):
            BabySyllableClapView(c: c, round: r).id(c.index)
        case .sentence(let w, let text):
            BabySentenceCard(c: c, word: w, text: text).id(c.index)
        case .sayIt(let w):
            BabySayItCard(c: c, word: w).id(c.index)
        case .done:
            BabyDoneView(c: c, onClose: { c.stopAll(); onClose() })
        }
    }

    /// 顶栏：关闭按钮 + 6 个圆点阶段条（当前阶段高亮放大）+ 右侧阶段图标
    private var topBar: some View {
        let activeStage = c.step.stage
        return HStack(spacing: 12) {
            Button { c.stopAll(); onClose() } label: {
                Image(systemName: "xmark")
                    .kidFont(18, .black, maxScale: 1.1)
                    .foregroundStyle(Palette.inkMuted)
                    .frame(width: 44, height: 44)
                    .background(Palette.surface, in: Circle())
                    .overlay { Circle().strokeBorder(Palette.hairline, lineWidth: 1.5) }
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("回到首页")

            HStack(spacing: 8) {
                ForEach(BabyStage.allCases, id: \.rawValue) { stage in
                    let isDone = activeStage == nil || stage.rawValue < (activeStage?.rawValue ?? 99)
                    let isCurrent = activeStage == stage
                    ZStack {
                        if isCurrent {
                            Capsule()
                                .fill(stageTint(stage))
                                .frame(width: 36, height: 22)
                            Image(systemName: stage.icon)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        } else if isDone {
                            Circle()
                                .fill(Func.positiveDeep)
                                .frame(width: 18, height: 18)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.white)
                        } else {
                            Circle()
                                .fill(Palette.hairline)
                                .frame(width: 14, height: 14)
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: activeStage)
                }
            }
            .frame(maxWidth: .infinity)

            stageIcon
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private func stageTint(_ stage: BabyStage) -> Color {
        switch stage {
        case .sing: return Func.accent
        case .review: return Func.positiveDeep
        case .learn: return Func.accentDeep
        case .game: return Func.infoDeep
        case .sentence: return PhraseColors.gold
        case .sayIt: return Func.positiveDeep
        }
    }

    private var stageIcon: some View {
        let icon = c.step.stage?.icon ?? "star.fill"
        let tint = c.step.stage.map(stageTint) ?? PhraseColors.gold
        return Image(systemName: icon)
            .kidFont(20, .bold, maxScale: 1.1)
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(tint.opacity(0.14), in: Circle())
            .accessibilityHidden(true)
    }
}

// MARK: - 阶段切换小过场（Tom 跳一下 + 开场白）

private struct BabyStageIntroView: View {
    let stage: BabyStage
    let isBubblePick: Bool
    let onTap: () -> Void
    @State private var jump = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Func.accent.opacity(0.14))
                        .frame(width: 170, height: 170)
                    TomMoodView(mood: .clap, size: 128)
                        .offset(y: jump ? -12 : 0)
                }

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: stage.icon)
                            .kidFont(24, .bold)
                            .foregroundStyle(Func.accentDeep)
                        Text(stage.titleZh)
                            .kidFont(24, .heavy)
                            .foregroundStyle(Func.accentDeep)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Func.accent.opacity(0.14), in: Capsule())

                    Text(isBubblePick ? "Pick a bubble!" : stage.promptText)
                        .kidFont(32, .heavy)
                        .foregroundStyle(Palette.ink)
                }
                .padding(20)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .elevationRaised()

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            guard !LaunchOptions.isUIScreenshotRun else { return }
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) { jump = true }
        }
    }
}

// MARK: - 第 1 步：唱一唱（儿歌或 4 拍鼓点节奏念词）

private struct BabySingView: View {
    let c: BabySessionController
    let words: [String]
    let songId: String?
    @State private var beat = false

    var body: some View {
        GeometryReader { geo in
            let cardSide = min((geo.size.width - 56) / 2, (geo.size.height - 230) / 2)
            let activeWord = words.indices.contains(c.chantIndex) ? words[c.chantIndex] : words.first ?? ""
            VStack(spacing: 14) {
                Spacer(minLength: 0)

                // Tom + 音符气泡
                HStack(spacing: 12) {
                    TomMoodView(mood: .happy, size: 64)
                        .offset(y: beat ? -6 : 0)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "music.quarternote.3")
                                .kidFont(18, .bold)
                                .foregroundStyle(Func.accentDeep)
                            Text(songId != nil ? "跟着儿歌晃一晃" : "跟着鼓点拍手念")
                                .kidFont(15, .bold)
                                .foregroundStyle(Func.accentDeep)
                        }
                        Text(chantLine(for: activeWord))
                            .kidFont(20, .heavy)
                            .foregroundStyle(Palette.ink)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .elevationGround()
                .padding(.horizontal, 16)

                // 今天的 4 张词卡（2×2 网格，当前念到的那张高亮跳动）
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        ForEach(Array(words.prefix(2).enumerated()), id: \.offset) { i, w in
                            wordTile(w, index: i, side: cardSide)
                        }
                    }
                    if words.count > 2 {
                        HStack(spacing: 12) {
                            ForEach(Array(words.dropFirst(2).prefix(2).enumerated()), id: \.offset) { i, w in
                                wordTile(w, index: i + 2, side: cardSide)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 20) {
                    Button { c.replayWord() } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .kidFont(26, .bold, maxScale: 1.1)
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Func.infoDeep, in: Circle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("再听一遍")

                    PulsingNextButton(highlight: true, label: "下一步") {
                        c.next()
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            guard !LaunchOptions.isUIScreenshotRun else { return }
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { beat = true }
        }
    }

    private func chantLine(for word: String) -> String {
        guard !word.isEmpty else { return "Let's sing!" }
        let cap = word.prefix(1).uppercased() + word.dropFirst()
        let sent = c.sentence(for: word) ?? "\(cap)!"
        return "\(cap), \(word), \(word)! \(sent)"
    }

    private func wordTile(_ w: String, index idx: Int, side: CGFloat) -> some View {
        let isCurrent = songId == nil && c.chantIndex == idx
        return Button { c.tapSingWord(w, index: idx) } label: {
            VStack(spacing: 4) {
                BabyPicture(word: c.picture(w), size: side - 24)
                    .overlay {
                        RoundedRectangle(cornerRadius: (side - 24) * 0.16, style: .continuous)
                            .strokeBorder(isCurrent ? Func.accent : Color.white, lineWidth: isCurrent ? 6 : 4)
                    }
                Text(w)
                    .kidFont(17, .heavy)
                    .foregroundStyle(Palette.ink)
            }
            .padding(8)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .elevationRaised()
            .scaleEffect(isCurrent ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: c.chantIndex)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(w)
    }
}

// MARK: - 第 2 步 & 第 4 步（游戏 A）：听音选图

private struct BabyChoiceView: View {
    let c: BabySessionController
    let round: BabyRound

    var body: some View {
        GeometryReader { geo in
            let side = min((geo.size.width - 60) / 2, (geo.size.height - 175) / 2)
            VStack(spacing: 16) {
                Spacer(minLength: 0)
                HStack(spacing: 18) {
                    TomMoodView(mood: c.tomMood, size: 70)
                    Button { c.replayWord() } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .kidFont(44, .bold, maxScale: 1.0)
                            .foregroundStyle(.white)
                            .frame(width: 104, height: 104)
                            .background(Func.accentPill, in: Circle())
                            .overlay { Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 4).padding(4) }
                            .elevationRaised()
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("再听一遍")
                }

                let opts = round.options
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ForEach(opts.prefix(2), id: \.self) { o in option(o, side: side) }
                    }
                    if opts.count > 2 {
                        HStack(spacing: 16) {
                            ForEach(opts.dropFirst(2), id: \.self) { o in option(o, side: side) }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func option(_ o: String, side: CGFloat) -> some View {
        let isAnswer = o == round.answer
        let solved = c.phase == .solved && isAnswer
        let missed = c.wrong.contains(o)
        return Button { c.choose(o) } label: {
            BabyPicture(word: c.picture(o), size: side)
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(solved ? Func.positiveDeep : Color.white, lineWidth: solved ? 8 : 5)
                }
                .elevationRaised()
                .overlay { PraiseBurst(tick: c.praiseTick, show: solved) }
                .scaleEffect(solved ? 1.08 : (c.phase == .solved ? 0.92 : 1.0))
                .opacity(missed ? 0.45 : (c.phase == .solved && !isAnswer ? 0.5 : 1.0))
                .modifier(Shake(animatableData: CGFloat(missed ? c.wrongTick : 0)))
                .animation(.easeInOut(duration: 0.4), value: c.wrongTick)
                .animation(.spring(response: 0.35, dampingFraction: 0.55), value: c.phase)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("选项")
    }
}

/// 点错时轻轻左右晃一下（计数每加 1，sin 走两个来回）
private struct Shake: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(animatableData * .pi * 4), y: 0))
    }
}

// MARK: - 第 3 步：学新词（一词一卡，大图、喇叭、话筒、下一个）

private struct BabyLearnCard: View {
    let c: BabySessionController
    let word: String
    @State private var wiggle = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width - 48, geo.size.height * 0.54)
            VStack(spacing: 12) {
                Spacer(minLength: 0)
                Button { c.replayWord() } label: {
                    BabyPicture(word: c.picture(word), size: side)
                        .overlay {
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .strokeBorder(Color.white, lineWidth: 6)
                        }
                        .elevationRaised()
                        .overlay { PraiseBurst(tick: c.praiseTick, show: c.phase == .praised) }
                        .rotationEffect(.degrees(wiggle ? 2 : -2))
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("再听一遍")

                HStack(spacing: 10) {
                    TomMoodView(mood: c.tomMood, size: 48)
                    Text(word)
                        .kidFont(34, .heavy)
                        .foregroundStyle(Palette.ink)
                }

                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Button { c.replayWord() } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .kidFont(26, .bold, maxScale: 1.1)
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Func.infoDeep, in: Circle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("再听")
                    .frame(maxWidth: .infinity)

                    PhraseMicButton(phase: micPhase, level: c.recorder.level) { c.tapMic() }
                        .frame(maxWidth: .infinity)

                    PulsingNextButton(highlight: c.phase == .praised || c.phase == .inviting, label: "下一个") {
                        c.next()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            guard !LaunchOptions.isUIScreenshotRun else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { wiggle = true }
        }
    }

    private var micPhase: PhraseLessonController.Phase {
        switch c.phase {
        case .recording: return .recording
        case .inviting: return .inviting
        default: return .idle
        }
    }
}

// MARK: - 复习日：戳泡泡选游戏

private struct BabyBubblePickView: View {
    let c: BabySessionController
    let choices: [BabyGameKind]
    @State private var floatUp = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 18) {
                Spacer(minLength: 0)
                HStack(spacing: 12) {
                    TomMoodView(mood: .happy, size: 74)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("复习日！")
                            .kidFont(24, .heavy)
                            .foregroundStyle(Func.accentDeep)
                        Text("戳一个泡泡选今天玩的游戏")
                            .kidFont(16, .bold)
                            .foregroundStyle(Palette.inkMuted)
                    }
                }
                .padding(16)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .elevationGround()

                HStack(spacing: 16) {
                    ForEach(Array(choices.enumerated()), id: \.offset) { idx, kind in
                        bubbleButton(kind: kind, index: idx, size: min(112, (geo.size.width - 64) / 3))
                    }
                }
                .padding(.vertical, 12)

                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            guard !LaunchOptions.isUIScreenshotRun else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { floatUp = true }
        }
    }

    private func bubbleButton(kind: BabyGameKind, index idx: Int, size: CGFloat) -> some View {
        let meta = bubbleMeta(for: kind)
        return Button { c.pickBubbleGame(kind) } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.85), meta.tint.opacity(0.35), meta.tint.opacity(0.75)],
                                center: .topLeading,
                                startRadius: 6,
                                endRadius: size
                            )
                        )
                    Circle()
                        .strokeBorder(Color.white.opacity(0.9), lineWidth: 4)
                    // 泡泡高光
                    Circle()
                        .fill(Color.white.opacity(0.75))
                        .frame(width: size * 0.2, height: size * 0.2)
                        .offset(x: -size * 0.22, y: -size * 0.22)
                    Image(systemName: meta.icon)
                        .font(.system(size: size * 0.38, weight: .black))
                        .foregroundStyle(meta.tint)
                }
                .frame(width: size, height: size)
                .shadow(color: meta.tint.opacity(0.32), radius: 10, y: 5)
                .offset(y: floatUp ? (idx.isMultiple(of: 2) ? -8 : 8) : 0)

                Text(meta.title)
                    .kidFont(17, .heavy)
                    .foregroundStyle(Palette.ink)
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(meta.title)
    }

    private func bubbleMeta(for kind: BabyGameKind) -> (title: String, icon: String, tint: Color) {
        switch kind {
        case .listenChoice: return (kind.titleZh, "speaker.wave.2.fill", Func.positiveDeep)
        case .memoryFlip: return (kind.titleZh, "square.grid.2x2.fill", Func.accent)
        case .shadowDrag: return (kind.titleZh, "circle.lefthalf.filled", Func.infoDeep)
        case .followMe: return (kind.titleZh, "figure.dance", PhraseColors.gold)
        case .rhymeMatch: return (kind.titleZh, "music.note.list", Func.accentDeep)
        case .syllableClap: return (kind.titleZh, "hands.clap.fill", PhraseColors.gold)
        case .feedAnimal: return (kind.titleZh, "carrot.fill", Func.accentDeep)
        case .findInScene: return (kind.titleZh, "magnifyingglass.circle.fill", Func.infoDeep)
        }
    }
}

// MARK: - 第 4 步（游戏 B）：翻翻乐 G1（6 张卡 = 3 对图，无文字）

private struct BabyMemoryFlipView: View {
    let c: BabySessionController
    let cards: [String]

    var body: some View {
        GeometryReader { geo in
            let cols = 3
            let spacing: CGFloat = 14
            let cardSide = min((geo.size.width - 48 - spacing * 2) / CGFloat(cols), (geo.size.height - 170) / 2)
            VStack(spacing: 16) {
                Spacer(minLength: 0)
                HStack(spacing: 12) {
                    TomMoodView(mood: c.tomMood, size: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("翻翻乐")
                            .kidFont(22, .heavy)
                            .foregroundStyle(Palette.ink)
                        Text("翻开两张一样的图配成一对")
                            .kidFont(15, .semibold)
                            .foregroundStyle(Palette.inkMuted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)

                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        ForEach(0..<min(3, cards.count), id: \.self) { i in
                            cardTile(index: i, side: cardSide)
                        }
                    }
                    if cards.count > 3 {
                        HStack(spacing: spacing) {
                            ForEach(3..<min(6, cards.count), id: \.self) { i in
                                cardTile(index: i, side: cardSide)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func cardTile(index i: Int, side: CGFloat) -> some View {
        let word = cards[i]
        let isMatched = c.memoryMatched.contains(word)
        let isFaceUp = c.memoryPeeking || isMatched || c.memoryFlipped.contains(i)
        return Button { c.flipMemoryCard(at: i, cards: cards) } label: {
            ZStack {
                if isFaceUp {
                    BabyPicture(word: c.picture(word), size: side)
                        .overlay {
                            RoundedRectangle(cornerRadius: side * 0.16, style: .continuous)
                                .strokeBorder(isMatched ? Func.positiveDeep : Func.accent, lineWidth: isMatched ? 6 : 4)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            if isMatched {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(Func.positiveDeep)
                                    .background(Color.white, in: Circle())
                                    .padding(6)
                            }
                        }
                        .overlay {
                            PraiseBurst(tick: c.praiseTick, show: isMatched)
                                .scaleEffect(0.42)
                                .allowsHitTesting(false)
                        }
                } else {
                    RoundedRectangle(cornerRadius: side * 0.16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Func.info, Func.infoDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: side, height: side)
                        .overlay {
                            RoundedRectangle(cornerRadius: side * 0.16, style: .continuous)
                                .strokeBorder(Color.white, lineWidth: 5)
                        }
                        .overlay {
                            Image(systemName: "star.fill")
                                .font(.system(size: side * 0.36, weight: .bold))
                                .foregroundStyle(PhraseColors.gold)
                        }
                }
            }
            .elevationRaised()
            .scaleEffect(isMatched ? 1.04 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isFaceUp)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isMatched)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(isFaceUp ? word : "盖着的卡片")
    }
}

// MARK: - 第 4 步（游戏 C）：影子配对 G2（上方剪影 + 下方 3 张可拖/可点词图）

private struct BabyShadowDragView: View {
    let c: BabySessionController
    let round: BabyRound
    @State private var draggedOption: String?
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let targetSide = min(geo.size.width * 0.44, geo.size.height * 0.38)
            let optionSide = min((geo.size.width - 64) / 3, geo.size.height * 0.25)
            let solved = c.phase == .solved
            VStack(spacing: 18) {
                Spacer(minLength: 0)

                // 上方：Tom + 影子框 + 喇叭
                HStack(spacing: 16) {
                    TomMoodView(mood: c.tomMood, size: 64)

                    ZStack {
                        RoundedRectangle(cornerRadius: targetSide * 0.18, style: .continuous)
                            .fill(PhraseColors.paper)
                            .frame(width: targetSide, height: targetSide)
                            .overlay {
                                RoundedRectangle(cornerRadius: targetSide * 0.18, style: .continuous)
                                    .strokeBorder(solved ? Func.positiveDeep : Palette.inkSubtle,
                                                  style: StrokeStyle(lineWidth: solved ? 6 : 3, dash: solved ? [] : [8, 6]))
                            }

                        if solved {
                            BabyPicture(word: c.picture(round.answer), size: targetSide - 12)
                                .overlay { PraiseBurst(tick: c.praiseTick, show: true) }
                                .transition(.scale)
                        } else {
                            BabySilhouetteView(word: c.picture(round.answer), size: targetSide - 20)
                        }
                    }
                    .elevationRaised()

                    Button { c.replayWord() } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .kidFont(26, .bold, maxScale: 1.1)
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Func.accentPill, in: Circle())
                            .elevationRaised()
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("再听一遍")
                }

                Text("把对应的图拖到影子上")
                    .kidFont(16, .bold)
                    .foregroundStyle(Palette.inkMuted)

                // 下方：3 张候选图（既支持拖放，也支持直接点选，照顾 4 岁小手）
                HStack(spacing: 14) {
                    ForEach(round.options, id: \.self) { opt in
                        optionCard(opt, side: optionSide)
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func optionCard(_ opt: String, side: CGFloat) -> some View {
        let isDragging = draggedOption == opt
        let missed = c.wrong.contains(opt)
        let solved = c.phase == .solved && opt == round.answer
        return BabyPicture(word: c.picture(opt), size: side)
            .overlay {
                RoundedRectangle(cornerRadius: side * 0.16, style: .continuous)
                    .strokeBorder(solved ? Func.positiveDeep : Color.white, lineWidth: solved ? 6 : 4)
            }
            .elevationRaised()
            .opacity(solved ? 0.35 : (missed ? 0.45 : 1.0))
            .offset(isDragging ? dragOffset : .zero)
            .scaleEffect(isDragging ? 1.12 : 1.0)
            .zIndex(isDragging ? 10 : 0)
            .modifier(Shake(animatableData: CGFloat(missed ? c.wrongTick : 0)))
            .animation(.easeInOut(duration: 0.4), value: c.wrongTick)
            .onTapGesture {
                c.choose(opt)
            }
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        if draggedOption != opt {
                            draggedOption = opt
                            c.sayWord(opt)
                        }
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let movedUpEnough = value.translation.height < -50
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                            draggedOption = nil
                            dragOffset = .zero
                        }
                        if movedUpEnough {
                            c.choose(opt)
                        }
                    }
            )
            .accessibilityLabel(opt)
    }
}

/// 生成并缓存单词图的剪影：优先用透明底 PNG，否则从平涂图标四角泛洪抠掉浅色纸底、把主体染成深棕剪影
private enum BabySilhouetteCache {
    private static var cache: [String: UIImage] = [:]

    static func image(for word: String, store: DataStore) -> UIImage? {
        if let hit = cache[word] { return hit }
        for folder in ["items", "feed"] {
            if let url = Bundle.main.url(forResource: word, withExtension: "png", subdirectory: "scenes/\(folder)"),
               let img = UIImage(contentsOfFile: url.path) {
                cache[word] = img
                return img
            }
        }
        guard let url = store.iconURL(forWord: word),
              let src = UIImage(contentsOfFile: url.path),
              let cut = makeCornerFloodFillSilhouette(from: src) else { return nil }
        cache[word] = cut
        return cut
    }

    private static func makeCornerFloodFillSilhouette(from image: UIImage) -> UIImage? {
        let dim = 128
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixels = [UInt8](repeating: 0, count: dim * dim * 4)
        guard let ctx = CGContext(
            data: &pixels,
            width: dim,
            height: dim,
            bitsPerComponent: 8,
            bytesPerRow: dim * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let cg = image.cgImage else { return nil }

        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: dim, height: dim))

        // 取四个角的平均背景色（暖白/米白纸底）
        let corners = [(2, 2), (dim - 3, 2), (2, dim - 3), (dim - 3, dim - 3)]
        var bgR = 0, bgG = 0, bgB = 0
        for (cx, cy) in corners {
            let idx = (cy * dim + cx) * 4
            bgR += Int(pixels[idx])
            bgG += Int(pixels[idx + 1])
            bgB += Int(pixels[idx + 2])
        }
        bgR /= corners.count
        bgG /= corners.count
        bgB /= corners.count

        let thresholdSq = 42 * 42 * 3
        func isBackground(_ x: Int, _ y: Int) -> Bool {
            let idx = (y * dim + x) * 4
            let dr = Int(pixels[idx]) - bgR
            let dg = Int(pixels[idx + 1]) - bgG
            let db = Int(pixels[idx + 2]) - bgB
            return (dr * dr + dg * dg + db * db) <= thresholdSq
        }

        // 从四条边往里 BFS 泛洪标记背景
        var visited = [Bool](repeating: false, count: dim * dim)
        var queue: [Int] = []
        queue.reserveCapacity(dim * dim / 2)

        for x in 0..<dim {
            for y in [0, dim - 1] {
                let p = y * dim + x
                if !visited[p] && isBackground(x, y) {
                    visited[p] = true
                    queue.append(p)
                }
            }
        }
        for y in 0..<dim {
            for x in [0, dim - 1] {
                let p = y * dim + x
                if !visited[p] && isBackground(x, y) {
                    visited[p] = true
                    queue.append(p)
                }
            }
        }

        var head = 0
        while head < queue.count {
            let p = queue[head]
            head += 1
            let x = p % dim
            let y = p / dim
            let neighbors = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
            for (nx, ny) in neighbors where nx >= 0 && nx < dim && ny >= 0 && ny < dim {
                let np = ny * dim + nx
                if !visited[np] && isBackground(nx, ny) {
                    visited[np] = true
                    queue.append(np)
                }
            }
        }

        // 把非背景像素染成深棕色剪影 (#3D2B1F -> 61, 43, 31)
        for p in 0..<(dim * dim) {
            let idx = p * 4
            if visited[p] {
                pixels[idx] = 0
                pixels[idx + 1] = 0
                pixels[idx + 2] = 0
                pixels[idx + 3] = 0
            } else {
                pixels[idx] = 61
                pixels[idx + 1] = 43
                pixels[idx + 2] = 31
                pixels[idx + 3] = 255
            }
        }

        guard let outCG = ctx.makeImage() else { return nil }
        return UIImage(cgImage: outCG)
    }
}

private struct BabySilhouetteView: View {
    @Environment(DataStore.self) private var store
    let word: String
    let size: CGFloat

    var body: some View {
        let w = store.babyData?.picture(for: word) ?? word
        Group {
            if let ui = BabySilhouetteCache.image(for: w, store: store) {
                Image(uiImage: ui)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(PhraseColors.outline)
                    .padding(size * 0.08)
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(PhraseColors.outline)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - 第 4 步（游戏 D）：Tom 说你做 G5（身体 + 动作 TPR）

private struct BabyFollowMeView: View {
    let c: BabySessionController
    let word: String
    @State private var bounce = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width - 56, geo.size.height * 0.48)
            let cmd = BabyPlan.followMeCommands[word] ?? "Show me \(word)!"
            let solved = c.phase == .solved
            VStack(spacing: 14) {
                Spacer(minLength: 0)

                HStack(spacing: 12) {
                    TomMoodView(mood: c.tomMood, size: 68)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tom 说你做！")
                            .kidFont(16, .bold)
                            .foregroundStyle(Func.accentDeep)
                        Text(cmd)
                            .kidFont(24, .heavy)
                            .foregroundStyle(Palette.ink)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .elevationGround()
                .padding(.horizontal, 16)

                Button { c.replayWord() } label: {
                    BabyPicture(word: c.picture(word), size: side)
                        .overlay {
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .strokeBorder(solved ? Func.positiveDeep : Color.white, lineWidth: solved ? 8 : 6)
                        }
                        .elevationRaised()
                        .overlay { PraiseBurst(tick: c.praiseTick, show: solved) }
                        .offset(y: bounce ? -8 : 0)
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(cmd)

                Spacer(minLength: 0)

                HStack(spacing: 24) {
                    Button { c.replayWord() } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .kidFont(26, .bold, maxScale: 1.1)
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Func.infoDeep, in: Circle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("再听一遍")

                    Button { c.completeFollowMe() } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .kidFont(32, .bold)
                            Text("我做到了！")
                                .kidFont(22, .heavy)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .frame(height: 68)
                        .background(Func.positiveDeep, in: Capsule())
                        .elevationRaised()
                        .scaleEffect(bounce ? 1.05 : 1.0)
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("我做到了")
                }
                .padding(.horizontal, 20)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onAppear {
            guard !LaunchOptions.isUIScreenshotRun else { return }
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { bounce = true }
        }
    }
}

// MARK: - 第 4 步（小游戏 E）：押韵配对（听两词判断是否押韵）

private struct BabyRhymeMatchView: View {
    let c: BabySessionController
    let round: BabyRhymeRound

    var body: some View {
        GeometryReader { geo in
            let cardSide = min((geo.size.width - 56) / 2, geo.size.height * 0.38)
            VStack(spacing: 14) {
                Spacer(minLength: 0)

                // 顶部 Tom 提示栏
                HStack(spacing: 12) {
                    TomMoodView(mood: c.tomMood, size: 68)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("押韵配对")
                            .kidFont(16, .bold)
                            .foregroundStyle(Func.accentDeep)
                        Text("听一听，尾音一样吗？")
                            .kidFont(22, .heavy)
                            .foregroundStyle(Palette.ink)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .elevationGround()
                .padding(.horizontal, 16)

                // 中间两张词卡并排
                HStack(spacing: 16) {
                    rhymeCard(word: round.word1, side: cardSide)
                    rhymeCard(word: round.word2, side: cardSide)
                }
                .padding(.horizontal, 12)

                Spacer(minLength: 0)

                // 底部操作区：再听一遍 + 押韵 (一样) / 不押韵 (不同)
                HStack(spacing: 16) {
                    Button { c.replayWord() } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .kidFont(24, .bold, maxScale: 1.1)
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 58)
                            .background(Func.infoDeep, in: Circle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("再听一遍")

                    // 押韵（一样）
                    Button { c.chooseRhyme(true) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .kidFont(26, .bold)
                            Text("一样 (押韵)")
                                .kidFont(18, .heavy)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Func.positiveDeep, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .elevationRaised()
                        .scaleEffect(c.rhymeFeedback == true ? 1.05 : 1.0)
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("一样押韵")

                    // 不押韵（不同）
                    Button { c.chooseRhyme(false) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                                .kidFont(24, .bold)
                            Text("不一样")
                                .kidFont(18, .heavy)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Func.accentDeep, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .elevationRaised()
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("不一样")
                }
                .padding(.horizontal, 16)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func rhymeCard(word: String, side: CGFloat) -> some View {
        let isSpeaking = c.activeSpeakingWord == word
        let solved = c.phase == .solved
        return Button { c.sayWord(word) } label: {
            VStack(spacing: 6) {
                BabyPicture(word: c.picture(word), size: side - 16)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(isSpeaking ? Func.accent : (solved ? Func.positiveDeep : Color.white),
                                          lineWidth: isSpeaking ? 6 : (solved ? 5 : 4))
                    }
                    .scaleEffect(isSpeaking ? 1.04 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSpeaking)
                Text(word)
                    .kidFont(18, .heavy)
                    .foregroundStyle(Palette.ink)
            }
            .padding(8)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .elevationRaised()
            .overlay { PraiseBurst(tick: c.praiseTick, show: solved) }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(word)
    }
}

// MARK: - 第 4 步（小游戏 F）：拍手数音节（1/2/3 音节感知）

private struct BabySyllableClapView: View {
    let c: BabySessionController
    let round: BabySyllableRound
    @State private var drumBounce = false

    var body: some View {
        GeometryReader { geo in
            let picSide = min(geo.size.width - 96, geo.size.height * 0.34)
            let solved = c.phase == .solved
            VStack(spacing: 12) {
                Spacer(minLength: 0)

                // 顶部 Tom 提示栏
                HStack(spacing: 12) {
                    TomMoodView(mood: c.tomMood, size: 68)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("拍手数音节")
                            .kidFont(16, .bold)
                            .foregroundStyle(PhraseColors.gold)
                        Text("听单词，拍几下？")
                            .kidFont(22, .heavy)
                            .foregroundStyle(Palette.ink)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .elevationGround()
                .padding(.horizontal, 16)

                // 居中大图
                Button { c.replayWord() } label: {
                    VStack(spacing: 4) {
                        BabyPicture(word: c.picture(round.word), size: picSide)
                            .overlay {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .strokeBorder(solved ? Func.positiveDeep : Color.white, lineWidth: solved ? 6 : 4)
                            }
                        Text(round.word)
                            .kidFont(20, .heavy)
                            .foregroundStyle(Palette.ink)
                    }
                    .padding(8)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .elevationRaised()
                    .overlay { PraiseBurst(tick: c.praiseTick, show: solved) }
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(round.word)

                // 中间可交互拍手小木鼓
                Button {
                    c.tapSyllableDrum()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) { drumBounce = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { drumBounce = false }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "hands.clap.fill")
                            .kidFont(28, .bold)
                            .foregroundStyle(PhraseColors.gold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("敲小鼓拍一拍")
                                .kidFont(16, .heavy)
                                .foregroundStyle(Palette.ink)
                            HStack(spacing: 6) {
                                ForEach(1...3, id: \.self) { dot in
                                    Circle()
                                        .fill(dot <= c.drumTaps ? PhraseColors.gold : Palette.hairline)
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Palette.surface, in: Capsule())
                    .overlay { Capsule().strokeBorder(PhraseColors.gold.opacity(0.6), lineWidth: 2) }
                    .scaleEffect(drumBounce ? 1.15 : 1.0)
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("敲小鼓")

                Spacer(minLength: 0)

                // 底部 1、2、3 音节选项按钮
                HStack(spacing: 14) {
                    syllableButton(count: 1, dots: "●", label: "1 拍")
                    syllableButton(count: 2, dots: "● ●", label: "2 拍")
                    syllableButton(count: 3, dots: "● ● ●", label: "3 拍")
                }
                .padding(.horizontal, 16)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func syllableButton(count: Int, dots: String, label: String) -> some View {
        let isAnswer = count == round.count
        let isChosen = c.syllableFeedback == count
        let solved = c.phase == .solved && isAnswer
        return Button { c.chooseSyllable(count) } label: {
            VStack(spacing: 4) {
                Text("\(count)")
                    .kidFont(26, .heavy)
                Text(dots)
                    .kidFont(13, .bold)
                Text(label)
                    .kidFont(12, .heavy)
            }
            .foregroundStyle(solved ? .white : Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(solved ? Func.positiveDeep : (isChosen ? PhraseColors.gold : Palette.surface),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(solved ? Color.white : Palette.hairline, lineWidth: solved ? 3 : 1.5)
            }
            .elevationRaised()
            .scaleEffect(solved ? 1.06 : 1.0)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("\(count) 拍")
    }
}

// MARK: - 第 5 步：句子（今天这包的 1 个句型套 2 个新词，跟读）

private struct BabySentenceCard: View {
    let c: BabySessionController
    let word: String
    let text: String

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width - 56, geo.size.height * 0.46)
            VStack(spacing: 14) {
                Spacer(minLength: 0)

                HStack(spacing: 12) {
                    TomMoodView(mood: c.tomMood, size: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("跟着 Tom 说句子")
                            .kidFont(14, .bold)
                            .foregroundStyle(Func.accentDeep)
                        Text(text)
                            .kidFont(26, .heavy)
                            .foregroundStyle(Palette.ink)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .elevationGround()
                .padding(.horizontal, 16)

                Button { c.replayWord() } label: {
                    BabyPicture(word: c.picture(word), size: side)
                        .overlay {
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .strokeBorder(Color.white, lineWidth: 6)
                        }
                        .elevationRaised()
                        .overlay { PraiseBurst(tick: c.praiseTick, show: c.phase == .praised) }
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(text)

                Spacer(minLength: 0)

                HStack(spacing: 0) {
                    Button { c.replayWord() } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .kidFont(26, .bold, maxScale: 1.1)
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Func.infoDeep, in: Circle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("再听句子")
                    .frame(maxWidth: .infinity)

                    PhraseMicButton(phase: micPhase, level: c.recorder.level) { c.tapMic() }
                        .frame(maxWidth: .infinity)

                    PulsingNextButton(highlight: c.phase == .praised || c.phase == .inviting, label: "下一个") {
                        c.next()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var micPhase: PhraseLessonController.Phase {
        switch c.phase {
        case .recording: return .recording
        case .inviting: return .inviting
        default: return .idle
        }
    }
}

// MARK: - 第 6 步：自己说（看图不先放音，孩子先开口，再放示范音）

private struct BabySayItCard: View {
    let c: BabySessionController
    let word: String

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width - 52, geo.size.height * 0.5)
            VStack(spacing: 14) {
                Spacer(minLength: 0)

                HStack(spacing: 12) {
                    TomMoodView(mood: c.tomMood, size: 60)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("轮到你先说！")
                            .kidFont(20, .heavy)
                            .foregroundStyle(Palette.ink)
                        Text(c.phase == .praised ? word : "看图大声说出来")
                            .kidFont(16, .bold)
                            .foregroundStyle(c.phase == .praised ? Func.positiveDeep : Palette.inkMuted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .elevationGround()
                .padding(.horizontal, 16)

                Button { c.replayWord() } label: {
                    BabyPicture(word: c.picture(word), size: side)
                        .overlay {
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .strokeBorder(c.phase == .praised ? Func.positiveDeep : Color.white,
                                              lineWidth: c.phase == .praised ? 8 : 6)
                        }
                        .elevationRaised()
                        .overlay { PraiseBurst(tick: c.praiseTick, show: c.phase == .praised) }
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("听示范音")

                Spacer(minLength: 0)

                HStack(spacing: 0) {
                    Button { c.replayWord() } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .kidFont(26, .bold, maxScale: 1.1)
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Func.infoDeep, in: Circle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("听答案")
                    .frame(maxWidth: .infinity)

                    PhraseMicButton(phase: micPhase, level: c.recorder.level) { c.tapMic() }
                        .frame(maxWidth: .infinity)

                    PulsingNextButton(highlight: c.phase == .praised, label: "下一个") {
                        c.next()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var micPhase: PhraseLessonController.Phase {
        switch c.phase {
        case .recording: return .recording
        case .inviting: return .inviting
        default: return .idle
        }
    }
}

// MARK: - 第 7 步：完成（今天的贴纸 + Tom 拍手）

private struct BabyDoneView: View {
    let c: BabySessionController
    let onClose: () -> Void
    @State private var pop = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            TomMoodView(mood: .clap, size: 84)
            ZStack {
                Image(systemName: "seal.fill")
                    .kidFont(220, .bold, maxScale: 1.0)
                    .foregroundStyle(PhraseColors.gold)
                    .shadow(color: PhraseColors.gold.opacity(0.4), radius: 18)
                if let s = c.sticker {
                    BabyPicture(word: c.picture(s), size: 136)
                        .clipShape(Circle())
                        .overlay { Circle().strokeBorder(Color.white, lineWidth: 6) }
                }
            }
            .scaleEffect(pop ? 1 : 0.5)
            .rotationEffect(.degrees(pop ? 0 : -20))
            .onAppear {
                if LaunchOptions.isUIScreenshotRun { pop = true; return }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.5)) { pop = true }
            }
            Text("You did it!")
                .kidFont(34, .heavy)
                .foregroundStyle(Palette.ink)
            Text(c.replay ? "又玩了一遍，真棒！" : (c.firstCompletion ? "今天的贴纸贴好啦" : "今天已经得过贴纸啦"))
                .kidFont(17, .semibold)
                .foregroundStyle(Palette.inkMuted)
            Spacer()
            AppButton(title: "回到首页", icon: "house.fill", action: onClose)
                .frame(maxWidth: 360)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - 图画（自由点着听）

struct BabyPicturesView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if let id = LaunchOptions.babyPack, let pack = store.babyData?.packs.first(where: { $0.id == id }) {
                    BabyPackView(pack: pack)
                } else {
                    packList
                }
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var known: Set<String> {
        if let d = store.babyData, let s = BabyDemo.states(d) { return Set(s.keys) }
        return store.babyKnown
    }

    private var packList: some View {
        let data = store.babyData
        let open = data.map { BabyPlan.openPacks($0, known: known, unlockAll: store.babyUnlockAll) } ?? []
        return KidScrollView {
            Text("图画")
                .pageTitleStyle()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 8)

            NavigationLink { PhonicsIslandView() } label: {
                PhonicsIslandBanner()
            }
            .buttonStyle(PressableStyle())

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(data?.packs ?? []) { pack in
                    let unlocked = open.contains(pack)
                    NavigationLink { BabyPackView(pack: pack) } label: {
                        packTile(pack, unlocked: unlocked)
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(!unlocked)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    private func packTile(_ pack: BabyPack, unlocked: Bool) -> some View {
        let learned = pack.words.filter(known.contains).count
        return VStack(spacing: 6) {
            GeometryReader { geo in
                if let first = pack.words.first {
                    BabyPicture(word: store.babyData?.picture(for: first) ?? first, size: geo.size.width)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if !unlocked {
                    ZStack {
                        RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Color.white.opacity(0.6))
                        Image(systemName: "lock.fill").kidFont(30, .bold).foregroundStyle(Palette.inkSubtle)
                    }
                }
            }
            Text(pack.nameZh)
                .kidFont(17, .heavy)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
            HStack(spacing: 3) {
                ForEach(0..<min(pack.words.count, 10), id: \.self) { i in
                    Image(systemName: i < learned ? "star.fill" : "star")
                        .kidFont(11, .bold, maxScale: 1.0)
                        .foregroundStyle(i < learned ? PhraseColors.gold : Palette.inkSubtle)
                }
            }
        }
        .padding(10)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .elevationGround()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pack.nameZh)，\(unlocked ? "可以看" : "还没解锁")")
    }
}

/// 一个词包里的所有图：点一下就念出来，图会跳一下
struct BabyPackView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let pack: BabyPack
    @State private var player = AudioPlayer()
    @State private var tapped: String?
    @State private var tapTick = 0

    var body: some View {
        KidScrollView {
            HStack {
                SubPageHeader(onBack: { player.stop(); dismiss() })
                Spacer(minLength: 0)
                if let song = pack.songId, let url = store.songAudioURL(song) {
                    Button { player.play(url: url) } label: {
                        Image(systemName: "music.note")
                            .kidFont(22, .bold, maxScale: 1.1)
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(Func.accentPill, in: Circle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("听儿歌")
                    .padding(.trailing)
                }
            }
            Text(pack.nameZh)
                .subPageTitleStyle()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 10)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(pack.words, id: \.self) { w in
                    Button {
                        tapped = w
                        tapTick += 1
                        player.playWord(w, url: store.audioURL(forWord: w))
                    } label: {
                        VStack(spacing: 4) {
                            GeometryReader { geo in
                                BabyPicture(word: store.babyData?.picture(for: w) ?? w, size: geo.size.width)
                            }
                            .aspectRatio(1, contentMode: .fit)
                            Text(w)
                                .kidFont(18, .heavy)
                                .foregroundStyle(Palette.ink)
                        }
                        .padding(8)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                        .elevationGround()
                        .scaleEffect(tapped == w ? 1.06 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.45), value: tapTick)
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel(w)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .creamBackground()
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { player.stop() }
    }
}

/// 宝宝模式的词图：圆角大方块。
/// 自己再做一次「词 → 配图词」映射（幂等）：资源包里同名的 mom / dad / grandma 是旧 3D 图，
/// 调用方漏映射也只会拿到平涂的 mother / father / grandmother。
struct BabyPicture: View {
    @Environment(DataStore.self) private var store
    let word: String
    let size: CGFloat

    var body: some View {
        let w = store.babyData?.picture(for: word) ?? word
        Group {
            if let url = store.iconURL(forWord: w), let ui = UIImage(contentsOfFile: url.path) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                PhraseColors.paper
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.16, style: .continuous))
        .accessibilityHidden(true)
    }
}

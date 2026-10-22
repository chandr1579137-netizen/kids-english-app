import SwiftUI
import UIKit

// MARK: - 宝宝模式（4 岁）
//
// 孩子看到五个页签：今天 / 图画 / 说一说 / 儿歌 / 家长。不识字也能自己玩：
// 页面上只有大图、喇叭和会跳的按钮，所有提示都靠声音。
// 「今天」一次约 5–7 分钟：复习到期的旧词（听音选图）→ 学 3 个新词（一词一卡，可跟读）→
// 听音选图小游戏 5 题 → 得今天的贴纸。词包、复习间隔和出题规则在 BabyPath.swift，
// 设计依据见 docs/pm/baby-mode-v1.md。其余内容（背单词、单词卡等）在家长门后面。

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

    /// `-uiBabyDemo correct|wrong|recording|praised` 停在某个状态
    static var babyDemo: String? { value(for: "-uiBabyDemo") }

    /// `-uiBabyKnown N` 截图时假装前 N 个词已经学过、今天都到期（让复习步骤出现）
    static var babyKnown: Int { value(for: "-uiBabyKnown").flatMap { Int($0) } ?? 0 }

    /// `-uiBabyPack <id>` 图画页直接打开某个词包
    static var babyPack: String? { value(for: "-uiBabyPack") }

    /// `-uiBabyDoneToday` 截图时假装今天已经完成（首页显示贴纸和「再玩一次」）
    static var babyDoneToday: Bool { ProcessInfo.processInfo.arguments.contains("-uiBabyDoneToday") }

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
        VStack(spacing: 0) {
            Group {
                switch tab {
                case .today: BabyTodayView()
                case .pictures: BabyPicturesView()
                case .talk: PhrasesHomeView()
                case .songs: SongsView(asTabRoot: true)
                case .parent: NavigationStack { ParentGateView() }
                }
            }
            .frame(maxWidth: KidLayout.readableWidth)
            KidTabBar(selection: $tab)
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
        .onAppear {
            if LaunchOptions.babyStep != nil, controller == nil { start(replay: false) }
        }
    }

    private var home: some View {
        GeometryReader { geo in
            VStack(spacing: 18) {
                Spacer(minLength: 0)
                // Tom 和今天要学的三张图
                HStack(alignment: .center, spacing: 14) {
                    PhraseAvatarView(speaker: "tom", size: 110, active: false)
                        .offset(y: bounce ? -10 : 0)
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            if doneToday, let w = todaySticker {
                                BabyPicture(word: pic(w), size: 76)
                                Image(systemName: "checkmark.circle.fill")
                                    .kidFont(34, .bold, maxScale: 1.1)
                                    .foregroundStyle(Func.positiveDeep)
                            } else {
                                ForEach(preview, id: \.self) { w in BabyPicture(word: pic(w), size: 70) }
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

                Text(doneToday ? "今天完成啦！再玩一次？" : "今天学 \(preview.count) 个新词")
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

    /// 词 → 配图用的词（mom 用平涂的 mother 图）。资源包里同名的 mom / dad 是旧 3D 图，不能直接用
    private func pic(_ w: String) -> String { store.babyData?.picture(for: w) ?? w }

    private var todaySticker: String? {
        if LaunchOptions.babyDoneToday { return preview.first ?? store.babyData?.allWords.first }
        return store.babyStickers[store.todayKeyString]
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
                let w = isToday ? (doneToday ? todaySticker : nil) : store.babyStickers[day]
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

// MARK: - 一次「今天」的流程

@Observable
final class BabySessionController {
    enum Phase: Equatable {
        case idle, listening, inviting, recording, playingBack, praised, solved
    }

    let steps: [BabyStep]
    let frozen: Bool
    let replay: Bool
    private let data: BabyPathData
    private let store: DataStore
    private let words = AudioPlayer()
    let audio = PhraseAudio()
    let recorder = PhraseVoiceRecorder()

    private(set) var index = 0
    private(set) var phase: Phase = .idle
    private(set) var wrong: Set<String> = []
    private(set) var wrongTick = 0
    private(set) var praiseTick = 0
    private(set) var firstTry = true
    private(set) var firstCompletion = false
    let sticker: String?
    private var token = 0

    init(data: BabyPathData, store: DataStore, replay: Bool) {
        self.data = data
        self.store = store
        self.replay = replay
        // 先用局部变量：初始化完成前不能读 self 的属性
        let isFrozen = LaunchOptions.babyStep != nil
        frozen = isFrozen
        let states = BabyDemo.states(data) ?? store.babyWords
        let known = Set(states.keys)
        let today = isFrozen ? BabyDemo.today : store.todayKeyString
        var plan: [BabyStep]
        if isFrozen {
            var rng = SeededGenerator(seed: 7)
            plan = BabyPlan.session(data, newWords: BabyPlan.newWords(data, known: known, unlockAll: false, count: 3),
                                    reviews: BabyPlan.dueReviews(states, today: today), known: known,
                                    unlockAll: false, using: &rng)
        } else {
            var rng = SystemRandomNumberGenerator()
            if replay {
                plan = BabyPlan.replay(data, known: known, unlockAll: store.babyUnlockAll, using: &rng)
            } else {
                plan = BabyPlan.session(data,
                                        newWords: BabyPlan.newWords(data, known: known, unlockAll: store.babyUnlockAll,
                                                                    count: store.babyNewPerDay),
                                        reviews: BabyPlan.dueReviews(states, today: today), known: known,
                                        unlockAll: store.babyUnlockAll, using: &rng)
            }
        }
        steps = plan
        sticker = BabyPlan.sticker(for: plan)
        if let s = LaunchOptions.babyStep { index = min(max(s, 0), plan.count - 1) }
    }

    var step: BabyStep { steps[index] }
    var progress: Double { Double(index) / Double(max(steps.count - 1, 1)) }

    func picture(_ word: String) -> String { data.picture(for: word) }

    func start() {
        if frozen { applyDemo() } else { enter() }
    }

    private func applyDemo() {
        switch step {
        case .review(let r), .game(let r):
            switch LaunchOptions.babyDemo {
            case "correct": phase = .solved; praiseTick = 1
            case "wrong": phase = .listening; wrong = Set(r.options.filter { $0 != r.answer }.prefix(1)); firstTry = false
            default: phase = .listening
            }
        case .learn:
            switch LaunchOptions.babyDemo {
            case "recording": phase = .recording
            case "praised": phase = .praised; praiseTick = 1
            default: phase = .inviting
            }
        case .done:
            firstCompletion = true
        }
    }

    private func sayWord(_ w: String, rate: Float = 1.0, then: (() -> Void)? = nil) {
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
            // 系统朗读兜底没有结束回调：估一个时长
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                guard let self, self.token == my else { return }
                then?()
            }
        }
    }

    private func prompt(_ name: String, then: (() -> Void)? = nil) {
        words.stop()
        audio.play(store.phraseFileURL("audio", "\(name).mp3"), onEnd: then)
    }

    private func enter() {
        token += 1
        let my = token
        recorder.cancel()
        audio.stop()
        words.stop()
        wrong = []
        firstTry = true
        switch step {
        case .review(let r), .game(let r):
            phase = .listening
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, self.token == my else { return }
                self.sayWord(r.answer)
            }
        case .learn(let w):
            // 一词一卡：说两遍，然后话筒跳起来请孩子跟着说
            phase = .listening
            sayWord(w) { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    guard let self, self.token == my else { return }
                    self.sayWord(w) { [weak self] in
                        guard let self, self.token == my else { return }
                        self.phase = .inviting
                    }
                }
            }
        case .done:
            phase = .idle
            if !replay, let s = sticker {
                firstCompletion = store.babyFinishToday(sticker: s)
            }
            prompt("prompt_done")
        }
    }

    /// 听音选图：点对了 → 星星 + 表扬，自动下一题；点错了 → 那张图轻轻晃一下，再说一遍，不扣分
    func choose(_ option: String) {
        guard !frozen, phase != .solved else { return }
        let r: BabyRound
        switch step {
        case .review(let x), .game(let x): r = x
        default: return
        }
        let my = token
        if option == r.answer {
            phase = .solved
            praiseTick += 1
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
            sayWord(r.answer)
        }
    }

    func replayWord(rate: Float = 1.0) {
        guard !frozen else { return }
        switch step {
        case .review(let r), .game(let r): sayWord(r.answer, rate: rate)
        case .learn(let w): sayWord(w, rate: rate)
        case .done: break
        }
    }

    func tapMic() {
        guard !frozen, case .learn(let w) = step else { return }
        if phase == .recording { recorder.finish(); return }
        words.stop()
        audio.stop()
        phase = .recording
        let my = token
        recorder.start(key: "baby-\(w)") { [weak self] spoke in
            guard let self, self.token == my else { return }
            if spoke {
                self.phase = .playingBack
                self.recorder.playBack("baby-\(w)") { [weak self] in
                    guard let self, self.token == my else { return }
                    self.praiseTick += 1
                    self.phase = .praised
                    self.prompt(["prompt_great", "prompt_well", "prompt_yay"][self.praiseTick % 3])
                }
            } else {
                // 没出声也不说错：「下一个」照样跳起来
                self.phase = .praised
            }
        }
    }

    func next() {
        guard !frozen else { return }
        if case .learn(let w) = step, !replay { store.babyLearn(w) }
        guard index < steps.count - 1 else { return }
        index += 1
        enter()
    }

    func stopAll() {
        token += 1
        audio.stop()
        words.stop()
        recorder.cancel()
    }
}

struct BabySessionView: View {
    let c: BabySessionController
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            topBar
            switch c.step {
            case .review(let r), .game(let r):
                BabyChoiceView(c: c, round: r).id(c.index)
            case .learn(let w):
                BabyLearnCard(c: c, word: w).id(c.index)
            case .done:
                BabyDoneView(c: c, onClose: { c.stopAll(); onClose() })
            }
        }
        .padding(.bottom, 8)
        .onDisappear { c.stopAll() }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
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

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.hairline)
                    Capsule().fill(Func.accent)
                        .frame(width: max(14, geo.size.width * c.progress))
                        .animation(.easeOut(duration: 0.3), value: c.index)
                }
            }
            .frame(height: 14)

            stageIcon
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    /// 这一步在干什么：绿圈=复习、星星=学新词、手柄=小游戏
    private var stageIcon: some View {
        let icon: String
        let tint: Color
        switch c.step {
        case .review: icon = "arrow.counterclockwise"; tint = Func.positiveDeep
        case .learn: icon = "sparkles"; tint = Func.accentDeep
        case .game: icon = "gamecontroller.fill"; tint = Func.infoDeep
        case .done: icon = "star.fill"; tint = PhraseColors.gold
        }
        return Image(systemName: icon)
            .kidFont(20, .bold, maxScale: 1.1)
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(tint.opacity(0.14), in: Circle())
            .accessibilityHidden(true)
    }
}

/// 听音选图：一个大喇叭 + 三张大图（上二下一）
private struct BabyChoiceView: View {
    let c: BabySessionController
    let round: BabyRound

    var body: some View {
        GeometryReader { geo in
            let side = min((geo.size.width - 60) / 2, (geo.size.height - 170) / 2)
            VStack(spacing: 18) {
                Spacer(minLength: 0)
                Button { c.replayWord() } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .kidFont(46, .bold, maxScale: 1.0)
                        .foregroundStyle(.white)
                        .frame(width: 110, height: 110)
                        .background(Func.accentPill, in: Circle())
                        .overlay { Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 4).padding(4) }
                        .elevationRaised()
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("再听一遍")

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

/// 学新词：一词一卡。大图、喇叭、话筒、下一个
private struct BabyLearnCard: View {
    let c: BabySessionController
    let word: String
    @State private var wiggle = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width - 48, geo.size.height * 0.56)
            VStack(spacing: 14) {
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

                Text(word)
                    .kidFont(34, .heavy)
                    .foregroundStyle(Palette.ink)

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

/// 完成：今天的贴纸
private struct BabyDoneView: View {
    let c: BabySessionController
    let onClose: () -> Void
    @State private var pop = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Image(systemName: "seal.fill")
                    .kidFont(240, .bold, maxScale: 1.0)
                    .foregroundStyle(PhraseColors.gold)
                    .shadow(color: PhraseColors.gold.opacity(0.4), radius: 18)
                if let s = c.sticker {
                    BabyPicture(word: c.picture(s), size: 150)
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
                .padding(.bottom, 12)
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

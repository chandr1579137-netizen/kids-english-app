import SwiftUI
import UIKit
import AVFoundation
import Combine

// MARK: - 「说一说」口语课（替换原「读短文」tab）
//
// 一句一卡（版式 B），一次学一个场景，约 5 分钟。课内流程见 Phrases.swift 的 PhraseLessonPlan，
// 设计依据见 docs/pm/phrases-lesson-v1.md。孩子不识字：所有提示都靠声音、大图和按钮动效，
// 英文原句只当小字常驻，中文默认不显示（家长中心可开）。
// 旧「读短文」代码和进度原样保留、不可达（先藏后删，见 docs/retire-90-lessons-plan.md）。

// MARK: 启动参数（CI 截图用）

extension LaunchOptions {
    /// `-uiPhraseScene L1-1` 直接打开某个场景的课
    static var phraseSceneId: String? { value(for: "-uiPhraseScene") }

    /// `-uiPhraseStep N` 停在课内第 N 步（从 0 开始），不放声音、不自动往下走
    static var phraseStep: Int? { value(for: "-uiPhraseStep").flatMap { Int($0) } }

    /// `-uiPhraseDemo recording|praised|answer` 停在卡片的某个状态
    static var phraseDemo: String? { value(for: "-uiPhraseDemo") }

    /// `-uiPhraseChinese` 截图时打开中文
    static var phraseChinese: Bool { ProcessInfo.processInfo.arguments.contains("-uiPhraseChinese") }

    /// `-uiPhraseCompleted L1-1,L1-2` 截图时假装这些场景已学完（只影响显示，不写进度）
    static var phraseCompleted: Set<String> {
        Set((value(for: "-uiPhraseCompleted") ?? "").split(separator: ",").map(String.init))
    }
}

// MARK: 声音

/// 播一条音频，播完回调。新的一次播放会作废上一次的回调。
@Observable
final class PhraseAudio {
    private let player = AudioPlayer()
    private var token = 0
    /// 正在播哪一句（头像据此跳动）
    private(set) var playingLineId: String? = nil

    func play(_ url: URL?, rate: Float = 1.0, lineId: String? = nil, onEnd: (() -> Void)? = nil) {
        token += 1
        let my = token
        playingLineId = lineId
        guard let url else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self, self.token == my else { return }
                self.playingLineId = nil
                onEnd?()
            }
            return
        }
        player.onTimeUpdate = { [weak self] t in
            guard t >= 999999, let self, self.token == my else { return }
            self.playingLineId = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                guard self.token == my else { return }
                onEnd?()
            }
        }
        player.play(url: url, rate: rate)
    }

    func stop() {
        token += 1
        playingLineId = nil
        player.onTimeUpdate = nil
        player.stop()
    }
}

/// 跟读录音：开着电平表，孩子说完停顿一下就自动结束；只判断出没出声（SpeakCheck）。
@Observable
final class PhraseVoiceRecorder {
    private var recorder: AVAudioRecorder? = nil
    private var meterTimer: Timer? = nil
    private var playback: AVAudioPlayer? = nil
    private var onFinish: ((Bool) -> Void)? = nil
    private var peak: Float = -160
    private var lastLoudAt: Date? = nil
    private var startedAt = Date()

    private(set) var isRecording = false
    /// 0…1，给录音圈的动效用
    private(set) var level: CGFloat = 0
    private(set) var permissionDenied = false

    /// 最长录几秒；说完后安静多久自动停
    static let maxSeconds: TimeInterval = 5
    static let silenceAfterVoice: TimeInterval = 0.9

    private func fileURL(_ key: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("phrase_\(key).m4a")
    }

    func hasRecording(_ key: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(key).path)
    }

    func start(key: String, onFinish: @escaping (Bool) -> Void) {
        cancel()
        switch AVAudioApplication.shared.recordPermission {
        case .denied:
            permissionDenied = true
            onFinish(false)
            return
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.start(key: key, onFinish: onFinish)
                    } else {
                        self.permissionDenied = true
                        onFinish(false)
                    }
                }
            }
            return
        default:
            break
        }
        permissionDenied = false
        AudioSession.configureRecording()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
        ]
        guard let r = try? AVAudioRecorder(url: fileURL(key), settings: settings) else {
            AudioSession.configurePlayback()
            onFinish(false)
            return
        }
        r.isMeteringEnabled = true
        guard r.record() else {
            AudioSession.configurePlayback()
            onFinish(false)
            return
        }
        recorder = r
        isRecording = true
        peak = -160
        lastLoudAt = nil
        startedAt = Date()
        self.onFinish = onFinish
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard let r = recorder, isRecording else { return }
        r.updateMeters()
        let p = r.peakPower(forChannel: 0)
        peak = max(peak, p)
        level = CGFloat(max(0, min(1, (r.averagePower(forChannel: 0) + 50) / 40)))
        let now = Date()
        if SpeakCheck.didSpeak(peakDB: p) { lastLoudAt = now }
        if let last = lastLoudAt, now.timeIntervalSince(last) > Self.silenceAfterVoice {
            finish()
        } else if now.timeIntervalSince(startedAt) > Self.maxSeconds {
            finish()
        }
    }

    /// 结束录音并回调「说了没有」
    func finish() { stop(notify: true) }

    /// 放弃这次录音，不回调
    func cancel() { stop(notify: false) }

    private func stop(notify: Bool) {
        meterTimer?.invalidate()
        meterTimer = nil
        playback?.stop()
        guard isRecording else { onFinish = nil; return }
        recorder?.stop()
        recorder = nil
        isRecording = false
        level = 0
        // 录音会把会话切成 playAndRecord，录完立刻切回播放，否则后面示范音偏小
        AudioSession.configurePlayback()
        let callback = onFinish
        onFinish = nil
        if notify { callback?(SpeakCheck.didSpeak(peakDB: peak)) }
    }

    /// 回放孩子自己的声音，播完回调
    func playBack(_ key: String, onEnd: @escaping () -> Void) {
        guard hasRecording(key), let p = try? AVAudioPlayer(contentsOf: fileURL(key)) else {
            onEnd()
            return
        }
        AudioSession.configurePlayback()
        playback = p
        p.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + p.duration + 0.2) { onEnd() }
    }
}

// MARK: 课内流程控制

@Observable
final class PhraseLessonController {
    /// 一张卡当前的状态
    enum Phase: Equatable {
        case idle
        /// 正在放示范音
        case modeling
        /// 等孩子开口（话筒在跳）
        case inviting
        case recording
        /// 在回放孩子自己的声音
        case playingBack
        /// 刚表扬完，「下一个」在跳
        case praised
        /// 回想卡：已放出示范音（答案）
        case answer
    }

    let scene: PhraseScene
    let steps: [PhraseStep]
    let frozen: Bool
    let audio = PhraseAudio()
    let recorder = PhraseVoiceRecorder()
    private let store: DataStore

    private(set) var index = 0
    private(set) var phase: Phase = .idle
    private var attempts = 0
    /// 每次表扬加 1，触发星星动效
    private(set) var praiseTick = 0
    /// 「看」这一步正在放第几句
    private(set) var watchIndex: Int? = nil
    private(set) var watchFinished = false
    /// 完成页：这次是不是第一次学完（第一次才发星星和卡片）
    private(set) var firstCompletion = false
    private var token = 0

    init(scene: PhraseScene, catalog: PhraseCatalog?, store: DataStore) {
        self.scene = scene
        self.store = store
        steps = PhraseLessonPlan.steps(for: scene, previous: catalog?.scene(before: scene.id))
        frozen = LaunchOptions.phraseStep != nil
        if let s = LaunchOptions.phraseStep {
            index = min(max(s, 0), steps.count - 1)
        }
    }

    var step: PhraseStep { steps[index] }

    /// 进度条：完成页之前的步数
    var progress: Double { Double(index) / Double(max(steps.count - 1, 1)) }

    func line(for step: PhraseStep) -> PhraseLine? {
        switch step {
        case .warmup(let l): return l
        case .learn(let i), .turn(let i): return scene.lines[i]
        case .watch, .done: return nil
        }
    }

    var currentLine: PhraseLine? { line(for: step) }

    private var recordingKey: String { "\(currentLine?.id ?? scene.id)-\(index)" }

    var hasOwnRecording: Bool { recorder.hasRecording(recordingKey) }

    // MARK: 资源

    private func lineURL(_ line: PhraseLine) -> URL? { store.phraseFileURL("audio", line.audio) }
    private func promptURL(_ name: String) -> URL? { store.phraseFileURL("audio", "\(name).mp3") }

    // MARK: 进入一步

    func start() {
        if frozen { applyDemoState() } else { enter() }
    }

    private func enter() {
        token += 1
        let my = token
        audio.stop()
        recorder.cancel()
        attempts = 0
        watchIndex = nil
        watchFinished = false

        switch step {
        case .learn(let i):
            phase = .modeling
            // 前两张卡加一句「轮到你」的旁白，教会孩子「听完要说」；之后只靠话筒跳动提示
            let teach = i < 2
            audio.play(lineURL(scene.lines[i]), lineId: scene.lines[i].id) { [weak self] in
                guard let self, self.token == my else { return }
                if teach {
                    self.audio.play(self.promptURL("prompt_say")) { [weak self] in
                        guard let self, self.token == my else { return }
                        self.phase = .inviting
                    }
                } else {
                    self.phase = .inviting
                }
            }
        case .warmup, .turn:
            phase = .inviting
            // 每一段回想开头说一次「轮到你说」，然后等孩子；6 秒没开口就放答案
            let firstOfKind = index == 0 || steps[index - 1].isRecall == false
            let wait: () -> Void = { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    guard let self, self.token == my, self.phase == .inviting else { return }
                    self.revealAnswer()
                }
            }
            if firstOfKind {
                audio.play(promptURL("prompt_turn")) { wait() }
            } else {
                wait()
            }
        case .watch:
            phase = .idle
            audio.play(promptURL("prompt_watch")) { [weak self] in
                guard let self, self.token == my else { return }
                self.playWatch(from: 0, token: my)
            }
        case .done:
            phase = .idle
            firstCompletion = store.completePhraseScene(scene.id)
            audio.play(promptURL("prompt_done"))
        }
    }

    /// 截图用：停在某个状态，不放声音、不写进度
    private func applyDemoState() {
        switch step {
        case .watch:
            watchIndex = min(1, scene.lines.count - 1)
        case .done:
            firstCompletion = true
        default:
            switch LaunchOptions.phraseDemo {
            case "recording": phase = .recording
            case "praised": phase = .praised; praiseTick = 1
            case "answer": phase = .answer
            default: phase = .inviting
            }
        }
    }

    // MARK: 操作

    func tapMic() {
        guard !frozen else { return }
        if phase == .recording {
            recorder.finish()
            return
        }
        audio.stop()
        attempts += 1
        phase = .recording
        let my = token
        recorder.start(key: recordingKey) { [weak self] spoke in
            guard let self, self.token == my else { return }
            self.afterRecording(spoke: spoke, token: my)
        }
    }

    private func afterRecording(spoke: Bool, token my: Int) {
        let recall = step.isRecall
        if spoke {
            // 先让孩子听自己的声音（这本身就是奖励），再表扬
            phase = .playingBack
            recorder.playBack(recordingKey) { [weak self] in
                guard let self, self.token == my else { return }
                self.praise(token: my) {
                    if recall { self.revealAnswer() }
                }
            }
            return
        }
        if recall {
            revealAnswer()
        } else if SpeakCheck.shouldMoveOn(attempt: attempts, spoke: false) {
            // 两次都没出声：不说「错」，直接去下一张
            phase = .idle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self, self.token == my else { return }
                self.next()
            }
        } else {
            // 第一次没出声：温和地再邀请一次，示范音放慢
            phase = .modeling
            audio.play(promptURL("prompt_again")) { [weak self] in
                guard let self, self.token == my, let line = self.currentLine else { return }
                self.audio.play(self.lineURL(line), rate: 0.75, lineId: line.id) { [weak self] in
                    guard let self, self.token == my else { return }
                    self.phase = .inviting
                }
            }
        }
    }

    private func praise(token my: Int, then: (() -> Void)? = nil) {
        praiseTick += 1
        phase = .praised
        let name = ["prompt_great", "prompt_well", "prompt_yay"][praiseTick % 3]
        audio.play(promptURL(name)) { [weak self] in
            guard let self, self.token == my else { return }
            then?()
        }
    }

    /// 回想卡：放出示范音当「答案」
    private func revealAnswer() {
        guard let line = currentLine else { return }
        let my = token
        let wasPraised = phase == .praised
        phase = .answer
        audio.play(lineURL(line), lineId: line.id) { [weak self] in
            guard let self, self.token == my, wasPraised else { return }
            self.phase = .praised
        }
    }

    /// 点大图或「再听」：重放这一句（回想卡里等于看答案）
    func replay(rate: Float = 1.0) {
        guard !frozen, let line = currentLine else { return }
        recorder.cancel()
        if step.isRecall && phase == .inviting {
            revealAnswer()
            return
        }
        let my = token
        let before = phase
        phase = .modeling
        audio.play(lineURL(line), rate: rate, lineId: line.id) { [weak self] in
            guard let self, self.token == my else { return }
            self.phase = before == .modeling || before == .recording || before == .idle ? .inviting : before
        }
    }

    func playOwnVoice() {
        guard !frozen else { return }
        audio.stop()
        recorder.playBack(recordingKey) {}
    }

    private func playWatch(from i: Int, token my: Int) {
        guard scene.lines.indices.contains(i) else {
            watchIndex = nil
            watchFinished = true
            return
        }
        watchIndex = i
        let line = scene.lines[i]
        audio.play(lineURL(line), lineId: line.id) { [weak self] in
            guard let self, self.token == my else { return }
            self.playWatch(from: i + 1, token: my)
        }
    }

    func rewatch() {
        guard !frozen else { return }
        token += 1
        watchFinished = false
        playWatch(from: 0, token: token)
    }

    func next() {
        guard !frozen, index < steps.count - 1 else { return }
        index += 1
        enter()
    }

    func back() {
        guard !frozen, index > 0 else { return }
        index -= 1
        enter()
    }

    func restart() {
        guard !frozen else { return }
        index = 0
        enter()
    }

    func stopAll() {
        token += 1
        audio.stop()
        recorder.cancel()
    }
}

// MARK: - 列表页（tab 根）

struct PhrasesHomeView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if let id = LaunchOptions.phraseSceneId,
                   let scene = store.phraseCatalog?.allScenes.first(where: { $0.id == id }) {
                    PhraseLessonView(scene: scene)
                } else {
                    sceneList
                }
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var completed: Set<String> {
        store.completedPhraseScenes.union(LaunchOptions.phraseCompleted)
    }

    private var sceneList: some View {
        let levels = store.phraseCatalog?.levels ?? []
        let open = PhraseUnlock.unlocked(levels: levels, completed: completed, unlockAll: store.phraseUnlockAll)
        let next = PhraseUnlock.next(levels: levels, completed: completed)
        return KidScrollView {
            VStack(alignment: .leading, spacing: 2) {
                Text("说一说")
                    .pageTitleStyle()
                Text("听一听，说一说，跟 Tom 学说话")
                    .pageSubtitleStyle()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 10)

            starStrip(total: levels.reduce(0) { $0 + $1.scenes.count })
                .padding(.horizontal)
                .padding(.bottom, 14)

            if levels.isEmpty {
                Text("口语课资源没有打包进来")
                    .kidFont(17, .bold)
                    .foregroundStyle(Palette.inkMuted)
                    .padding()
            }

            ForEach(levels) { level in
                VStack(alignment: .leading, spacing: 10) {
                    Text("L\(level.level) · \(level.titleZh)")
                        .kidFont(20, .heavy)
                        .foregroundStyle(Palette.ink)
                        .padding(.horizontal)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                              spacing: 12) {
                        ForEach(level.scenes) { scene in
                            let unlocked = open.contains(scene.id)
                            NavigationLink {
                                PhraseLessonView(scene: scene)
                            } label: {
                                PhraseSceneTile(scene: scene,
                                                done: completed.contains(scene.id),
                                                isNext: scene.id == next,
                                                locked: !unlocked)
                            }
                            .buttonStyle(PressableStyle())
                            // 锁不能只是画上去的：没解锁的点不开
                            .disabled(!unlocked)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 16)
            }
        }
    }

    /// 已得星星：一个场景一颗，孩子看得懂的进度
    private func starStrip(total: Int) -> some View {
        let got = completed.count
        return HStack(spacing: 6) {
            ForEach(0..<max(total, 1), id: \.self) { i in
                Image(systemName: i < got ? "star.fill" : "star")
                    .kidFont(22, .bold, maxScale: 1.1)
                    .foregroundStyle(i < got ? PhraseColors.gold : Palette.inkSubtle)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement()
        .accessibilityLabel("已得 \(got) 颗星，一共 \(total) 颗")
    }
}

/// 场景卡：第一句的图当封面
struct PhraseSceneTile: View {
    let scene: PhraseScene
    let done: Bool
    let isNext: Bool
    let locked: Bool
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                if let first = scene.lines.first {
                    PhrasePicture(line: first, side: geo.size.width, corner: 18)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay(alignment: .topTrailing) { badge.padding(6) }
            .overlay {
                if locked {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                }
            }

            Text(scene.titleEn)
                .kidFont(18, .heavy)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(scene.titleZh)
                .kidFont(14, .semibold)
                .foregroundStyle(Palette.inkMuted)
                .lineLimit(1)
        }
        .padding(8)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(isNext ? Func.positiveDeep : Color.clear, lineWidth: 3)
        }
        .elevationGround()
        .scaleEffect(isNext && pulse ? 1.03 : 1.0)
        .onAppear {
            guard isNext, !LaunchOptions.isUIScreenshotRun else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(scene.titleZh)，\(done ? "学过了" : (locked ? "还没解锁" : "可以学"))")
    }

    @ViewBuilder
    private var badge: some View {
        if done {
            circleBadge("star.fill", PhraseColors.gold)
        } else if locked {
            circleBadge("lock.fill", Palette.inkSubtle)
        } else {
            circleBadge("play.fill", Func.positiveDeep)
        }
    }

    private func circleBadge(_ icon: String, _ color: Color) -> some View {
        ZStack {
            Circle().fill(color)
            Image(systemName: icon)
                .kidFont(16, .black, maxScale: 1.0)
                .foregroundStyle(.white)
        }
        .frame(width: 36, height: 36)
        .overlay { Circle().strokeBorder(Color.white, lineWidth: 2) }
    }
}

// MARK: - 一节课

struct PhraseLessonView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let scene: PhraseScene
    @State private var controller: PhraseLessonController?

    var body: some View {
        Group {
            if let controller {
                PhraseLessonBody(c: controller, onClose: {
                    controller.stopAll()
                    dismiss()
                })
            } else {
                Color.clear
            }
        }
        .creamBackground()
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            guard controller == nil else { return }
            let c = PhraseLessonController(scene: scene, catalog: store.phraseCatalog, store: store)
            controller = c
            c.start()
        }
        .onDisappear { controller?.stopAll() }
    }
}

private struct PhraseLessonBody: View {
    @Environment(DataStore.self) private var store
    let c: PhraseLessonController
    let onClose: () -> Void

    private var showChinese: Bool { store.phraseShowChinese || LaunchOptions.phraseChinese }

    var body: some View {
        VStack(spacing: 8) {
            topBar
            switch c.step {
            case .learn, .warmup, .turn:
                if let line = c.currentLine {
                    PhraseCardView(c: c, line: line, showChinese: showChinese)
                        .id(c.index)
                }
            case .watch:
                PhraseWatchView(c: c, showChinese: showChinese)
            case .done:
                PhraseDoneView(c: c, onClose: onClose)
            }
        }
        .padding(.bottom, 8)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .kidFont(18, .black, maxScale: 1.1)
                    .foregroundStyle(Palette.inkMuted)
                    .frame(width: 44, height: 44)
                    .background(Palette.surface, in: Circle())
                    .overlay { Circle().strokeBorder(Palette.hairline, lineWidth: 1.5) }
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("回到列表")

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.hairline)
                    Capsule().fill(Func.accent)
                        .frame(width: max(14, geo.size.width * c.progress))
                        .animation(.easeOut(duration: 0.3), value: c.index)
                }
            }
            .frame(height: 14)
            .accessibilityElement()
            .accessibilityLabel("进度")

            stageIcon
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    /// 这一步在干什么：耳朵=听着学，眼睛=看一遍，话筒气泡=轮到你说（不用识字也能分）
    private var stageIcon: some View {
        let icon: String
        let tint: Color
        switch c.step {
        case .learn: icon = "ear.fill"; tint = Func.infoDeep
        case .watch: icon = "eyes"; tint = Func.accentDeep
        case .warmup, .turn: icon = "bubble.left.fill"; tint = Func.positiveDeep
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

// MARK: 一句一卡（学 / 热身 / 轮到你）

private struct PhraseCardView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    let c: PhraseLessonController
    let line: PhraseLine
    let showChinese: Bool

    /// 回想卡在放出答案之前不显示原句，让孩子看图自己想
    private var hideText: Bool {
        c.step.isRecall && !(c.phase == .answer || c.phase == .praised)
    }

    var body: some View {
        GeometryReader { geo in
            // 大字号时文字和按钮都变高，图要让出位置，否则原句会压到说话人名字上
            let side = min(geo.size.width - 40, geo.size.height * (typeSize >= .xxLarge ? 0.38 : 0.5))
            VStack(spacing: 10) {
                Spacer(minLength: 0)
                Button { c.replay() } label: {
                    PhrasePicture(line: line, side: side, corner: 28)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(Color.white, lineWidth: 5)
                        }
                        .elevationRaised()
                        .overlay { PraiseBurst(tick: c.praiseTick, show: c.phase == .praised) }
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("再听一遍")

                speakerRow

                VStack(spacing: 2) {
                    if hideText {
                        // 回想卡先不给原句：放一个「该你说了」的对话气泡（三个点在跳），
                        // 不用问号——问号对大人像出错，对不识字的孩子也没有意思
                        YourTurnBubble()
                    } else {
                        Text(line.en)
                            .kidFont(26, .heavy)
                            .foregroundStyle(Palette.ink)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                    }
                    if showChinese && !hideText {
                        Text(line.zh)
                            .kidFont(16, .medium)
                            .foregroundStyle(Palette.inkMuted)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                .frame(minHeight: 40)

                Spacer(minLength: 0)
                mainButtons
                smallButtons
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .overlay(alignment: .top) {
            if c.phase == .recording { listeningBadge.padding(.top, 4) }
        }
    }

    private var speakerRow: some View {
        let ch = store.phraseCatalog?.character(line.speaker)
        return HStack(spacing: 8) {
            PhraseAvatarView(speaker: line.speaker, size: 44,
                             active: c.audio.playingLineId == line.id)
            Text(ch?.nameEn ?? line.speaker.capitalized)
                .kidFont(18, .heavy)
                .foregroundStyle(Palette.inkMuted)
        }
    }

    /// 三个大按钮：再听 · 说 · 下一个
    private var mainButtons: some View {
        HStack(alignment: .center, spacing: 0) {
            roundButton(icon: "speaker.wave.2.fill", tint: Func.infoDeep, size: 64, label: "再听") {
                c.replay()
            }
            .frame(maxWidth: .infinity)

            PhraseMicButton(phase: c.phase, level: c.recorder.level) { c.tapMic() }
                .frame(maxWidth: .infinity)

            let ready = c.phase == .praised || c.phase == .answer
            PulsingNextButton(highlight: ready, label: "下一个") { c.next() }
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 8)
    }

    /// 小按钮：上一张 · 慢速 · 我的声音
    private var smallButtons: some View {
        HStack(spacing: 10) {
            smallButton(icon: "chevron.left", title: "上一张", enabled: c.index > 0) { c.back() }
            smallButton(icon: "tortoise.fill", title: "慢速", enabled: true) { c.replay(rate: 0.75) }
            smallButton(icon: "person.wave.2.fill", title: "我的声音", enabled: c.hasOwnRecording) { c.playOwnVoice() }
        }
        .padding(.horizontal, 16)
    }

    private var listeningBadge: some View {
        HStack(spacing: 6) {
            Circle().fill(Func.negativeDeep).frame(width: 10, height: 10)
            Text("正在听你说…")
                .kidFont(15, .bold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6), in: Capsule())
    }

    private func roundButton(icon: String, tint: Color, size: CGFloat, label: String,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .kidFont(size * 0.4, .bold, maxScale: 1.1)
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(tint, in: Circle())
                .overlay { Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 3).padding(3) }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(label)
    }

    private func smallButton(icon: String, title: String, enabled: Bool,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).kidFont(14, .bold, maxScale: 1.1)
                Text(title).kidFont(14, .bold, maxScale: 1.15).lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(Palette.inkMuted)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Palette.surface, in: Capsule())
            .overlay { Capsule().strokeBorder(Palette.hairline, lineWidth: 1) }
            .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .accessibilityLabel(title)
    }
}

/// 「该你说了」：绿色对话气泡里三个点依次跳动（像对方正在说话），回想卡用它代替原句
private struct YourTurnBubble: View {
    @State private var phase = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: 11, height: 11)
                    .offset(y: phase == i && !LaunchOptions.isUIScreenshotRun ? -4 : 0)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 40)
        .background(Func.positiveDeep, in: Capsule())
        .overlay(alignment: .bottomLeading) {
            // 气泡尾巴，指向上面的说话人
            Circle().fill(Func.positiveDeep).frame(width: 10, height: 10).offset(x: 6, y: 4)
        }
        .animation(.easeInOut(duration: 0.25), value: phase)
        .onReceive(timer) { _ in phase = (phase + 1) % 3 }
        .accessibilityElement()
        .accessibilityLabel("轮到你说")
    }
}

/// 话筒：等孩子说时一跳一跳，录音时外圈跟着音量变大
private struct PhraseMicButton: View {
    let phase: PhraseLessonController.Phase
    let level: CGFloat
    let action: () -> Void
    @State private var bounce = false

    private var recording: Bool { phase == .recording }
    private var inviting: Bool { phase == .inviting }

    var body: some View {
        Button(action: action) {
            ZStack {
                if recording {
                    Circle()
                        .fill(Func.negativeDeep.opacity(0.22))
                        .frame(width: 96 + 36 * max(level, 0.3), height: 96 + 36 * max(level, 0.3))
                        .animation(.easeOut(duration: 0.08), value: level)
                }
                Circle()
                    .fill(recording ? Func.negativeDeep : Func.accentPill)
                    .frame(width: 96, height: 96)
                    .overlay { Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 3).padding(3) }
                    .elevationRaised()
                Image(systemName: recording ? "waveform" : "mic.fill")
                    .kidFont(40, .bold, maxScale: 1.1)
                    .foregroundStyle(.white)
            }
            .frame(width: 132, height: 132)
            .scaleEffect(inviting && bounce ? 1.1 : 1.0)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(recording ? "说完了" : "说一说")
        .onAppear(perform: animate)
        .onChange(of: phase) { _, _ in animate() }
    }

    private func animate() {
        bounce = false
        guard inviting, !LaunchOptions.isUIScreenshotRun else { return }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { bounce = true }
    }
}

/// 「下一个」：该走的时候一跳一跳
private struct PulsingNextButton: View {
    let highlight: Bool
    let label: String
    let action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.right")
                .kidFont(26, .black, maxScale: 1.1)
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(highlight ? Func.positiveDeep : Func.positiveDeep.opacity(0.45), in: Circle())
                .overlay { Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 3).padding(3) }
                .scaleEffect(highlight && pulse ? 1.12 : 1.0)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(label)
        .onAppear(perform: animate)
        .onChange(of: highlight) { _, _ in animate() }
    }

    private func animate() {
        pulse = false
        guard highlight, !LaunchOptions.isUIScreenshotRun else { return }
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { pulse = true }
    }
}

/// 表扬时从图上飞出的星星
private struct PraiseBurst: View {
    let tick: Int
    let show: Bool
    @State private var go = false

    private let angles: [Double] = [-150, -110, -70, -30, 10, 50]

    var body: some View {
        ZStack {
            if show {
                ForEach(angles.indices, id: \.self) { i in
                    let a = CGFloat(angles[i] * .pi / 180)
                    let dx: CGFloat = go ? cos(a) * 120 : 0
                    let dy: CGFloat = go ? sin(a) * 120 : 0
                    Image(systemName: "star.fill")
                        .kidFont(i % 2 == 0 ? 34 : 24, .bold, maxScale: 1.0)
                        .foregroundStyle(PhraseColors.gold)
                        .shadow(color: .white, radius: 2)
                        .offset(x: dx, y: dy)
                        .opacity(go || LaunchOptions.isUIScreenshotRun ? 1 : 0)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: tick) { _, _ in fire() }
        .onAppear { if show { fire() } }
    }

    private func fire() {
        if LaunchOptions.isUIScreenshotRun { go = true; return }
        go = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { go = true }
    }
}

// MARK: 看一遍（整段连播）

private struct PhraseWatchView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    let c: PhraseLessonController
    let showChinese: Bool

    private var shown: PhraseLine? {
        c.scene.lines.indices.contains(c.watchIndex ?? -1) ? c.scene.lines[c.watchIndex!]
            : c.scene.lines.last
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width - 40, geo.size.height * (typeSize >= .xxLarge ? 0.4 : 0.52))
            VStack(spacing: 12) {
                Spacer(minLength: 0)
                if let line = shown {
                    PhrasePicture(line: line, side: side, corner: 28)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(Color.white, lineWidth: 5)
                        }
                        .elevationRaised()
                        .id(line.id)
                        .transition(.opacity)
                    speakers(active: c.watchIndex == nil ? nil : line.speaker)
                    Text(line.en)
                        .kidFont(26, .heavy)
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, 20)
                    if showChinese {
                        Text(line.zh)
                            .kidFont(16, .medium)
                            .foregroundStyle(Palette.inkMuted)
                    }
                }
                PhraseLineDots(count: c.scene.lines.count, current: c.watchIndex,
                               finished: c.watchFinished)
                Spacer(minLength: 0)
                HStack(spacing: 0) {
                    Button { c.rewatch() } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .kidFont(26, .black, maxScale: 1.1)
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Func.infoDeep, in: Circle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel("再看一遍")
                    .frame(maxWidth: .infinity)

                    PulsingNextButton(highlight: c.watchFinished, label: "下一步") { c.next() }
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.easeInOut(duration: 0.25), value: c.watchIndex)
        }
    }

    /// 这个场景里的所有人，正在说话的那个放大
    private func speakers(active: String?) -> some View {
        var seen: [String] = []
        for l in c.scene.lines where !seen.contains(l.speaker) { seen.append(l.speaker) }
        return HStack(spacing: 14) {
            ForEach(seen, id: \.self) { id in
                PhraseAvatarView(speaker: id, size: 48, active: id == active)
            }
        }
    }
}

/// 句子顺序的小圆点（不显示数字）
private struct PhraseLineDots: View {
    let count: Int
    let current: Int?
    let finished: Bool

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                let on = finished || (current.map { i <= $0 } ?? false)
                Circle()
                    .fill(on ? Func.accent : Palette.hairline)
                    .frame(width: current == i ? 14 : 10, height: current == i ? 14 : 10)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: 完成

private struct PhraseDoneView: View {
    let c: PhraseLessonController
    let onClose: () -> Void
    @State private var pop = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Image(systemName: "star.fill")
                    .kidFont(150, .bold, maxScale: 1.0)
                    .foregroundStyle(PhraseColors.gold)
                    .shadow(color: PhraseColors.gold.opacity(0.4), radius: 16)
                PhraseAvatarView(speaker: "tom", size: 74, active: false)
                    .offset(y: 8)
            }
            .scaleEffect(pop ? 1 : 0.6)
            .onAppear {
                if LaunchOptions.isUIScreenshotRun { pop = true; return }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { pop = true }
            }

            Text("You did it!")
                .kidFont(32, .heavy)
                .foregroundStyle(Palette.ink)
            Text(c.firstCompletion ? "得到一颗星和一张卡片「\(c.scene.titleEn)」" : "又学了一遍，真棒！")
                .kidFont(17, .semibold)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            VStack(spacing: 12) {
                AppButton(title: "回到列表", icon: "square.grid.2x2.fill", action: onClose)
                AppButton(title: "再来一遍", icon: "arrow.counterclockwise", tier: .secondary) { c.restart() }
            }
            .frame(maxWidth: 360)
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - 图与头像

enum PhraseColors {
    static let gold = Color(red: 1.0, green: 0.76, blue: 0.08)
    static let outline = Color(red: 0.36, green: 0.22, blue: 0.12)
    static let sun = Color(red: 1.0, green: 0.80, blue: 0.20)
    static let moon = Color(red: 1.0, green: 0.90, blue: 0.55)
    static let hill = Color(red: 0.55, green: 0.78, blue: 0.42)
    static let night = Color(red: 0.12, green: 0.17, blue: 0.38)
    static let paper = Color(red: 0.99, green: 0.96, blue: 0.91)
}

/// 本地图片解码一次就缓存，翻卡时不重复解 768×768 的 JPEG
private enum PhraseImageCache {
    static let cache = NSCache<NSURL, UIImage>()

    static func image(_ url: URL?) -> UIImage? {
        guard let url else { return nil }
        if let hit = cache.object(forKey: url as NSURL) { return hit }
        guard let ui = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(ui, forKey: url as NSURL)
        return ui
    }
}

/// 句子配图：新图 / 现成词图 / 代码画
struct PhrasePicture: View {
    @Environment(DataStore.self) private var store
    let line: PhraseLine
    let side: CGFloat
    var corner: CGFloat = 24

    var body: some View {
        Group {
            if let file = line.image, let ui = PhraseImageCache.image(store.phraseFileURL("img", file)) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else if let icon = line.icon, let ui = PhraseImageCache.image(store.iconURL(forWord: icon)) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else if let code = line.code {
                PhraseCodeCard(kind: code, icon: line.codeIcon, side: side)
            } else {
                PhraseColors.paper
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .accessibilityHidden(true)
    }
}

struct PhraseAvatarView: View {
    @Environment(DataStore.self) private var store
    let speaker: String
    var size: CGFloat = 44
    var active = false

    var body: some View {
        let avatar = store.phraseCatalog?.character(speaker)?.avatar ?? "\(speaker).jpg"
        ZStack {
            Circle().fill(Palette.surface)
            if let ui = PhraseImageCache.image(store.phraseFileURL("avatars", avatar)) {
                Image(uiImage: ui).resizable().scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle().strokeBorder(active ? Func.accent : Palette.hairline, lineWidth: active ? 3 : 1.5)
        }
        .scaleEffect(active ? 1.15 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: active)
        .accessibilityHidden(true)
    }
}

/// 代码画的卡片：日出 / 下午 / 明天 / 傍晚 / 夜里。太阳和月亮都没有脸，图里没有字。
struct PhraseCodeCard: View {
    let kind: String
    let icon: String?
    let side: CGFloat

    var body: some View {
        ZStack {
            switch kind {
            case "sunrise": sunrise
            case "afternoon": afternoon
            case "tomorrow": tomorrow
            case "evening": evening
            default: night
            }
        }
        .frame(width: side, height: side)
    }

    private var sunrise: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 1.0, green: 0.84, blue: 0.58), Color(red: 0.99, green: 0.94, blue: 0.82)],
                           startPoint: .top, endPoint: .bottom)
            sun(size: side * 0.34, rays: true)
                .position(x: side * 0.5, y: side * 0.66)
            hill
            // 窗框：孩子在屋里看日出
            RoundedRectangle(cornerRadius: side * 0.04)
                .strokeBorder(Color(red: 0.62, green: 0.42, blue: 0.24), lineWidth: side * 0.05)
                .padding(side * 0.06)
        }
    }

    private var afternoon: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.62, green: 0.83, blue: 0.98), Color(red: 0.86, green: 0.94, blue: 0.99)],
                           startPoint: .top, endPoint: .bottom)
            // 太阳一天的弧线，停在偏右下午的位置
            Path { p in
                p.addArc(center: CGPoint(x: side * 0.5, y: side * 0.78), radius: side * 0.38,
                         startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            }
            .stroke(Color.white, style: StrokeStyle(lineWidth: side * 0.015, dash: [side * 0.03, side * 0.025]))
            let angle = CGFloat.pi * 0.2
            sun(size: side * 0.2, rays: true)
                .position(x: side * 0.5 + cos(angle) * side * 0.38,
                          y: side * 0.78 - sin(angle) * side * 0.38)
            hill
            iconTile(size: side * 0.3).position(x: side * 0.27, y: side * 0.74)
        }
    }

    private var tomorrow: some View {
        ZStack {
            PhraseColors.paper
            HStack(spacing: side * 0.04) {
                ZStack {
                    PhraseColors.night
                    moon(size: side * 0.2, background: PhraseColors.night)
                    stars(count: 3, in: side * 0.38)
                }
                .frame(width: side * 0.38, height: side * 0.5)
                .clipShape(RoundedRectangle(cornerRadius: side * 0.05))

                Image(systemName: "arrow.right")
                    .font(.system(size: side * 0.09, weight: .black))
                    .foregroundStyle(PhraseColors.outline)

                ZStack {
                    LinearGradient(colors: [Color(red: 1.0, green: 0.86, blue: 0.62), Color(red: 0.74, green: 0.88, blue: 0.99)],
                                   startPoint: .bottom, endPoint: .top)
                    sun(size: side * 0.14, rays: true).offset(y: -side * 0.1)
                    iconTile(size: side * 0.17).offset(y: side * 0.13)
                }
                .frame(width: side * 0.38, height: side * 0.5)
                .clipShape(RoundedRectangle(cornerRadius: side * 0.05))
            }
        }
    }

    private var evening: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.42, green: 0.33, blue: 0.66), Color(red: 1.0, green: 0.62, blue: 0.38)],
                           startPoint: .top, endPoint: .bottom)
            sun(size: side * 0.3, rays: false)
                .position(x: side * 0.62, y: side * 0.8)
            hill
            Image(systemName: "star.fill")
                .font(.system(size: side * 0.07))
                .foregroundStyle(Color.white)
                .position(x: side * 0.2, y: side * 0.2)
            iconTile(size: side * 0.3).position(x: side * 0.28, y: side * 0.72)
        }
    }

    private var night: some View {
        ZStack {
            PhraseColors.night
            stars(count: 6, in: side)
            moon(size: side * 0.3, background: PhraseColors.night)
                .position(x: side * 0.68, y: side * 0.3)
            iconTile(size: side * 0.36).position(x: side * 0.5, y: side * 0.72)
        }
    }

    // MARK: 零件

    private var hill: some View {
        Ellipse()
            .fill(PhraseColors.hill)
            .overlay { Ellipse().stroke(PhraseColors.outline, lineWidth: side * 0.008) }
            .frame(width: side * 1.4, height: side * 0.42)
            .position(x: side * 0.5, y: side * 0.98)
    }

    private func sun(size: CGFloat, rays: Bool) -> some View {
        ZStack {
            if rays {
                ForEach(0..<8, id: \.self) { i in
                    Capsule()
                        .fill(PhraseColors.sun)
                        .overlay { Capsule().stroke(PhraseColors.outline, lineWidth: 1.5) }
                        .frame(width: size * 0.1, height: size * 0.28)
                        .offset(y: -size * 0.72)
                        .rotationEffect(.degrees(Double(i) * 45))
                }
            }
            Circle()
                .fill(PhraseColors.sun)
                .overlay { Circle().stroke(PhraseColors.outline, lineWidth: 2.5) }
                .frame(width: size, height: size)
        }
    }

    /// 弯月：一个圆被同色背景的圆挖掉一块
    private func moon(size: CGFloat, background: Color) -> some View {
        ZStack {
            Circle().fill(PhraseColors.moon).frame(width: size, height: size)
            Circle().fill(background).frame(width: size * 0.86, height: size * 0.86)
                .offset(x: size * 0.32, y: -size * 0.16)
        }
    }

    private func stars(count: Int, in box: CGFloat) -> some View {
        let spots: [(CGFloat, CGFloat)] = [(0.18, 0.18), (0.38, 0.1), (0.15, 0.45), (0.85, 0.12), (0.88, 0.5), (0.3, 0.32)]
        return ZStack {
            ForEach(0..<min(count, spots.count), id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: box * (i % 2 == 0 ? 0.06 : 0.045)))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .position(x: box * spots[i].0, y: box * spots[i].1)
            }
        }
        .frame(width: box, height: box)
    }

    @ViewBuilder
    private func iconTile(size: CGFloat) -> some View {
        if let icon {
            WordIconView(word: icon, size: size)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white, lineWidth: 3)
                }
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
    }
}

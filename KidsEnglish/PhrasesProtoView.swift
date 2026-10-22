import SwiftUI
import UIKit

// MARK: - 「日常口语」版式原型（proto/daily-phrases，只做原型，不合并）
//
// 用户觉得「读短文」不适合 4 岁孩子，想换成日常问候/生活用语，但还没定版式。
// 这里把同一个场景（p08_eat「吃饭啦」7 句）做成三种版式给用户挑：
//   A 对话气泡  ·  B 一句一卡  ·  C 情景图 + 点读
// 只能用启动参数 `-uiPhrases A|B|C` 打开，不接入任何现有入口，不动「读短文」。
// 素材全部复用仓库已有图：word-icons 的 boy / mother / father 当头像，
// 句子配图 wash / hungry / food / yummy / rice / thirsty，"I'm full." 用灰色占位框；
// 情景图用「找一找」的 scenes/scene_kitchen.jpg。

// MARK: 启动参数

extension LaunchOptions {
    private static var phraseArgs: [String] { ProcessInfo.processInfo.arguments }

    private static func phraseValue(_ key: String) -> String? {
        let args = phraseArgs
        guard let i = args.firstIndex(of: key), args.indices.contains(i + 1) else { return nil }
        return args[i + 1]
    }

    /// `-uiPhrases A|B|C`：把对应版式原型当根视图渲染
    static var phrasesLayout: String? {
        guard let raw = phraseValue("-uiPhrases")?.uppercased(),
              ["A", "B", "C"].contains(raw) else { return nil }
        return raw
    }

    /// `-uiPhraseStep N`：停在第 N 句（从 0 开始）的播放态，不自动往下走
    static var phraseStep: Int? {
        guard let raw = phraseValue("-uiPhraseStep"), let n = Int(raw) else { return nil }
        return n
    }

    /// `-uiPhraseRole`：A 方案「我来当 Tom」态
    static var phraseRole: Bool { phraseArgs.contains("-uiPhraseRole") }

    /// `-uiPhraseRecord`：B 方案录音中态（截图用，不真的打开麦克风）
    static var phraseRecord: Bool { phraseArgs.contains("-uiPhraseRecord") }
}

// MARK: 数据（Resources/phrases-proto.json）

struct PhraseProtoCharacter: Decodable, Hashable {
    let id: String
    let name: String
    let avatar: String
    let side: String
}

struct PhraseProtoLine: Decodable, Identifiable, Hashable {
    let id: String
    let speaker: String
    let en: String
    let zh: String
    let icon: String?
    let audio: String
}

struct PhraseProtoScene: Decodable {
    let id: String
    let title_zh: String
    let title_en: String
    let image: String
    let lines: [PhraseProtoLine]
}

struct PhraseProtoData: Decodable {
    let characters: [PhraseProtoCharacter]
    let scene: PhraseProtoScene

    static func load() -> PhraseProtoData? {
        guard let url = Bundle.main.url(forResource: "phrases-proto", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PhraseProtoData.self, from: data)
    }

    func character(_ id: String) -> PhraseProtoCharacter? {
        characters.first { $0.id == id }
    }
}

/// 头像在整身词图里的脸部位置（中心 x/y、裁切边长，均为图片边长的比例）
enum PhraseAvatarCrop {
    static func crop(for avatar: String) -> (cx: CGFloat, cy: CGFloat, size: CGFloat) {
        switch avatar {
        case "boy": return (0.46, 0.21, 0.38)
        case "mother": return (0.50, 0.22, 0.44)
        case "father": return (0.50, 0.24, 0.46)
        default: return (0.5, 0.5, 1.0)
        }
    }
}

// MARK: 音频（一句播完自动接下一句）

@Observable
final class PhraseAudio {
    private let player = AudioPlayer()
    private var token = 0

    /// 播放一句；播完（或文件缺失时约 1.2 秒后）回调 onEnd
    func play(_ line: PhraseProtoLine, onEnd: (() -> Void)? = nil) {
        token += 1
        let my = token
        guard let url = Bundle.main.resourceURL?
            .appendingPathComponent("phrase-audio/\(line.audio)"),
              FileManager.default.fileExists(atPath: url.path) else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                guard self?.token == my else { return }
                onEnd?()
            }
            return
        }
        player.onTimeUpdate = { [weak self] t in
            guard t >= 999999, let self, self.token == my else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard self.token == my else { return }
                onEnd?()
            }
        }
        player.play(url: url)
    }

    func stop() {
        token += 1
        player.onTimeUpdate = nil
        player.stop()
    }
}

// MARK: 根视图

struct PhrasesProtoView: View {
    let layout: String
    @State private var data = PhraseProtoData.load()

    var body: some View {
        NavigationStack {
            Group {
                if let data {
                    switch layout {
                    case "B": PhraseCardLayout(data: data)
                    case "C": PhraseSceneLayout(data: data)
                    default: PhraseChatLayout(data: data)
                    }
                } else {
                    Text("没有找到 phrases-proto.json")
                        .kidFont(17, .bold)
                        .foregroundStyle(Palette.inkMuted)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .creamBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: 公用小部件

/// 圆形头像：从整身词图里裁出脸
struct PhraseAvatar: View {
    @Environment(DataStore.self) private var store
    let avatar: String
    var size: CGFloat = 44
    var active = false

    var body: some View {
        let c = PhraseAvatarCrop.crop(for: avatar)
        let full = size / c.size
        ZStack {
            Circle().fill(Palette.surface)
            if let url = store.iconURL(forWord: avatar),
               let ui = UIImage(contentsOfFile: url.path) {
                Image(uiImage: ui)
                    .resizable()
                    .frame(width: full, height: full)
                    .offset(x: (0.5 - c.cx) * full, y: (0.5 - c.cy) * full)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle().strokeBorder(active ? Func.accent : Palette.hairline,
                                  lineWidth: active ? 3 : 1.5)
        }
        .scaleEffect(active ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: active)
        .accessibilityHidden(true)
    }
}

/// 句子配图；没有图（"I'm full."）时是灰色占位框
struct PhrasePicture: View {
    @Environment(DataStore.self) private var store
    let icon: String?
    var size: CGFloat
    var corner: CGFloat = 12

    var body: some View {
        Group {
            if let icon, let url = store.iconURL(forWord: icon),
               let ui = UIImage(contentsOfFile: url.path) {
                Image(uiImage: ui)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color(red: 0.88, green: 0.88, blue: 0.89)
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .strokeBorder(Color(red: 0.70, green: 0.70, blue: 0.72),
                                      style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// 情景图（找一找的厨房背景）
struct PhraseSceneImage: View {
    let name: String
    var corner: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            Group {
                if let url = Bundle.main.resourceURL?.appendingPathComponent("scenes/\(name)"),
                   let ui = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    Color(red: 0.98, green: 0.92, blue: 0.75)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        }
        .accessibilityHidden(true)
    }
}

/// 页面顶部：场景名 + 可选的「中文」开关
struct PhraseHeader: View {
    let scene: PhraseProtoScene
    let tag: String
    var showZh: Binding<Bool>? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text(scene.title_zh)
                    .kidFont(24, .heavy)
                    .foregroundStyle(Palette.ink)
                Text("\(scene.title_en) · 原型 \(tag)")
                    .kidFont(13, .semibold)
                    .foregroundStyle(Palette.inkMuted)
            }
            Spacer(minLength: 4)
            if let showZh {
                Button {
                    showZh.wrappedValue.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showZh.wrappedValue ? "checkmark.circle.fill" : "circle")
                            .kidFont(15, .bold)
                        Text("中文")
                            .kidFont(15, .bold)
                    }
                    .foregroundStyle(showZh.wrappedValue ? .white : Palette.inkMuted)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 36)
                    .background(showZh.wrappedValue ? Func.positiveDeep : Palette.surface,
                                in: Capsule())
                    .overlay { Capsule().strokeBorder(Palette.hairline, lineWidth: 1) }
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(showZh.wrappedValue ? "隐藏中文" : "显示中文")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
}

/// 句子顺序的小圆点（不显示数字）
struct PhraseDots: View {
    let count: Int
    let current: Int?
    var done: Set<Int> = []
    var size: CGFloat = 10
    var onTap: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: size * 0.9) {
            ForEach(0..<count, id: \.self) { i in
                let isCurrent = current == i
                let isDone = done.contains(i)
                Circle()
                    .fill(isCurrent ? Func.accent : (isDone ? Func.accent.opacity(0.45) : Palette.hairline))
                    .frame(width: isCurrent ? size * 1.5 : size, height: isCurrent ? size * 1.5 : size)
                    .frame(width: size * 2.2, height: size * 2.2)
                    .contentShape(Rectangle())
                    .onTapGesture { onTap?(i) }
                    .animation(.easeOut(duration: 0.2), value: current)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("句子进度")
    }
}

/// 底栏按钮（上图标下文字，三等分）
struct PhraseBarButton: View {
    let icon: String
    let title: String
    var active = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .kidFont(20, .bold, maxScale: 1.15)
                Text(title)
                    .kidFont(14, .bold, maxScale: 1.15)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(active ? .white : Palette.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(active ? Func.infoDeep : Palette.surface,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: active ? 0 : 1)
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(title)
    }
}

// MARK: - A 对话气泡

struct PhraseChatLayout: View {
    let data: PhraseProtoData
    @State private var audio = PhraseAudio()
    @State private var recorder = Recorder()
    @State private var showZh = true
    /// 已经冒出来的气泡数
    @State private var visible = 0
    /// 正在说的那句
    @State private var current: Int? = nil
    @State private var roleMode = false
    /// 角色扮演：轮到孩子说（Tom 的气泡显示 🎤）
    @State private var waitingKid = false
    @State private var runToken = 0

    private var lines: [PhraseProtoLine] { data.scene.lines }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 10) {
                PhraseHeader(scene: data.scene, tag: "A · 对话气泡", showZh: $showZh)

                PhraseSceneImage(name: data.scene.image)
                    .frame(height: geo.size.height * 0.30)
                    .padding(.horizontal, 16)

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(lines.prefix(visible).enumerated()), id: \.element.id) { i, line in
                                bubbleRow(i, line)
                                    .id(line.id)
                                    .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    // 顶部渐隐：滚出去的气泡是「淡出」而不是被一刀切
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                                .frame(height: 16)
                            Color.black
                        }
                    }
                    .onChange(of: current) { _, new in
                        guard let new, lines.indices.contains(new) else { return }
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(lines[new].id, anchor: .bottom)
                        }
                    }
                    .onAppear {
                        if let c = current, lines.indices.contains(c) {
                            DispatchQueue.main.async { proxy.scrollTo(lines[c].id, anchor: .bottom) }
                        }
                    }
                }

                HStack(spacing: 10) {
                    PhraseBarButton(icon: "play.fill", title: "全部播放") {
                        start(role: false)
                    }
                    PhraseBarButton(icon: "theatermasks.fill", title: "我来当 Tom", active: roleMode) {
                        start(role: !roleMode)
                    }
                    PhraseBarButton(icon: "arrow.counterclockwise", title: "再听一遍") {
                        replayCurrent()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .onAppear(perform: setup)
        .onDisappear { audio.stop() }
    }

    @ViewBuilder
    private func bubbleRow(_ i: Int, _ line: PhraseProtoLine) -> some View {
        let ch = data.character(line.speaker)
        let isTom = line.speaker == "tom"
        let isCurrent = current == i
        let kidTurn = isTom && roleMode && waitingKid && isCurrent

        HStack(alignment: .bottom, spacing: 8) {
            if isTom { Spacer(minLength: 36) } else { avatarColumn(ch, active: isCurrent) }

            Group {
                if kidTurn {
                    kidTurnBubble(line)
                } else {
                    bubble(line, isTom: isTom)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Func.accent, lineWidth: isCurrent ? 3 : 0)
            }
            .scaleEffect(isCurrent ? 1.06 : 1.0, anchor: isTom ? .trailing : .leading)
            .animation(.spring(response: 0.28, dampingFraction: 0.45), value: isCurrent)
            .onTapGesture { tapBubble(i) }

            if isTom { avatarColumn(ch, active: isCurrent) } else { Spacer(minLength: 36) }
        }
        .padding(.vertical, isCurrent ? 4 : 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(ch?.name ?? ""): \(line.en)")
    }

    private func avatarColumn(_ ch: PhraseProtoCharacter?, active: Bool) -> some View {
        VStack(spacing: 2) {
            PhraseAvatar(avatar: ch?.avatar ?? "boy", size: 44, active: active)
            Text(ch?.name ?? "")
                .kidFont(11, .bold, maxScale: 1.1)
                .foregroundStyle(Palette.inkMuted)
        }
    }

    private func bubble(_ line: PhraseProtoLine, isTom: Bool) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(line.en)
                    .kidFont(22, .bold)
                    .foregroundStyle(isTom ? Color.white : Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if showZh {
                    Text(line.zh)
                        .kidFont(15, .medium)
                        .foregroundStyle(isTom ? Color.white.opacity(0.9) : Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            PhrasePicture(icon: line.icon, size: 56)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isTom ? Func.infoDeep : Palette.surface,
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Palette.hairline, lineWidth: isTom ? 0 : 1)
        }
    }

    /// 角色扮演：轮到 Tom（孩子）说。显示话筒，点话筒录音，再点结束并回放；点气泡继续
    private func kidTurnBubble(_ line: PhraseProtoLine) -> some View {
        let key = "phrase#\(line.id)"
        return HStack(spacing: 12) {
            Button {
                let wasRecording = recorder.isRecording
                recorder.toggleRecord(for: key)
                if wasRecording { recorder.playBack(for: key) }
            } label: {
                ZStack {
                    Circle().fill(recorder.isRecording ? Func.negativeDeep : Color.white)
                        .frame(width: 56, height: 56)
                    Image(systemName: "mic.fill")
                        .kidFont(26, .bold, maxScale: 1.1)
                        .foregroundStyle(recorder.isRecording ? Color.white : Func.infoDeep)
                }
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("录音")

            VStack(alignment: .leading, spacing: 3) {
                Text("轮到你说啦")
                    .kidFont(20, .heavy)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(line.en)
                    .kidFont(15, .semibold)
                    .foregroundStyle(Color.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Func.infoDeep.opacity(0.85),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [7, 5]))
                .padding(3)
        }
    }

    // MARK: 逻辑

    private func setup() {
        if let step = LaunchOptions.phraseStep {
            // 截图态：停在第 step 句「正在说」，不自动往下走
            let s = min(max(step, 0), lines.count - 1)
            roleMode = LaunchOptions.phraseRole
            visible = s + 1
            current = s
            waitingKid = roleMode && lines[s].speaker == "tom"
            return
        }
        if LaunchOptions.phraseRole {
            start(role: true)
        } else {
            start(role: false)
        }
    }

    private func start(role: Bool) {
        audio.stop()
        runToken += 1
        roleMode = role
        waitingKid = false
        current = nil
        withAnimation { visible = 0 }
        advance(to: 0, token: runToken)
    }

    private func advance(to i: Int, token: Int) {
        guard token == runToken else { return }
        guard lines.indices.contains(i) else {
            current = nil
            waitingKid = false
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            visible = max(visible, i + 1)
            current = i
        }
        let line = lines[i]
        if roleMode && line.speaker == "tom" {
            // 轮到孩子：等 4 秒（或点一下气泡）再继续
            waitingKid = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                guard token == runToken, current == i, waitingKid else { return }
                waitingKid = false
                advance(to: i + 1, token: token)
            }
        } else {
            waitingKid = false
            audio.play(line) { advance(to: i + 1, token: token) }
        }
    }

    private func tapBubble(_ i: Int) {
        if roleMode && waitingKid && current == i {
            waitingKid = false
            advance(to: i + 1, token: runToken)
            return
        }
        // 点任意气泡：只重听这一句，打断自动播放
        runToken += 1
        waitingKid = false
        current = i
        audio.play(lines[i])
    }

    private func replayCurrent() {
        let i = current ?? max(visible - 1, 0)
        guard lines.indices.contains(i) else { return }
        tapBubble(i)
    }
}

// MARK: - B 一句一卡

struct PhraseCardLayout: View {
    let data: PhraseProtoData
    @State private var audio = PhraseAudio()
    @State private var recorder = Recorder()
    @State private var page = 0
    @State private var playing = false
    /// 截图用：假装正在录音（不真的打开麦克风）
    @State private var demoRecording = false
    @State private var frozen = false

    private var lines: [PhraseProtoLine] { data.scene.lines }
    /// 最后多一页放星星庆祝
    private var pageCount: Int { lines.count + 1 }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 6) {
                PhraseHeader(scene: data.scene, tag: "B · 一句一卡")

                PhraseDots(count: lines.count, current: page < lines.count ? page : nil,
                           done: Set(0..<min(page, lines.count)), size: 9) { i in
                    withAnimation { page = i }
                }
                .padding(.top, 2)

                TabView(selection: $page) {
                    ForEach(Array(lines.enumerated()), id: \.element.id) { i, line in
                        card(line, height: geo.size.height, width: geo.size.width)
                            .tag(i)
                    }
                    celebration
                        .tag(lines.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .onAppear(perform: setup)
        .onChange(of: page) { _, new in
            guard !frozen else { return }
            demoRecording = false
            if lines.indices.contains(new) { playLine(new) } else { audio.stop(); playing = false }
        }
        .onDisappear { audio.stop() }
    }

    private func card(_ line: PhraseProtoLine, height: CGFloat, width: CGFloat) -> some View {
        let ch = data.character(line.speaker)
        let key = "phrase#\(line.id)"
        let imageSide = min(height * 0.55, width - 32)
        let recordingNow = demoRecording || recorder.isRecording
        return VStack(spacing: 8) {
            PhrasePicture(icon: line.icon, size: imageSide, corner: 24)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Palette.hairline, lineWidth: 1)
                }
                .onTapGesture { playLine(page) }

            HStack(spacing: 8) {
                PhraseAvatar(avatar: ch?.avatar ?? "boy", size: 34, active: playing)
                Text(ch?.name ?? "")
                    .kidFont(17, .heavy)
                    .foregroundStyle(Palette.inkMuted)
            }
            .padding(.top, 2)

            Text(line.en)
                .kidFont(28, .heavy)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(line.zh)
                .kidFont(17, .medium)
                .foregroundStyle(Palette.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 4)

            HStack(alignment: .center, spacing: 0) {
                sideButton(icon: recordingNow ? "stop.fill" : "mic.fill",
                           title: recordingNow ? "录音中" : "跟读",
                           tint: recordingNow ? Func.negativeDeep : Func.infoDeep,
                           filled: recordingNow) {
                    if demoRecording { demoRecording = false; return }
                    audio.stop(); playing = false
                    recorder.toggleRecord(for: key)
                }
                .frame(maxWidth: .infinity)

                Button { playLine(page) } label: {
                    ZStack {
                        Circle().fill(Func.positiveDeep)
                        Image(systemName: playing ? "speaker.wave.2.fill" : "play.fill")
                            .kidFont(36, .bold, maxScale: 1.1)
                            .foregroundStyle(.white)
                    }
                    .frame(width: 88, height: 88)
                    .overlay {
                        Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 3).padding(3)
                    }
                    .elevationRaised()
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("播放")

                sideButton(icon: "play.circle.fill", title: "我的声音",
                           tint: Func.accentDeep, filled: false,
                           enabled: recorder.hasRecording(for: key)) {
                    audio.stop(); playing = false
                    recorder.playBack(for: key)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 16)
        .overlay(alignment: .top) {
            if recordingNow {
                HStack(spacing: 6) {
                    Circle().fill(Func.negativeDeep).frame(width: 10, height: 10)
                    Text("正在录音… 说完再点一下")
                        .kidFont(15, .bold)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.6), in: Capsule())
                .padding(.top, 12)
            }
        }
    }

    private func sideButton(icon: String, title: String, tint: Color, filled: Bool,
                            enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(filled ? tint : Palette.surface)
                    Image(systemName: icon)
                        .kidFont(24, .bold, maxScale: 1.1)
                        .foregroundStyle(filled ? Color.white : tint)
                }
                .frame(width: 60, height: 60)
                .overlay { Circle().strokeBorder(filled ? Color.clear : Palette.hairline, lineWidth: 1.5) }
                Text(title)
                    .kidFont(14, .bold, maxScale: 1.15)
                    .foregroundStyle(Palette.inkMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .opacity(enabled ? 1 : 0.45)
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
        .accessibilityLabel(title)
    }

    private var celebration: some View {
        VStack(spacing: 18) {
            Spacer()
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .kidFont(i == 1 ? 76 : 56, .bold, maxScale: 1.1)
                        .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.10))
                }
            }
            Text("吃饭啦，全部听完啦！")
                .kidFont(24, .heavy)
                .foregroundStyle(Palette.ink)
            AppButton(title: "再来一遍", icon: "arrow.counterclockwise") {
                withAnimation { page = 0 }
            }
            .frame(maxWidth: 260)
            Spacer()
        }
        .padding()
    }

    private func setup() {
        if let step = LaunchOptions.phraseStep {
            frozen = true
            page = min(max(step, 0), lines.count - 1)
            playing = !LaunchOptions.phraseRecord
            demoRecording = LaunchOptions.phraseRecord
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { frozen = false }
            return
        }
        playLine(page)
    }

    private func playLine(_ i: Int) {
        guard lines.indices.contains(i) else { return }
        playing = true
        audio.play(lines[i]) { playing = false }
    }
}

// MARK: - C 情景图 + 点读

struct PhraseSceneLayout: View {
    let data: PhraseProtoData
    @State private var audio = PhraseAudio()
    /// 正在说的那句
    @State private var current: Int? = nil
    /// 已经听过的句子
    @State private var heard: Set<Int> = []
    @State private var autoRunning = false
    @State private var runToken = 0
    @State private var breathe = false

    private var lines: [PhraseProtoLine] { data.scene.lines }
    /// 三个热点在情景图上的位置（比例坐标，站在厨房地板上）
    private struct Spot: Identifiable {
        let id: String
        let x: CGFloat
        let y: CGFloat
    }
    private let spots: [Spot] = [
        Spot(id: "mom", x: 0.20, y: 0.60), Spot(id: "dad", x: 0.50, y: 0.74), Spot(id: "tom", x: 0.80, y: 0.60),
    ]

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 10) {
                PhraseHeader(scene: data.scene, tag: "C · 情景图点读")

                GeometryReader { img in
                    ZStack {
                        PhraseSceneImage(name: data.scene.image, corner: 22)
                        ForEach(spots) { spot in
                            hotspot(spot.id)
                                .position(x: img.size.width * spot.x, y: img.size.height * spot.y)
                        }
                    }
                }
                .frame(height: geo.size.height * 0.60)
                .padding(.horizontal, 16)

                subtitleBar
                    .padding(.horizontal, 16)

                PhraseDots(count: lines.count, current: current, done: heard, size: 12) { i in
                    say(i)
                }

                Button { autoRunning ? stopAuto() : startAuto() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: autoRunning ? "stop.fill" : "play.rectangle.fill")
                            .kidFont(18, .bold, maxScale: 1.15)
                        Text(autoRunning ? "停一停" : "自动演一遍")
                            .kidFont(18, .heavy, maxScale: 1.15)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .frame(height: 48)
                    .background(Func.infoDeep, in: Capsule())
                }
                .buttonStyle(PressableStyle())
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            setup()
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
        .onDisappear { audio.stop() }
    }

    private func hotspot(_ speaker: String) -> some View {
        let ch = data.character(speaker)
        let speaking = current.map { lines[$0].speaker == speaker } ?? false
        return VStack(spacing: 2) {
            ZStack {
                // 呼吸光圈：提示「这里可以点」
                Circle()
                    .fill(Color(red: 1.0, green: 0.85, blue: 0.30).opacity(breathe ? 0.15 : 0.55))
                    .frame(width: 92, height: 92)
                    .scaleEffect(breathe ? 1.12 : 0.92)
                Circle()
                    .strokeBorder(Color(red: 1.0, green: 0.78, blue: 0.10), lineWidth: 3)
                    .frame(width: 80, height: 80)
                    .scaleEffect(breathe ? 1.08 : 0.96)
                PhraseAvatar(avatar: ch?.avatar ?? "boy", size: 66, active: speaking)
                    .overlay { Circle().strokeBorder(Color.white, lineWidth: 3) }
            }
            .frame(width: 96, height: 96)
            Text(ch?.name ?? "")
                .kidFont(13, .heavy, maxScale: 1.1)
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Palette.surface.opacity(0.9), in: Capsule())
        }
        // 说话气泡浮在头像上方：用 overlay 不占布局，头像不会因为冒气泡而跳位置
        .overlay(alignment: .top) {
            if speaking, let c = current {
                Text(lines[c].en)
                    .kidFont(16, .heavy, maxScale: 1.15)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Func.accent, lineWidth: 2)
                    }
                    .elevationRaised()
                    .offset(y: -40)
                    .transition(.scale(scale: 0.5, anchor: .bottom).combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { tapSpeaker(speaker) }
        .accessibilityElement()
        .accessibilityLabel(ch?.name ?? speaker)
        .accessibilityAddTraits(.isButton)
    }

    private var subtitleBar: some View {
        Group {
            if let c = current {
                let ch = data.character(lines[c].speaker)
                HStack(spacing: 10) {
                    PhraseAvatar(avatar: ch?.avatar ?? "boy", size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lines[c].en)
                            .kidFont(22, .heavy)
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(lines[c].zh)
                            .kidFont(15, .medium)
                            .foregroundStyle(Palette.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "hand.tap.fill")
                        .kidFont(26, .bold, maxScale: 1.1)
                        .foregroundStyle(Func.accent)
                    Text("点一点图里的人，听听他们说什么")
                        .kidFont(17, .bold)
                        .foregroundStyle(Palette.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 66, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Palette.hairline, lineWidth: 1)
        }
    }

    // MARK: 逻辑

    private func setup() {
        guard let step = LaunchOptions.phraseStep else { return }
        // 截图态：前面几句已经点过，第 step 句正在说
        let s = min(max(step, 0), lines.count - 1)
        heard = Set(0...s)
        current = s
    }

    /// 点一个人：播放这个人的「下一句」。
    /// 优先接着整段顺序（轮到他就说那句），否则说他自己还没说过的第一句，都说过就从头轮。
    private func tapSpeaker(_ speaker: String) {
        stopAuto()
        let mine = lines.indices.filter { lines[$0].speaker == speaker }
        guard !mine.isEmpty else { return }
        let nextInOrder = lines.indices.first { !heard.contains($0) }
        let pick: Int
        if let n = nextInOrder, lines[n].speaker == speaker {
            pick = n
        } else if let unheard = mine.first(where: { !heard.contains($0) }) {
            pick = unheard
        } else if let c = current, let pos = mine.firstIndex(of: c) {
            pick = mine[(pos + 1) % mine.count]
        } else {
            pick = mine[0]
        }
        say(pick)
    }

    private func say(_ i: Int, then: (() -> Void)? = nil) {
        guard lines.indices.contains(i) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            current = i
            heard.insert(i)
        }
        audio.play(lines[i]) { then?() }
    }

    private func startAuto() {
        runToken += 1
        autoRunning = true
        heard = []
        step(0, token: runToken)
    }

    private func step(_ i: Int, token: Int) {
        guard token == runToken, autoRunning else { return }
        guard lines.indices.contains(i) else { autoRunning = false; return }
        say(i) { step(i + 1, token: token) }
    }

    private func stopAuto() {
        runToken += 1
        autoRunning = false
    }
}

import SwiftUI

// MARK: - 听音选词
struct AudioToWordGame: View {
    let words: [WordEntry]
    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()
    @State private var quiz: [WordEntry] = []
    @State private var index = 0
    @State private var options: [WordEntry] = []
    @State private var score = 0
    @State private var finished = false
    @State private var picked: String? = nil

    var body: some View {
        VStack(spacing: 24) {
            if finished {
                gameOverView
            } else if let current = quiz[safe: index] {
                Text("听一听，是哪个单词？")
                    .kidFont(34)
                Button {
                    playCurrent()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .kidFont(60)
                        .foregroundStyle(.white)
                        .frame(width: 130, height: 130)
                        .background(Circle().fill(Color.blue))
                }
                Text("\(index + 1) / \(quiz.count)")
                    .kidFont(17, .semibold)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(options, id: \.word) { opt in
                        Button(opt.word) { answer(opt) }
                            .kidFont(28)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(RoundedRectangle(cornerRadius: 18).fill(optionColor(opt)))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .onAppear { start() }
        .blueBackground()
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Text("🎉 得分：\(score) / \(quiz.count)")
                .kidFont(34)
            Button("再来一局") { start() }
                .kidFont(28)
                .padding(.horizontal, 40).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.blue))
                .foregroundStyle(.white)
        }
    }

    private func start() {
        quiz = Array(words.shuffled().prefix(min(10, words.count)))
        index = 0; score = 0; finished = false; picked = nil
        setupOptions()
    }

    private func setupOptions() {
        guard let current = quiz[safe: index] else { return }
        var pool = store.words.filter { $0.word != current.word }.shuffled()
        options = ([current] + Array(pool.prefix(3))).shuffled()
        picked = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { playCurrent() }
    }

    private func playCurrent() {
        guard let current = quiz[safe: index],
              let url = store.bestAudioURL(forWord: current.word) else { return }
        player.play(url: url)
    }

    private func optionColor(_ opt: WordEntry) -> Color {
        guard let p = picked else { return Color.purple.opacity(0.8) }
        if opt.word == quiz[index].word { return Color.green }
        if opt.word == p { return Color.red }
        return Color.gray.opacity(0.4)
    }

    private func answer(_ opt: WordEntry) {
        guard picked == nil else { return }
        picked = opt.word
        if opt.word == quiz[index].word { score += 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if index + 1 < quiz.count { index += 1; setupOptions() }
            else { finished = true }
        }
    }
}

// MARK: - 听音选义
struct AudioToMeaningGame: View {
    let words: [WordEntry]
    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()
    @State private var quiz: [WordEntry] = []
    @State private var index = 0
    @State private var options: [WordEntry] = []
    @State private var score = 0
    @State private var finished = false
    @State private var picked: String? = nil

    var body: some View {
        VStack(spacing: 24) {
            if finished {
                gameOverView
            } else if let current = quiz[safe: index] {
                Text("听一听，是什么意思？")
                    .kidFont(34)
                Button {
                    playCurrent()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .kidFont(60)
                        .foregroundStyle(.white)
                        .frame(width: 130, height: 130)
                        .background(Circle().fill(Color.blue))
                }
                Text("\(index + 1) / \(quiz.count)")
                    .kidFont(17, .semibold)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(options, id: \.word) { opt in
                        Button(opt.meaningCn ?? "") { answer(opt) }
                            .kidFont(22)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(RoundedRectangle(cornerRadius: 18).fill(optionColor(opt)))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .onAppear { start() }
        .blueBackground()
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Text("🎉 得分：\(score) / \(quiz.count)")
                .kidFont(34)
            Button("再来一局") { start() }
                .kidFont(28)
                .padding(.horizontal, 40).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.blue))
                .foregroundStyle(.white)
        }
    }

    private func start() {
        let withCn = words.filter { !($0.meaningCn ?? "").trimmingCharacters(in: .whitespaces).isEmpty }
        quiz = Array(withCn.shuffled().prefix(min(10, withCn.count)))
        index = 0; score = 0; finished = false; picked = nil
        setupOptions()
    }

    private func setupOptions() {
        guard let current = quiz[safe: index] else { return }
        var pool = words.filter { $0.word != current.word && !($0.meaningCn ?? "").isEmpty }.shuffled()
        options = ([current] + Array(pool.prefix(3))).shuffled()
        picked = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { playCurrent() }
    }

    private func playCurrent() {
        guard let current = quiz[safe: index],
              let url = store.bestAudioURL(forWord: current.word) else { return }
        player.play(url: url)
    }

    private func optionColor(_ opt: WordEntry) -> Color {
        guard let p = picked else { return Color.orange.opacity(0.85) }
        if opt.word == quiz[index].word { return Color.green }
        if opt.word == p { return Color.red }
        return Color.gray.opacity(0.4)
    }

    private func answer(_ opt: WordEntry) {
        guard picked == nil else { return }
        picked = opt.word
        if opt.word == quiz[index].word { score += 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if index + 1 < quiz.count { index += 1; setupOptions() }
            else { finished = true }
        }
    }
}

// MARK: - 看词选义
struct WordToMeaningGame: View {
    let words: [WordEntry]
    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()
    @State private var quiz: [WordEntry] = []
    @State private var index = 0
    @State private var options: [WordEntry] = []
    @State private var score = 0
    @State private var finished = false
    @State private var picked: String? = nil

    var body: some View {
        VStack(spacing: 24) {
            if finished {
                gameOverView
            } else if let current = quiz[safe: index] {
                Text(current.word)
                    .kidFont(64, .bold)
                Button {
                    if let url = store.bestAudioURL(forWord: current.word) {
                        player.play(url: url)
                    }
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .kidFont(36)
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(Circle().fill(Color.blue))
                }
                Text("是什么意思？")
                    .kidFont(28)
                Text("\(index + 1) / \(quiz.count)")
                    .kidFont(17, .semibold)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(options, id: \.word) { opt in
                        Button(opt.meaningCn ?? "") { answer(opt) }
                            .kidFont(22)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(RoundedRectangle(cornerRadius: 18).fill(optionColor(opt)))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .onAppear { start() }
        .blueBackground()
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Text("🎉 得分：\(score) / \(quiz.count)")
                .kidFont(34)
            Button("再来一局") { start() }
                .kidFont(28)
                .padding(.horizontal, 40).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.blue))
                .foregroundStyle(.white)
        }
    }

    private func start() {
        let withCn = words.filter { !($0.meaningCn ?? "").trimmingCharacters(in: .whitespaces).isEmpty }
        quiz = Array(withCn.shuffled().prefix(min(10, withCn.count)))
        index = 0; score = 0; finished = false; picked = nil
        setupOptions()
    }

    private func setupOptions() {
        guard let current = quiz[safe: index] else { return }
        let pool = words.filter { $0.word != current.word && !($0.meaningCn ?? "").isEmpty }.shuffled()
        options = ([current] + Array(pool.prefix(3))).shuffled()
        picked = nil
    }

    private func optionColor(_ opt: WordEntry) -> Color {
        guard let p = picked else { return Color.teal.opacity(0.85) }
        if opt.word == quiz[index].word { return Color.green }
        if opt.word == p { return Color.red }
        return Color.gray.opacity(0.4)
    }

    private func answer(_ opt: WordEntry) {
        guard picked == nil else { return }
        picked = opt.word
        if opt.word == quiz[index].word { score += 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if index + 1 < quiz.count { index += 1; setupOptions() }
            else { finished = true }
        }
    }
}

// MARK: - 听写训练
struct DictationGame: View {
    let words: [WordEntry]
    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()
    @State private var quiz: [WordEntry] = []
    @State private var index = 0
    @State private var input = ""
    @State private var score = 0
    @State private var finished = false
    @State private var result: ResultState = .none

    enum ResultState { case none, correct, wrong }

    var body: some View {
        VStack(spacing: 18) {
            if finished {
                gameOverView
            } else if let current = quiz[safe: index] {
                Text("听一听，写出单词")
                    .kidFont(28, .heavy)
                    .foregroundStyle(Palette.ink)

                Button {
                    playCurrent()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .kidFont(52, .bold)
                        .foregroundStyle(.white)
                        .frame(width: 120, height: 120)
                        .background(Circle().fill(Func.infoDeep))
                }
                .buttonStyle(PressableStyle())

                Text("点喇叭可以再听 · \(index + 1)/\(quiz.count)")
                    .kidFont(15, .medium)
                    .foregroundStyle(Palette.inkMuted)

                TextField("输入英文单词", text: $input)
                    .kidFont(28, .bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.ink)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Palette.surface,
                                in: RoundedRectangle(cornerRadius: Radius.thumb, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.thumb, style: .continuous)
                            .strokeBorder(Palette.hairline, lineWidth: 1.5)
                    }
                    .padding(.horizontal, 20)

                switch result {
                case .none:
                    Button {
                        check()
                    } label: {
                        Text("检查")
                            .kidFont(22, .heavy)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Func.positiveDeep,
                                        in: RoundedRectangle(cornerRadius: Radius.pill, style: .continuous))
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.horizontal, 20)
                case .correct:
                    Text("✅ 对啦！")
                        .kidFont(28, .heavy)
                        .foregroundStyle(Func.positiveDeep)
                case .wrong:
                    Text("正确答案是：\(current.word)")
                        .kidFont(22, .bold)
                        .foregroundStyle(Func.negativeDeep)
                    Text("再听听、记住它 💪")
                        .kidFont(15, .medium)
                        .foregroundStyle(Palette.inkMuted)
                }
            }
        }
        .padding()
        .onAppear { start() }
        .blueBackground()
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Text("🎉 得分：\(score) / \(quiz.count)")
                .kidFont(34)
            Button("再来一局") { start() }
                .kidFont(28)
                .padding(.horizontal, 40).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.blue))
                .foregroundStyle(.white)
        }
    }

    private func start() {
        quiz = Array(words.shuffled().prefix(min(10, words.count)))
        index = 0; score = 0; finished = false; result = .none; input = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { playCurrent() }
    }

    private func playCurrent() {
        guard let current = quiz[safe: index],
              let url = store.bestAudioURL(forWord: current.word) else { return }
        player.play(url: url)
    }

    private func check() {
        guard let current = quiz[safe: index] else { return }
        let typed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if typed == current.word.lowercased() {
            score += 1
            result = .correct
        } else {
            result = .wrong
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (result == .correct ? 0.8 : 2.2)) {
            if index + 1 < quiz.count {
                index += 1; input = ""; result = .none
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { playCurrent() }
            } else {
                finished = true
            }
        }
    }
}

// MARK: - 壳
struct ConsolidationView: View {
    @Environment(\.dismiss) private var dismiss
    let words: [WordEntry]
    enum Mode: String, CaseIterable, Identifiable {
        case wordToImage="看词选图", audioToImage="听音选图", matching="配对消除",
             wordToAudio="看词选音", imageToWord="看图选词", audioToWord="听音选词",
             audioToMeaning="听音选义", wordToMeaning="看词选义", dictation="听写训练"
        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .wordToImage: return "game-lookword"
            case .audioToImage: return "game-listenimage"
            case .matching: return "game-match"
            case .wordToAudio: return "game-wordaudio"
            case .imageToWord: return "game-imageword"
            case .audioToWord: return "game-audioword"
            case .audioToMeaning: return "game-audiomeaning"
            case .wordToMeaning: return "game-wordmeaning"
            case .dictation: return "game-dictation"
            }
        }

        /// 难度：1 = 简单，2 = 中等
        var difficultyLevel: Int {
            switch self {
            case .wordToImage, .audioToImage, .wordToAudio, .wordToMeaning:
                return 1
            default:
                return 2
            }
        }

        var difficulty: String {
            difficultyLevel == 1 ? "简单" : "中等"
        }

        /// 难度用点数表达（●●○）—— 颜色留给技能类型，两个维度各有通道，不互相抢
        var difficultyDots: String {
            String(repeating: "●", count: difficultyLevel)
                + String(repeating: "○", count: 3 - difficultyLevel)
        }

        /// 技能类型：颜色编码「练什么」，不是随机分配
        enum Skill {
            case look, listen, match, write
        }

        var skill: Skill {
            switch self {
            case .wordToImage, .wordToAudio, .imageToWord, .wordToMeaning: return .look
            case .audioToImage, .audioToWord, .audioToMeaning: return .listen
            case .matching: return .match
            case .dictation: return .write
            }
        }

        /// 参考图 9 种玩法是 9 个不同色相，不是按技能归成 4 色
        var color: Color {
            switch self {
            case .wordToImage:   return Color(red: 0.36, green: 0.55, blue: 0.94)  // 蓝
            case .audioToImage:  return Color(red: 0.48, green: 0.78, blue: 0.49)  // 绿
            case .matching:      return Color(red: 0.64, green: 0.48, blue: 0.91)  // 紫
            case .wordToAudio:   return Color(red: 1.00, green: 0.62, blue: 0.26)  // 橙
            case .imageToWord:   return Color(red: 1.00, green: 0.56, blue: 0.66)  // 粉
            case .audioToWord:   return Color(red: 0.36, green: 0.78, blue: 0.78)  // 青
            case .audioToMeaning: return Color(red: 1.00, green: 0.82, blue: 0.30) // 黄
            case .wordToMeaning: return Color(red: 1.00, green: 0.36, blue: 0.36)  // 红
            case .dictation:     return Color(red: 0.18, green: 0.36, blue: 0.82)  // 深蓝
            }
        }

        /// 卡片渐变底（参考图是渐变，不是单色）
        var gradient: LinearGradient {
            LinearGradient(colors: [color.opacity(0.88), color.opacity(0.42)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        /// 技能名称（用于分组标题与无障碍标签）
        var skillName: String {
            switch skill {
            case .look: return "看图看词"
            case .listen: return "听音"
            case .match: return "配对"
            case .write: return "书写"
            }
        }
    }
    /// `-uiGame <n>` 截图用：跳过网格直接进某个玩法
    @State private var mode: Mode? = LaunchOptions.startingGameMode

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        Group {
            if let m = mode {
                gameView(for: m)
            } else {
                modeGrid
            }
        }
        .blueBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    /// 系统返回键在英文环境下会显示 “Back”，中文 App 里很突兀 —— 自绘。
    /// 网格页不用整条顶栏（参考图标题是页面第一行），改成左上角浮一个圆形返回。
    private var floatingBack: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .kidFont(17, .bold)
                .foregroundStyle(Palette.ink)
                .frame(width: 38, height: 38)
                .background(Palette.surface.opacity(0.92), in: Circle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("返回")
    }

    // MARK: - 九宫格模式选择

    private var modeGrid: some View {
        ScrollView {
            VStack(spacing: 18) {
                if words.isEmpty {
                    Text("先去背单词吧")
                        .kidFont(22, .heavy)
                        .foregroundStyle(Palette.ink)
                        .padding(40)
                        .whiteCard()
                        .padding()
                } else {
                    // 参考图：标题带 🎮，副标题灰色
                    HStack(spacing: 8) {
                        Text("选个玩法吧！")
                            .kidFont(40, .heavy)
                            .foregroundStyle(Palette.ink)
                        Text("🎮").kidFont(34)
                    }
                    .padding(.top, 8)
                    Text("9 种游戏，越玩越熟")
                        .pageSubtitleStyle()

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Mode.allCases) { m in
                            Button {
                                mode = m
                            } label: {
                                gameModeCard(m)
                            }
                            .buttonStyle(PressableStyle())
                            .accessibilityLabel("\(m.rawValue)，\(m.skillName)，\(m.difficulty)")
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .overlay(alignment: .topLeading) {
            floatingBack
                .padding(.leading, 14)
                .padding(.top, 4)
        }
    }

    /// 玩法卡：参考图是竖长条 + 白圆托底图标 + 难度胶囊标签
    private func gameModeCard(_ m: Mode) -> some View {
        let fg = onFill(m.color)
        return VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Palette.surface)
                    .frame(width: 66, height: 66)
                uiIcon(m.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 42, height: 42)
            }
            .padding(.top, 8)

            Text(m.rawValue)
                .kidFont(18, .bold)
                .foregroundStyle(fg)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // 难度用胶囊标签，不用「●●○」这类符号串
            Text(m.difficulty)
                .kidFont(12, .bold)
                // 胶囊是白底，文字必须用深色。深色卡（听写训练）的 fg 是白色，
                // 沿用 fg 就成了白底白字，难度标签直接消失。
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, 11)
                .frame(height: 21)
                .background(.white.opacity(0.88), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .frame(height: 168)
        .background(m.gradient,
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .elevationGround()
    }

    // MARK: - 游戏页（带返回）

    @ViewBuilder
    private func gameView(for m: Mode) -> some View {
        VStack(spacing: 0) {
            // 游戏内需要一条返回入口（网格页的顶栏已去掉，改为浮层）
            HStack {
                Button {
                    mode = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .kidFont(16, .bold)
                        Text("换游戏")
                            .kidFont(17, .semibold)
                    }
                    .foregroundStyle(Func.infoDeep)
                    .frame(height: 40)
                }
                .buttonStyle(PressableStyle())

                Spacer()

                Text(m.rawValue)
                    .kidFont(17, .bold)
                    .foregroundStyle(Palette.ink)
                Spacer()
                Color.clear.frame(width: 70, height: 1)
            }
            .padding(.horizontal)
            .padding(.bottom, 4)

            // 玩法内容放进滚动容器：这些题目（图片 + 4 个选项）常常比可用高度还高，
            // 之前 VStack 溢出后被垂直居中，头部被顶到状态栏后面、底部选项贴住底栏。
            // 头部留在滚动区之外，切题时位置不会跳。
            ScrollView {
                Group {
                    switch m {
                    case .wordToImage: WordToImageGame(words: words)
                    case .audioToImage: AudioToImageGame(words: words)
                    case .matching: MatchingGame(words: words)
                    case .wordToAudio: WordToAudioGame(words: words)
                    case .imageToWord: ImageToWordGame(words: words)
                    case .audioToWord: AudioToWordGame(words: words)
                    case .audioToMeaning: AudioToMeaningGame(words: words)
                    case .wordToMeaning: WordToMeaningGame(words: words)
                    case .dictation: DictationGame(words: words)
                    }
                }
                .id(m)
            }
        }
    }
}

// MARK: - 数组安全下标
extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

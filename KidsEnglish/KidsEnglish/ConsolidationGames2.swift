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
                    .font(.largeTitle)
                Button {
                    playCurrent()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                        .frame(width: 130, height: 130)
                        .background(Circle().fill(Color.blue))
                }
                Text("\(index + 1) / \(quiz.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(options, id: \.word) { opt in
                        Button(opt.word) { answer(opt) }
                            .font(.title)
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
        .creamBackground()
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Text("🎉 得分：\(score) / \(quiz.count)")
                .font(.largeTitle)
            Button("再来一局") { start() }
                .font(.title)
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
                    .font(.largeTitle)
                Button {
                    playCurrent()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                        .frame(width: 130, height: 130)
                        .background(Circle().fill(Color.blue))
                }
                Text("\(index + 1) / \(quiz.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(options, id: \.word) { opt in
                        Button(opt.meaningCn ?? "") { answer(opt) }
                            .font(.title2)
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
        .creamBackground()
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Text("🎉 得分：\(score) / \(quiz.count)")
                .font(.largeTitle)
            Button("再来一局") { start() }
                .font(.title)
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
                    .font(.system(size: 64, weight: .bold))
                Button {
                    if let url = store.bestAudioURL(forWord: current.word) {
                        player.play(url: url)
                    }
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(Circle().fill(Color.blue))
                }
                Text("是什么意思？")
                    .font(.title)
                Text("\(index + 1) / \(quiz.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(options, id: \.word) { opt in
                        Button(opt.meaningCn ?? "") { answer(opt) }
                            .font(.title2)
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
        .creamBackground()
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Text("🎉 得分：\(score) / \(quiz.count)")
                .font(.largeTitle)
            Button("再来一局") { start() }
                .font(.title)
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
        VStack(spacing: 24) {
            if finished {
                gameOverView
            } else if let current = quiz[safe: index] {
                Text("听一听，写出单词")
                    .font(.largeTitle)
                Button {
                    playCurrent()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                        .frame(width: 130, height: 130)
                        .background(Circle().fill(Color.blue))
                }
                Text("点喇叭可以再听")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("\(index + 1) / \(quiz.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                TextField("输入英文单词", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .font(.title)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 40)
                switch result {
                case .none:
                    Button("检查") { check() }
                        .font(.title)
                        .padding(.horizontal, 50).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.green))
                        .foregroundStyle(.white)
                case .correct:
                    Text("✅ 对啦！")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                case .wrong:
                    Text("正确答案是：\(current.word)")
                        .font(.title)
                        .foregroundStyle(.red)
                    Text("再听听、记住它 💪")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .onAppear { start() }
        .creamBackground()
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Text("🎉 得分：\(score) / \(quiz.count)")
                .font(.largeTitle)
            Button("再来一局") { start() }
                .font(.title)
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

        var color: Color {
            switch skill {
            case .look: return AppTheme.brightBlue   // 看
            case .listen: return AppTheme.green      // 听
            case .match: return AppTheme.purple      // 配对
            case .write: return Color(red: 1.0, green: 0.5, blue: 0.0)  // 写
            }
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
    @State private var mode: Mode? = nil

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        Group {
            if let m = mode {
                gameView(for: m)
            } else {
                modeGrid
            }
        }
        .creamBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) { header }
    }

    /// 系统返回键在英文环境下显示 “Back”，中文 App 里很突兀 —— 自绘
    private var header: some View {
        HStack(spacing: 12) {
            Button {
                if mode == nil { dismiss() } else { mode = nil }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                    Text(mode == nil ? "返回" : "换游戏")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Func.infoDeep)
                .frame(height: 44)
            }
            .buttonStyle(PressableStyle())

            Spacer()

            Text(mode == nil ? "巩固练习" : mode!.rawValue)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Palette.ink)

            Spacer()

            // 与左侧「返回」等宽的占位，保证标题真正居中
            Color.clear.frame(width: 62, height: 1)
        }
        .padding(.horizontal)
        .background(Palette.canvas)
    }

    // MARK: - 九宫格模式选择

    private var modeGrid: some View {
        ScrollView {
            VStack(spacing: 18) {
                if words.isEmpty {
                    Text("先去背单词吧")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Palette.ink)
                        .padding(40)
                        .whiteCard()
                        .padding()
                } else {
                    Text("选个玩法吧")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundStyle(Palette.ink)
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
    }

    /// 玩法卡：颜色按技能类型分族，难度用点数表达 —— 两个维度各有通道
    private func gameModeCard(_ m: Mode) -> some View {
        let fg = onFill(m.color)
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Palette.surface)
                    .frame(width: 60, height: 60)
                uiIcon(m.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 38, height: 38)
            }
            Text(m.rawValue)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(fg)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text("\(m.difficultyDots) \(m.difficulty)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(fg.opacity(0.78))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(m.color, in: RoundedRectangle(cornerRadius: Radius.card))
        .elevationGround()
    }

    // MARK: - 游戏页（带返回）

    @ViewBuilder
    private func gameView(for m: Mode) -> some View {
        VStack(spacing: 0) {
            // 「换游戏」已收进顶部 header，这里不再重复一个灰色胶囊按钮
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

// MARK: - 数组安全下标
extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

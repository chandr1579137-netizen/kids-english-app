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
                    .kidFont(34, maxScale: 1.15)
                Button {
                    playCurrent()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .kidFont(60, maxScale: 1.15)
                        .foregroundStyle(.white)
                        .frame(width: 130, height: 130)
                        .background(Circle().fill(Color.blue))
                }
                Text("\(index + 1) / \(quiz.count)")
                    .kidFont(17, .semibold, maxScale: 1.15)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(options, id: \.word) { opt in
                        Button(opt.word) { answer(opt) }
                            .kidFont(28, maxScale: 1.15)
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
                .kidFont(34, maxScale: 1.15)
            Button("再来一局") { start() }
                .kidFont(28, maxScale: 1.15)
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
        let pool = store.words.filter { $0.word != current.word }.shuffled()
        options = ([current] + Confusables.pickDistractors(from: pool, for: current)).shuffled()
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
                    .kidFont(34, maxScale: 1.15)
                Button {
                    playCurrent()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .kidFont(60, maxScale: 1.15)
                        .foregroundStyle(.white)
                        .frame(width: 130, height: 130)
                        .background(Circle().fill(Color.blue))
                }
                Text("\(index + 1) / \(quiz.count)")
                    .kidFont(17, .semibold, maxScale: 1.15)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(options, id: \.word) { opt in
                        Button(opt.meaningCn ?? "") { answer(opt) }
                            .kidFont(22, maxScale: 1.15)
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
                .kidFont(34, maxScale: 1.15)
            Button("再来一局") { start() }
                .kidFont(28, maxScale: 1.15)
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
        options = ([current] + Confusables.pickDistractors(from: pool, for: current, distinctMeaning: true)).shuffled()
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
                    .kidFont(64, .bold, maxScale: 1.15)
                Button {
                    if let url = store.bestAudioURL(forWord: current.word) {
                        player.play(url: url)
                    }
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .kidFont(36, maxScale: 1.15)
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(Circle().fill(Color.blue))
                }
                Text("是什么意思？")
                    .kidFont(28, maxScale: 1.15)
                Text("\(index + 1) / \(quiz.count)")
                    .kidFont(17, .semibold, maxScale: 1.15)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(options, id: \.word) { opt in
                        Button(opt.meaningCn ?? "") { answer(opt) }
                            .kidFont(22, maxScale: 1.15)
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
                .kidFont(34, maxScale: 1.15)
            Button("再来一局") { start() }
                .kidFont(28, maxScale: 1.15)
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
        options = ([current] + Confusables.pickDistractors(from: pool, for: current, distinctMeaning: true)).shuffled()
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
                    .kidFont(28, .heavy, maxScale: 1.15)
                    .foregroundStyle(Palette.ink)

                Button {
                    playCurrent()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .kidFont(52, .bold, maxScale: 1.15)
                        .foregroundStyle(.white)
                        .frame(width: 120, height: 120)
                        .background(Circle().fill(Func.infoDeep))
                }
                .buttonStyle(PressableStyle())

                Text("点喇叭可以再听 · \(index + 1)/\(quiz.count)")
                    .kidFont(15, .medium, maxScale: 1.15)
                    .foregroundStyle(Palette.inkMuted)

                TextField("输入英文单词", text: $input)
                    .kidFont(28, .bold, maxScale: 1.15)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Palette.ink)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .frame(maxWidth: .infinity)
                    // 用 minHeight 而不是 height：28pt 字号在大字号下会撑到 ~38pt，
                    // 固定 64 会把「输入英文单词」的占位文字上下一齐切掉。
                    .frame(minHeight: 64)
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
                            .kidFont(22, .heavy, maxScale: 1.15)
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
                        .kidFont(28, .heavy, maxScale: 1.15)
                        .foregroundStyle(Func.positiveDeep)
                case .wrong:
                    Text("正确答案是：\(current.word)")
                        .kidFont(22, .bold, maxScale: 1.15)
                        .foregroundStyle(Func.negativeDeep)
                    Text("再听听、记住它 💪")
                        .kidFont(15, .medium, maxScale: 1.15)
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
                .kidFont(34, maxScale: 1.15)
            Button("再来一局") { start() }
                .kidFont(28, maxScale: 1.15)
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
        case findInScene="听音找一找",
             wordToImage="看词选图", audioToImage="听音选图", matching="配对消除",
             wordToAudio="看词选音", imageToWord="看图选词", audioToWord="听音选词",
             audioToMeaning="听音选义", wordToMeaning="看词选义", dictation="听写训练",
             feedAnimal="喂小动物"   // 放在最后：CI 截图的 -uiGame 下标不用重排
        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .findInScene: return "game-findscene"
            case .wordToImage: return "game-lookword"
            case .audioToImage: return "game-listenimage"
            case .matching: return "game-match"
            case .wordToAudio: return "game-wordaudio"
            case .imageToWord: return "game-imageword"
            case .audioToWord: return "game-audioword"
            case .audioToMeaning: return "game-audiomeaning"
            case .wordToMeaning: return "game-wordmeaning"
            case .dictation: return "game-dictation"
            case .feedAnimal: return "game-feedanimal"
            }
        }

        /// 难度：1 = 简单，2 = 中等
        var difficultyLevel: Int {
            switch self {
            case .findInScene, .feedAnimal, .wordToImage, .audioToImage, .wordToAudio, .wordToMeaning:
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
            case .findInScene, .feedAnimal, .audioToImage, .audioToWord, .audioToMeaning: return .listen
            case .matching: return .match
            case .dictation: return .write
            }
        }

        /// 参考图 9 种玩法是 9 个不同色相，不是按技能归成 4 色
        var color: Color {
            switch self {
            case .findInScene:   return Color(red: 0.93, green: 0.45, blue: 0.62)  // 玫红
            case .wordToImage:   return Color(red: 0.36, green: 0.55, blue: 0.94)  // 蓝
            case .audioToImage:  return Color(red: 0.48, green: 0.78, blue: 0.49)  // 绿
            case .matching:      return Color(red: 0.64, green: 0.48, blue: 0.91)  // 紫
            case .wordToAudio:   return Color(red: 1.00, green: 0.62, blue: 0.26)  // 橙
            case .imageToWord:   return Color(red: 1.00, green: 0.56, blue: 0.66)  // 粉
            case .audioToWord:   return Color(red: 0.36, green: 0.78, blue: 0.78)  // 青
            case .audioToMeaning: return Color(red: 1.00, green: 0.82, blue: 0.30) // 黄
            case .wordToMeaning: return Color(red: 1.00, green: 0.36, blue: 0.36)  // 红
            case .dictation:     return Color(red: 0.18, green: 0.36, blue: 0.82)  // 深蓝
            case .feedAnimal:    return Color(red: 0.80, green: 0.56, blue: 0.32)  // 棕
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
                .kidFont(17, .bold, maxScale: 1.15)
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
                        .kidFont(22, .heavy, maxScale: 1.15)
                        .foregroundStyle(Palette.ink)
                        .padding(40)
                        .whiteCard()
                        .padding()
                } else {
                    // 参考图：标题带 🎮，副标题灰色
                    HStack(spacing: 8) {
                        Text("选个玩法吧！")
                            .kidFont(40, .heavy, maxScale: 1.15)
                            .foregroundStyle(Palette.ink)
                        Text("🎮").kidFont(34, maxScale: 1.15)
                    }
                    .padding(.top, 8)
                    Text("\(Mode.allCases.count) 种游戏，越玩越熟")
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
                .kidFont(18, .bold, maxScale: 1.15)
                .foregroundStyle(fg)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // 难度用胶囊标签，不用「●●○」这类符号串
            Text(m.difficulty)
                .kidFont(12, .bold, maxScale: 1.15)
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
        if m == .findInScene {
            // 听音找一找自带顶栏（返回 + 星星），整页是场景面板，不套通用标题和滚动容器
            FindInSceneGame(onBack: { mode = nil })
        } else if m == .feedAnimal {
            // 喂小动物同样自带顶栏，整页是拖放舞台（放进滚动容器会和拖动手势冲突）
            FeedAnimalGame(onBack: { mode = nil })
        } else {
            commonGameView(for: m)
        }
    }

    private func commonGameView(for m: Mode) -> some View {
        VStack(spacing: 0) {
            // 游戏内需要一条返回入口（网格页的顶栏已去掉，改为浮层）
            HStack {
                Button {
                    mode = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .kidFont(16, .bold, maxScale: 1.15)
                        Text("换游戏")
                            .kidFont(17, .semibold, maxScale: 1.15)
                    }
                    .foregroundStyle(Func.infoDeep)
                    .frame(height: 40)
                }
                .buttonStyle(PressableStyle())

                Spacer()

                Text(m.rawValue)
                    .kidFont(17, .bold, maxScale: 1.15)
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
                    case .findInScene, .feedAnimal: EmptyView()
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

// MARK: - 听音找一找

/// 一张场景面板里摆 7–8 个物品（现成词图抠的透明 PNG），App 只用声音问「Where is the duck?」。
/// 点对：物品放大 1.15 倍再弹回、金色光圈、读单词 + 表扬，亮一颗星；
/// 点错：物品左右晃一下，再问一遍。每轮 5 题，没有倒计时，画面上不放中文说明。
/// 摆放规则（台面贴线、墙面只挂能挂的）在 Models.swift 的 SceneLayout，单测见 SceneTests。
struct FindInSceneGame: View {
    var onBack: () -> Void

    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()

    @State private var scenes: [FindScene] = []
    @State private var scene: FindScene?
    @State private var background: UIImage?
    @State private var itemImages: [String: UIImage] = [:]
    @State private var questions: [String] = []
    @State private var index = 0
    @State private var stars = 0
    @State private var finished = false
    @State private var locked = false
    /// 正在「答对」动画中的物品
    @State private var foundWord: String?
    @State private var popped = false
    /// 每个物品被点错的次数，驱动晃动动画
    @State private var shakes: [String: CGFloat] = [:]
    @State private var successTrigger = 0
    @State private var errorTrigger = 0

    static let questionsPerRound = 5
    /// 复数词用 are（和音频 find#where-<word> 一致）
    static let pluralWords: Set<String> = ["shoes", "blocks"]

    static func question(for word: String) -> String {
        pluralWords.contains(word) ? "Where are the \(word)?" : "Where is the \(word)?"
    }

    private static var args: [String] { ProcessInfo.processInfo.arguments }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if let scene {
                if finished {
                    celebration
                } else {
                    // 面板 + 问句条作为一组，在星星行和底栏之间垂直居中；
                    // 两者间距 20pt。屏幕矮时先缩面板（等比，不拉伸），问句条保持原高。
                    Spacer(minLength: 10)
                    VStack(spacing: 20) {
                        panel(scene)
                        promptBar
                            .layoutPriority(2)
                    }
                    Spacer(minLength: 10)
                }
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.canvas.ignoresSafeArea())
        .onAppear(perform: setup)
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.error, trigger: errorTrigger)
    }

    // MARK: 顶栏：返回 + 5 颗星

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .kidFont(20, .bold, maxScale: 1.15)
                    .foregroundStyle(Palette.ink)
                    .frame(width: 48, height: 48)
                    .background(Palette.surface, in: Circle())
                    .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("返回")

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<Self.questionsPerRound, id: \.self) { i in
                    Image(systemName: i < stars ? "star.fill" : "star")
                        .kidFont(26, .bold, maxScale: 1.15)
                        .foregroundStyle(i < stars ? Color(red: 1.0, green: 0.72, blue: 0.10) : Palette.inkSubtle)
                }
            }
            .accessibilityLabel("\(stars) / \(Self.questionsPerRound)")
        }
        .padding(.top, 4)
    }

    // MARK: 场景面板（等比显示，不拉伸）

    private func panel(_ scene: FindScene) -> some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack(alignment: .topLeading) {
                Group {
                    if let background {
                        Image(uiImage: background).resizable()
                    } else {
                        // 背景图缺失时的占位渐变（不影响玩）
                        LinearGradient(colors: [Color(red: 0.74, green: 0.88, blue: 0.98),
                                                Color(red: 0.70, green: 0.86, blue: 0.55)],
                                       startPoint: .top, endPoint: .bottom)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    }
                }
                .frame(width: w, height: h)

                ForEach(SceneLayout.placements(for: scene), id: \.word) { p in
                    item(p, side: p.width * w)
                        .position(x: p.centerX * w, y: p.centerY * h)
                }
            }
        }
        .aspectRatio(scene.aspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .layoutPriority(1)
    }

    private func item(_ p: ScenePlacement, side: CGFloat) -> some View {
        let isFound = foundWord == p.word
        let hit = max(side, 64)   // 可点区域不小于 64pt
        return Button {
            tap(p.word)
        } label: {
            ZStack {
                if isFound {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.85, blue: 0.25).opacity(0.35))
                        .overlay(Circle().strokeBorder(Color(red: 1.0, green: 0.75, blue: 0.10), lineWidth: 5))
                        .shadow(color: Color(red: 1.0, green: 0.80, blue: 0.20).opacity(0.9), radius: 10)
                        .frame(width: side * 1.25, height: side * 1.25)
                }
                itemImage(p.word)
                    .frame(width: side, height: side)
            }
            .frame(width: hit, height: hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isFound && popped ? 1.15 : 1)
        .modifier(FindShakeEffect(animatableData: shakes[p.word] ?? 0))
        .zIndex(isFound ? 1 : 0)
        .accessibilityLabel(p.word)
    }

    @ViewBuilder
    private func itemImage(_ word: String) -> some View {
        if let ui = itemImages[word] {
            Image(uiImage: ui).resizable().scaledToFit()
        } else {
            WordIconView(word: word, size: 60)
        }
    }

    // MARK: 底部提示条：只放英文问句 + 喇叭

    private var promptBar: some View {
        HStack(spacing: 14) {
            Button(action: playQuestion) {
                Image(systemName: "speaker.wave.2.fill")
                    .kidFont(28, .bold, maxScale: 1.15)
                    .foregroundStyle(.white)
                    .frame(width: 66, height: 66)
                    .background(Color(red: 0.98, green: 0.52, blue: 0.08), in: Circle())
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("再听一遍")

            Text("“\(Self.question(for: questions[safe: index] ?? ""))”")
                .kidFont(26, .heavy, maxScale: 1.15)
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }

    // MARK: 庆祝页（无中文）

    private var celebration: some View {
        VStack(spacing: 22) {
            Spacer()
            HStack(spacing: 8) {
                ForEach(0..<Self.questionsPerRound, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .kidFont(44, .bold, maxScale: 1.15)
                        .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.10))
                }
            }
            // 这一轮找到的 5 个物品排成一行，点一下再读一遍
            HStack(spacing: 8) {
                ForEach(questions, id: \.self) { word in
                    Button {
                        if let url = store.bestAudioURL(forWord: word) { player.play(url: url) }
                    } label: {
                        itemImage(word)
                            .frame(width: 54, height: 54)
                            .frame(width: 64, height: 64)
                            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel(word)
                }
            }
            Text("Great job!")
                .kidFont(46, .heavy, maxScale: 1.15)
                .foregroundStyle(Palette.ink)
            HStack(spacing: 28) {
                roundButton("arrow.counterclockwise", color: Color(red: 0.20, green: 0.55, blue: 0.95), label: "再玩一次") {
                    if let scene { startRound(scene) }
                }
                roundButton("arrow.right", color: Color(red: 0.10, green: 0.62, blue: 0.18), label: "换一个场景") {
                    nextScene()
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.scale.combined(with: .opacity))
    }

    private func roundButton(_ symbol: String, color: Color, label: String,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .kidFont(34, .heavy, maxScale: 1.15)
                .foregroundStyle(.white)
                .frame(width: 84, height: 84)
                .background(color, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(label)
    }

    // MARK: 逻辑

    private func setup() {
        guard scenes.isEmpty else { return }
        if let url = Bundle.main.url(forResource: "scenes", withExtension: "json", subdirectory: "scenes"),
           let data = try? Data(contentsOf: url) {
            scenes = SceneCatalog.decode(data)
        }
        let wanted = LaunchOptions.value(for: "-uiScene")
        guard let first = scenes.first(where: { $0.id == wanted }) ?? scenes.randomElement() else { return }
        startRound(first)
    }

    private func load(_ relative: String) -> UIImage? {
        guard let url = Bundle.main.resourceURL?.appendingPathComponent("scenes/\(relative)") else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private func startRound(_ s: FindScene) {
        scene = s
        background = load(s.background)
        var images: [String: UIImage] = [:]
        for item in s.items {
            if let ui = load("items/\(item.word.replacingOccurrences(of: " ", with: "_")).png") {
                images[item.word] = ui
            }
        }
        itemImages = images
        let words = s.items.map(\.word)
        // 截图模式下固定顺序，方便对图；平时随机出 5 题
        let pool = LaunchOptions.isUIScreenshotRun ? words : words.shuffled()
        questions = Array(pool.prefix(Self.questionsPerRound))
        index = 0; stars = 0; locked = false; foundWord = nil; popped = false; shakes = [:]
        finished = false

        if Self.args.contains("-uiSceneDone") {
            stars = Self.questionsPerRound
            finished = true
            return
        }
        if Self.args.contains("-uiSceneFound"), let w = questions.first {
            // 截图：展示「答对了」的样子（金色光圈 + 2 颗星）
            stars = 2; foundWord = w; locked = true
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { playQuestion() }
    }

    private func nextScene() {
        guard !scenes.isEmpty else { return }
        let i = scenes.firstIndex(where: { $0.id == scene?.id }) ?? -1
        startRound(scenes[(i + 1) % scenes.count])
    }

    private func audioURL(_ key: String) -> URL? {
        guard let file = store.audioMap[key] else { return nil }
        return Bundle.main.resourceURL?.appendingPathComponent("audio/\(file)")
    }

    private func playQuestion() {
        guard let word = questions[safe: index],
              let url = audioURL("find#where-\(word)") else { return }
        player.play(url: url)
    }

    private func tap(_ word: String) {
        guard !locked, !finished, let target = questions[safe: index] else { return }
        if word == target {
            locked = true
            stars += 1
            successTrigger += 1
            foundWord = word
            withAnimation(.spring(response: 0.22, dampingFraction: 0.5)) { popped = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { popped = false }
            }
            if let url = store.bestAudioURL(forWord: word) { player.play(url: url) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                if let url = audioURL("find#praise-\(Int.random(in: 1...3))") { player.play(url: url) }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                foundWord = nil
                if index + 1 < questions.count {
                    index += 1
                    locked = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { playQuestion() }
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { finished = true }
                }
            }
        } else {
            errorTrigger += 1
            withAnimation(.linear(duration: 0.45)) { shakes[word, default: 0] += 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { playQuestion() }
        }
    }
}

/// 点错时左右晃：animatableData 每 +1 晃 3 个来回，停在原位
private struct FindShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(animatableData * .pi * 6), y: 0))
    }
}

// MARK: - 喂小动物

/// 喂小动物：动物说 “I want a banana!”，孩子把托盘里对的食物拖到动物身上。
/// 喂对：食物飞进去，动物跳一下说 “Yummy banana!”，点亮一颗星；
/// 喂错：动物轻轻摇头说 “No, thank you!”，食物弹回原位，再说一遍想吃什么；
/// 没拖到动物身上：食物只弹回原位。没有倒计时，玩的过程中不出现中文。
struct FeedAnimalGame: View {
    var onBack: () -> Void

    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()

    @State private var catalog: FeedCatalog?
    @State private var rounds: [FeedRound] = []
    @State private var images: [String: UIImage] = [:]
    @State private var index = 0
    @State private var stars = 0
    @State private var finished = false
    @State private var locked = false

    /// 正在拖的托盘格子（松手弹回 / 飞进动物的动画结束前一直保留，保证它画在最上层）
    @State private var dragging: Int?
    @State private var dragOffset: CGSize = .zero
    /// 喂对了的格子：食物缩小消失
    @State private var eaten: Int?
    /// 顶部台词被临时替换成 “Yummy …!” / “No, thank you!”
    @State private var reply: String?
    @State private var hop = false
    @State private var shake: CGFloat = 0
    @State private var animalFrame: CGRect = .zero
    @State private var slotFrames: [Int: CGRect] = [:]
    @State private var successTrigger = 0
    @State private var errorTrigger = 0

    static let space = "feed-animal"
    private static let ink = Color(red: 0.36, green: 0.24, blue: 0.14)
    private static let orange = Color(red: 0.98, green: 0.52, blue: 0.08)
    private static var args: [String] { ProcessInfo.processInfo.arguments }

    private var round: FeedRound? { rounds[safe: index] }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if finished {
                celebration
            } else if let round {
                // 舞台 + 托盘作为一组垂直居中；屏幕矮时先等比缩舞台，托盘保持原高
                Spacer(minLength: 10)
                VStack(spacing: 20) {
                    stage(round)
                    tray(round)
                        .layoutPriority(2)
                }
                Spacer(minLength: 10)
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.canvas.ignoresSafeArea())
        .coordinateSpace(name: Self.space)
        .overlay { trail.allowsHitTesting(false) }
        .onAppear(perform: setup)
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: errorTrigger)
    }

    // MARK: 顶栏：返回 + 5 颗星

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .kidFont(20, .bold, maxScale: 1.15)
                    .foregroundStyle(Palette.ink)
                    .frame(width: 48, height: 48)
                    .background(Palette.surface, in: Circle())
                    .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
                    .frame(width: 64, height: 64)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("返回")

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<FeedGame.roundsPerGame, id: \.self) { i in
                    Image(systemName: i < stars ? "star.fill" : "star")
                        .kidFont(26, .bold, maxScale: 1.15)
                        .foregroundStyle(i < stars ? Color(red: 1.0, green: 0.72, blue: 0.10) : Palette.inkSubtle)
                }
            }
            .accessibilityLabel("\(stars) / \(FeedGame.roundsPerGame)")
        }
    }

    // MARK: 舞台：台词 + 喇叭 + 动物（等比，不拉伸）

    private func stage(_ round: FeedRound) -> some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let side = min(w * 0.74, h * 0.62)
            ZStack {
                // 还没有专门的「喂动物」背景图：米色墙 + 木色地面的渐变占位
                LinearGradient(colors: [Color(red: 0.98, green: 0.93, blue: 0.82),
                                        Color(red: 0.96, green: 0.89, blue: 0.76)],
                               startPoint: .top, endPoint: .bottom)
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle().fill(Self.ink.opacity(0.55)).frame(height: 2)
                    LinearGradient(colors: [Color(red: 0.92, green: 0.82, blue: 0.62),
                                            Color(red: 0.89, green: 0.78, blue: 0.57)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: h * 0.17)
                }

                animalView(round.pair.animal)
                    .frame(width: side, height: side)
                    .background(FeedFrameReader { animalFrame = $0 })
                    .scaleEffect(hop ? 1.08 : 1, anchor: .bottom)
                    .offset(y: hop ? -22 : 0)
                    .modifier(FindShakeEffect(animatableData: shake))
                    .position(x: w / 2, y: h * 0.93 - side / 2)
                    .accessibilityLabel(round.pair.animal)

                lineBar(round)
                    .frame(width: w)
                    .position(x: w / 2, y: 52)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Self.ink, lineWidth: 3))
        }
        .aspectRatio(0.88, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .layoutPriority(1)
    }

    private func lineBar(_ round: FeedRound) -> some View {
        let text = reply ?? round.pair.want
        let color: Color = reply == nil ? Color(red: 0.13, green: 0.20, blue: 0.47)
            : (reply == catalog?.noThanks ? Color(red: 0.62, green: 0.38, blue: 0.16)
                                          : Color(red: 0.12, green: 0.52, blue: 0.20))
        return HStack(spacing: 10) {
            Text("“\(text)”")
                .kidFont(28, .heavy, maxScale: 1.15)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .contentTransition(.opacity)
            Spacer(minLength: 0)
            Button(action: playWant) {
                Image(systemName: "speaker.wave.2.fill")
                    .kidFont(26, .bold, maxScale: 1.15)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Self.orange, in: Circle())
                    .padding(4)
                    .background(Palette.surface, in: Circle())
                    .overlay(Circle().strokeBorder(Self.ink, lineWidth: 2.5))
                    .frame(width: 66, height: 66)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("再听一遍")
        }
        .padding(.leading, 22)
        .padding(.trailing, 14)
    }

    // MARK: 托盘：3 个食物格子（每格 ≥ 64pt）

    private func tray(_ round: FeedRound) -> some View {
        HStack(spacing: 14) {
            ForEach(Array(round.options.enumerated()), id: \.offset) { i, food in
                slot(i, food: food)
                    .zIndex(dragging == i ? 10 : 0)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        .zIndex(5)
    }

    private func slot(_ i: Int, food: String) -> some View {
        let lifted = dragging == i
        let gone = eaten == i
        return ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.99, green: 0.97, blue: 0.93))
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color(red: 0.80, green: 0.75, blue: 0.68),
                              style: lifted ? StrokeStyle(lineWidth: 3, dash: [8, 6]) : StrokeStyle(lineWidth: 1.5))
            foodView(food)
                .frame(width: 84, height: 84)
                .scaleEffect(gone ? 0.2 : (lifted ? 1.15 : 1))
                .opacity(gone ? 0 : 1)
                .shadow(color: .black.opacity(lifted ? 0.22 : 0), radius: 8, y: 6)
                .offset(lifted ? dragOffset : .zero)
        }
        .frame(width: 104, height: 104)
        .frame(maxWidth: .infinity)
        .background(FeedFrameReader { slotFrames[i] = $0 })
        .contentShape(Rectangle())
        .gesture(dragGesture(i, food: food))
        .accessibilityLabel(food)
        .accessibilityAddTraits(.isButton)
    }

    /// 拖动时从格子到手指的一条橙色虚线（和示意图一样），帮孩子看清「拿起来了」
    @ViewBuilder
    private var trail: some View {
        if let i = dragging, eaten == nil, let from = slotFrames[i], dragOffset != .zero {
            let start = CGPoint(x: from.midX, y: from.midY)
            let end = CGPoint(x: start.x + dragOffset.width, y: start.y + dragOffset.height)
            let len = hypot(end.x - start.x, end.y - start.y)
            if len > 60 {
                let k = (len - 54) / len   // 线停在食物边上，不压住食物
                Path { p in
                    p.move(to: start)
                    p.addLine(to: CGPoint(x: start.x + (end.x - start.x) * k, y: start.y + (end.y - start.y) * k))
                }
                .stroke(Self.orange, style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [2, 12]))
            }
        }
    }

    @ViewBuilder
    private func animalView(_ word: String) -> some View {
        if let ui = images[word] {
            Image(uiImage: ui).resizable().scaledToFit()
        } else {
            WordIconView(word: word, size: 160)
        }
    }

    @ViewBuilder
    private func foodView(_ word: String) -> some View {
        if let ui = images[word] {
            Image(uiImage: ui).resizable().scaledToFit()
        } else {
            WordIconView(word: word, size: 76)
        }
    }

    // MARK: 完成页（无中文）

    private var celebration: some View {
        VStack(spacing: 22) {
            Spacer()
            HStack(spacing: 8) {
                ForEach(0..<FeedGame.roundsPerGame, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .kidFont(44, .bold, maxScale: 1.15)
                        .foregroundStyle(Color(red: 1.0, green: 0.72, blue: 0.10))
                }
            }
            // 这一轮喂饱的 5 只动物，点一下读单词
            HStack(spacing: 8) {
                ForEach(rounds, id: \.pair.animal) { r in
                    Button {
                        if let url = store.bestAudioURL(forWord: r.pair.animal) { player.play(url: url) }
                    } label: {
                        animalView(r.pair.animal)
                            .frame(width: 54, height: 54)
                            .frame(width: 64, height: 64)
                            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableStyle())
                    .accessibilityLabel(r.pair.animal)
                }
            }
            Text("Great job!")
                .kidFont(46, .heavy, maxScale: 1.15)
                .foregroundStyle(Palette.ink)
            HStack(spacing: 28) {
                roundButton("arrow.counterclockwise", color: Color(red: 0.20, green: 0.55, blue: 0.95), label: "再玩一次") {
                    newGame()
                }
                roundButton("checkmark", color: Color(red: 0.10, green: 0.62, blue: 0.18), label: "完成", action: onBack)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .transition(.scale.combined(with: .opacity))
    }

    private func roundButton(_ symbol: String, color: Color, label: String,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .kidFont(34, .heavy, maxScale: 1.15)
                .foregroundStyle(.white)
                .frame(width: 84, height: 84)
                .background(color, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(label)
    }

    // MARK: 逻辑

    private func setup() {
        guard catalog == nil else { return }
        guard let url = Bundle.main.url(forResource: "feed-pairs", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let c = FeedCatalog.decode(data) else { return }
        catalog = c
        var loaded: [String: UIImage] = [:]
        for p in c.pairs {
            for w in [p.animal, p.food] where loaded[w] == nil {
                if let u = Bundle.main.resourceURL?.appendingPathComponent("scenes/feed/\(w).png"),
                   let ui = UIImage(contentsOfFile: u.path) {
                    loaded[w] = ui
                }
            }
        }
        images = loaded
        newGame()
    }

    private func newGame() {
        guard let catalog else { return }
        if LaunchOptions.isUIScreenshotRun {
            // 截图：固定从 monkey 开始、选项顺序固定，方便对图
            var rng = SeededGenerator(seed: 7)
            rounds = FeedGame.makeRounds(catalog.pairs, shuffleAnimals: false, using: &rng)
        } else {
            rounds = FeedGame.makeRounds(catalog.pairs)
        }
        index = 0; stars = 0; locked = false; eaten = nil; dragging = nil
        dragOffset = .zero; reply = nil; hop = false
        withAnimation { finished = false }

        if Self.args.contains("-uiFeedDone") {
            stars = FeedGame.roundsPerGame; finished = true
            return
        }
        if Self.args.contains("-uiFeedDrag") || Self.args.contains("-uiFeedYummy") || Self.args.contains("-uiFeedNo") {
            locked = true
            // 等舞台和托盘量好位置再摆出截图状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { stageScreenshot() }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { playWant() }
    }

    private func stageScreenshot() {
        guard let round, let ci = round.correctIndex, let from = slotFrames[ci] else { return }
        let to = CGSize(width: animalFrame.midX - from.midX, height: animalFrame.midY - from.midY)
        if Self.args.contains("-uiFeedDrag") {
            dragging = ci
            dragOffset = CGSize(width: to.width * 0.6, height: to.height * 0.6)
        } else if Self.args.contains("-uiFeedYummy") {
            stars = 1; dragging = ci; dragOffset = to; eaten = ci
            reply = round.pair.yummy
        } else if Self.args.contains("-uiFeedNo") {
            reply = catalog?.noThanks
        }
    }

    private func audioURL(_ key: String) -> URL? {
        guard let file = store.audioMap[key] else { return nil }
        return Bundle.main.resourceURL?.appendingPathComponent("audio/\(file)")
    }

    private func playWant() {
        guard let food = round?.pair.food, let url = audioURL(FeedGame.wantKey(food)) else { return }
        player.play(url: url)
    }

    private func dragGesture(_ i: Int, food: String) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named(Self.space))
            .onChanged { v in
                guard !locked, dragging == nil || dragging == i else { return }
                dragging = i
                dragOffset = v.translation
            }
            .onEnded { v in
                guard !locked, dragging == i, let round else { return }
                drop(i, food: food, at: v.location, round: round)
            }
    }

    private func springBack(_ i: Int) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { dragOffset = .zero }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            if dragging == i && dragOffset == .zero { dragging = nil }
        }
    }

    private func drop(_ i: Int, food: String, at point: CGPoint, round: FeedRound) {
        switch FeedGame.outcome(dropping: food, at: point, round: round, animalFrame: animalFrame) {
        case .missed:
            springBack(i)

        case .refused:
            locked = true
            errorTrigger += 1
            springBack(i)
            withAnimation(.linear(duration: 0.6)) { shake += 1 }
            withAnimation { reply = catalog?.noThanks }
            if let url = audioURL(FeedGame.noThanksKey) { player.play(url: url) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation { reply = nil }
                locked = false
                playWant()
            }

        case .eaten:
            locked = true
            successTrigger += 1
            let from = slotFrames[i] ?? .zero
            let to = CGSize(width: animalFrame.midX - from.midX, height: animalFrame.midY - from.midY)
            withAnimation(.easeIn(duration: 0.3)) { dragOffset = to; eaten = i }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                stars += 1
                withAnimation { reply = round.pair.yummy }
                withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) { hop = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { hop = false }
                }
                if let url = audioURL(FeedGame.yummyKey(round.pair.food)) { player.play(url: url) }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                eaten = nil; dragging = nil; dragOffset = .zero; reply = nil
                if index + 1 < rounds.count {
                    index += 1
                    locked = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { playWant() }
                } else {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { finished = true }
                }
            }
        }
    }
}

/// 量出某个视图在「喂小动物」坐标系里的位置（判定是否拖到了动物身上用）
private struct FeedFrameReader: View {
    let onChange: (CGRect) -> Void
    var body: some View {
        GeometryReader { g in
            let f = g.frame(in: .named(FeedAnimalGame.space))
            Color.clear
                .onAppear { onChange(f) }
                .onChange(of: f) { _, new in onChange(new) }
        }
    }
}

// MARK: - 数组安全下标
extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

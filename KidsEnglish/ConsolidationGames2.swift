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

        var difficulty: String {
            switch self {
            case .wordToImage, .audioToImage, .wordToAudio, .wordToMeaning:
                return "简单"
            default:
                return "中等"
            }
        }

        var color: Color {
            switch self {
            case .wordToImage: return Color(red: 0.36, green: 0.61, blue: 1.0)   // 蓝
            case .audioToImage: return Color(red: 0.49, green: 0.83, blue: 0.57) // 绿
            case .matching: return Color(red: 0.70, green: 0.53, blue: 1.0)      // 紫
            case .wordToAudio: return Color(red: 1.0, green: 0.72, blue: 0.30)   // 橙
            case .imageToWord: return Color(red: 0.96, green: 0.56, blue: 0.69)  // 粉
            case .audioToWord: return Color(red: 0.30, green: 0.82, blue: 0.88)  // 青
            case .audioToMeaning: return Color(red: 1.0, green: 0.84, blue: 0.31)// 黄
            case .wordToMeaning: return Color(red: 1.0, green: 0.54, blue: 0.50) // 红
            case .dictation: return Color(red: 0.24, green: 0.35, blue: 1.0)    // 深蓝
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
        .navigationTitle(mode == nil ? "巩固练习" : mode!.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 九宫格模式选择

    private var modeGrid: some View {
        ScrollView {
            VStack(spacing: 18) {
                if words.isEmpty {
                    Text("先去背单词吧 📚")
                        .font(.title.bold())
                        .foregroundColor(AppTheme.navy)
                        .padding(40)
                        .whiteCard()
                        .padding()
                } else {
                    Text("选个玩法吧！🎮")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(AppTheme.navy)
                        .padding(.top, 8)
                    Text("9种游戏，越玩越熟")
                        .font(.title3)
                        .foregroundColor(.gray)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Mode.allCases) { m in
                            Button {
                                mode = m
                            } label: {
                                VStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 76, height: 76)
                                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                                        uiIcon(m.iconName)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 44, height: 44)
                                    }
                                    Text(m.rawValue)
                                        .font(.headline.bold())
                                        .foregroundColor(AppTheme.navy)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    Text(m.difficulty)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 4)
                                        .background(m.color)
                                        .cornerRadius(12)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(m.color.opacity(0.35))
                                .cornerRadius(20)
                                .shadow(color: m.color.opacity(0.25), radius: 8, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - 游戏页（带返回）

    @ViewBuilder
    private func gameView(for m: Mode) -> some View {
        VStack(spacing: 0) {
            Button {
                mode = nil
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                    Text("换游戏")
                        .font(.headline.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.6))
                .cornerRadius(18)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 8)

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

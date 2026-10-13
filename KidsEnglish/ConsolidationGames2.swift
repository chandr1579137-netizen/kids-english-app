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
    }
    @State private var mode: Mode = .wordToImage

    var body: some View {
        VStack {
            if words.isEmpty {
                Spacer()
                Text("先去背单词吧 📚")
                    .font(.largeTitle)
                Spacer()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Mode.allCases) { m in
                            Button(m.rawValue) { mode = m }
                                .font(.title3)
                                .padding(.horizontal, 18).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 16)
                                    .fill(mode == m ? Color.blue : Color.gray.opacity(0.2)))
                                .foregroundStyle(mode == m ? .white : .primary)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                Group {
                    switch mode {
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
                .id(mode)
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

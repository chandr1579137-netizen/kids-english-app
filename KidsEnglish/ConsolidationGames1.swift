import SwiftUI

// MARK: - 共享小组件（仅本文件内部使用）

/// 抖动效果：点错时卡片左右抖一下
private struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    var amount: CGFloat = 10
    var shakesPerUnit: CGFloat = 3

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * shakesPerUnit),
                y: 0
            )
        )
    }
}

/// 大喇叭按钮：点读发音
private struct SpeakerButton: View {
    var size: CGFloat = 90
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "speaker.wave.2.fill")
                .kidFont(size * 0.45, maxScale: 1.15)
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.orange))
                .shadow(radius: 4)
        }
        .buttonStyle(.plain)
    }
}

/// 答对/答错时的边框颜色
private enum AnswerState {
    case none
    case correct
    case wrong
}

private func borderColor(for state: AnswerState) -> Color {
    switch state {
    case .none: return Color.gray.opacity(0.25)
    case .correct: return Color.green
    case .wrong: return Color.red
    }
}

// MARK: - 1. 看词选图 WordToImageGame

struct WordToImageGame: View {
    let words: [WordEntry]

    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()

    @State private var questions: [WordEntry] = []
    @State private var index: Int = 0
    @State private var score: Int = 0
    @State private var options: [WordEntry] = []
    @State private var correctIndex: Int? = nil
    @State private var pickedState: [Int: AnswerState] = [:]
    @State private var shakeCount: Int = 0
    @State private var answered: Bool = false
    @State private var finished: Bool = false
    @State private var successTrigger: Int = 0
    @State private var errorTrigger: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            if finished {
                resultView
            } else if questions.isEmpty {
                ProgressView("准备题目中…")
            } else {
                gameView
            }
        }
        .padding()
        .navigationTitle("看词选图")
        .onAppear { startNewGame() }
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.error, trigger: errorTrigger)
    }

    private var gameView: some View {
        VStack(spacing: 24) {
            Text("第 \(index + 1) / \(questions.count) 题  ·  得分 \(score)")
                .kidFont(17, .semibold, maxScale: 1.15)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Text(questions[index].word)
                    .kidFont(64, .bold, maxScale: 1.15)
                    .foregroundColor(.primary)
                SpeakerButton(size: 76) { playWord(questions[index]) }
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(options.indices, id: \.self) { i in
                    let state = pickedState[i] ?? .none
                    Button {
                        tapOption(i)
                    } label: {
                        WordIconView(word: options[i].word, size: 130)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(radius: 3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(borderColor(for: state), lineWidth: state == .none ? 2 : 6)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(answered)
                    .modifier(ShakeEffect(animatableData: CGFloat(shakeCount)))
                    .opacity(answered && state == .none ? 0.6 : 1.0)
                }
            }
            Spacer()
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🎉")
                .kidFont(90, maxScale: 1.15)
            Text("得了 \(score) 分！")
                .kidFont(40, .bold, maxScale: 1.15)
            Button("再来一局") {
                startNewGame()
            }
            .kidFont(28, .bold, maxScale: 1.15)
            .foregroundColor(.white)
            .padding(.horizontal, 48)
            .padding(.vertical, 18)
            .background(Capsule().fill(Color.green))
            Spacer()
        }
    }

    private func startNewGame() {
        questions = Array(words.shuffled().prefix(min(10, words.count)))
        index = 0
        score = 0
        finished = false
        answered = false
        setupQuestion()
    }

    private func setupQuestion() {
        guard index < questions.count else { return }
        let target = questions[index]
        let distractors = store.words
            .filter { $0.word != target.word }
            .shuffled()
            .prefix(3)
        options = ([target] + Array(distractors)).shuffled()
        correctIndex = options.firstIndex(where: { $0.word == target.word })
        pickedState = [:]
        answered = false
        // 自动读一遍题目
        playWord(target)
    }

    private func tapOption(_ i: Int) {
        guard !answered else { return }
        if i == correctIndex {
            pickedState[i] = .correct
            answered = true
            score += 1
            successTrigger += 1
            advance()
        } else {
            pickedState[i] = .wrong
            errorTrigger += 1
            withAnimation(.default) { shakeCount += 1 }
        }
    }

    private func advance() {
        let current = index
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run {
                guard index == current, !finished else { return }
                if index + 1 < questions.count {
                    index += 1
                    setupQuestion()
                } else {
                    finished = true
                }
            }
        }
    }

    private func playWord(_ w: WordEntry) {
        if let url = store.bestAudioURL(forWord: w.word) {
            player.play(url: url)
        }
    }
}

// MARK: - 2. 听音选图 AudioToImageGame

struct AudioToImageGame: View {
    let words: [WordEntry]

    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()

    @State private var questions: [WordEntry] = []
    @State private var index: Int = 0
    @State private var score: Int = 0
    @State private var options: [WordEntry] = []
    @State private var correctIndex: Int? = nil
    @State private var pickedState: [Int: AnswerState] = [:]
    @State private var shakeCount: Int = 0
    @State private var answered: Bool = false
    @State private var finished: Bool = false
    @State private var successTrigger: Int = 0
    @State private var errorTrigger: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            if finished {
                resultView
            } else if questions.isEmpty {
                ProgressView("准备题目中…")
            } else {
                gameView
            }
        }
        .padding()
        .navigationTitle("听音选图")
        .onAppear { startNewGame() }
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.error, trigger: errorTrigger)
    }

    private var gameView: some View {
        VStack(spacing: 24) {
            Text("第 \(index + 1) / \(questions.count) 题  ·  得分 \(score)")
                .kidFont(17, .semibold, maxScale: 1.15)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                Text("听一听，选出对应的图片 👂")
                    .kidFont(26, .semibold, maxScale: 1.15)
                SpeakerButton(size: 110) { playWord(questions[index]) }
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 16
            ) {
                ForEach(options.indices, id: \.self) { i in
                    let state = pickedState[i] ?? .none
                    Button {
                        tapOption(i)
                    } label: {
                        WordIconView(word: options[i].word, size: 130)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(radius: 3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(borderColor(for: state), lineWidth: state == .none ? 2 : 6)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(answered)
                    .modifier(ShakeEffect(animatableData: CGFloat(shakeCount)))
                    .opacity(answered && state == .none ? 0.6 : 1.0)
                }
            }
            Spacer()
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🎉")
                .kidFont(90, maxScale: 1.15)
            Text("得了 \(score) 分！")
                .kidFont(40, .bold, maxScale: 1.15)
            Button("再来一局") {
                startNewGame()
            }
            .kidFont(28, .bold, maxScale: 1.15)
            .foregroundColor(.white)
            .padding(.horizontal, 48)
            .padding(.vertical, 18)
            .background(Capsule().fill(Color.green))
            Spacer()
        }
    }

    private func startNewGame() {
        questions = Array(words.shuffled().prefix(min(10, words.count)))
        index = 0
        score = 0
        finished = false
        answered = false
        setupQuestion()
    }

    private func setupQuestion() {
        guard index < questions.count else { return }
        let target = questions[index]
        let distractors = store.words
            .filter { $0.word != target.word }
            .shuffled()
            .prefix(3)
        options = ([target] + Array(distractors)).shuffled()
        correctIndex = options.firstIndex(where: { $0.word == target.word })
        pickedState = [:]
        answered = false
        // 出现自动播放一次
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            await MainActor.run { playWord(target) }
        }
    }

    private func tapOption(_ i: Int) {
        guard !answered else { return }
        if i == correctIndex {
            pickedState[i] = .correct
            answered = true
            score += 1
            successTrigger += 1
            advance()
        } else {
            pickedState[i] = .wrong
            errorTrigger += 1
            withAnimation(.default) { shakeCount += 1 }
        }
    }

    private func advance() {
        let current = index
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run {
                guard index == current, !finished else { return }
                if index + 1 < questions.count {
                    index += 1
                    setupQuestion()
                } else {
                    finished = true
                }
            }
        }
    }

    private func playWord(_ w: WordEntry) {
        if let url = store.bestAudioURL(forWord: w.word) {
            player.play(url: url)
        }
    }
}

// MARK: - 3. 配对消除 MatchingGame

struct MatchingGame: View {
    let words: [WordEntry]

    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()

    private struct Card: Identifiable {
        let id: Int
        let word: String
        let isImage: Bool
    }

    @State private var cards: [Card] = []
    @State private var selectedIds: [Int] = []
    @State private var matchedIds: Set<Int> = []
    @State private var wrongIds: Set<Int> = []
    @State private var busy: Bool = false
    @State private var score: Int = 0
    @State private var finished: Bool = false
    @State private var successTrigger: Int = 0
    @State private var errorTrigger: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            if finished {
                resultView
            } else if cards.isEmpty {
                ProgressView("准备题目中…")
            } else {
                gameView
            }
        }
        .padding()
        .navigationTitle("配对消除")
        .onAppear { startNewGame() }
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.error, trigger: errorTrigger)
    }

    private var gameView: some View {
        VStack(spacing: 16) {
            Text("找到单词和图片的一对，消灭它们！ · 得分 \(score)")
                .kidFont(17, .semibold, maxScale: 1.15)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                spacing: 12
            ) {
                ForEach(cards) { card in
                    let isSelected = selectedIds.contains(card.id)
                    let isMatched = matchedIds.contains(card.id)
                    let isWrong = wrongIds.contains(card.id)

                    Button {
                        tapCard(card)
                    } label: {
                        ZStack {
                            if card.isImage {
                                WordIconView(word: card.word, size: 72)
                            } else {
                                Text(card.word)
                                    .kidFont(24, .bold, maxScale: 1.15)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 118)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(radius: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isMatched ? Color.green :
                                        (isWrong ? Color.red :
                                            (isSelected ? Color.orange : Color.gray.opacity(0.25))),
                                    lineWidth: (isMatched || isWrong || isSelected) ? 5 : 2
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(busy || isMatched)
                    .opacity(isMatched ? 0 : 1)
                    .scaleEffect(isMatched ? 0.6 : 1.0)
                    .animation(.easeOut(duration: 0.35), value: isMatched)
                }
            }
            Spacer()
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🎉🎉🎉")
                .kidFont(90, maxScale: 1.15)
            Text("全部消灭啦！")
                .kidFont(36, .bold, maxScale: 1.15)
            Text("得了 \(score) 分！")
                .kidFont(30, maxScale: 1.15)
                .foregroundColor(.secondary)
            Button("再来一局") {
                startNewGame()
            }
            .kidFont(28, .bold, maxScale: 1.15)
            .foregroundColor(.white)
            .padding(.horizontal, 48)
            .padding(.vertical, 18)
            .background(Capsule().fill(Color.green))
            Spacer()
        }
    }

    private func startNewGame() {
        // 6 对 = 12 张卡，3 列 × 4 行铺满屏幕；4 对只占两行，下半屏全空
        let pairs = Array(words.shuffled().prefix(min(6, words.count)))
        var list: [Card] = []
        for (i, w) in pairs.enumerated() {
            list.append(Card(id: i * 2, word: w.word, isImage: false))
            list.append(Card(id: i * 2 + 1, word: w.word, isImage: true))
        }
        cards = list.shuffled()
        selectedIds = []
        matchedIds = []
        wrongIds = []
        busy = false
        score = 0
        finished = false
    }

    private func tapCard(_ card: Card) {
        guard !busy, !matchedIds.contains(card.id),
              !selectedIds.contains(card.id) else { return }

        if selectedIds.count == 1, let firstId = selectedIds.first,
           let first = cards.first(where: { $0.id == firstId }) {
            // 第二张
            if first.word == card.word && first.isImage != card.isImage {
                // 配对成功：淡出消除
                selectedIds.append(card.id)
                busy = true
                score += 1
                successTrigger += 1
                playWord(card.word)
                let ids = [first.id, card.id]
                Task {
                    try? await Task.sleep(nanoseconds: 450_000_000)
                    await MainActor.run {
                        withAnimation { matchedIds.formUnion(ids) }
                        selectedIds = []
                        busy = false
                        if matchedIds.count == cards.count {
                            finished = true
                        }
                    }
                }
            } else {
                // 配对失败：翻回
                selectedIds.append(card.id)
                busy = true
                wrongIds = [first.id, card.id]
                errorTrigger += 1
                Task {
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    await MainActor.run {
                        selectedIds = []
                        wrongIds = []
                        busy = false
                    }
                }
            }
        } else {
            selectedIds = [card.id]
            playWord(card.word)
        }
    }

    private func playWord(_ word: String) {
        if let url = store.bestAudioURL(forWord: word) {
            player.play(url: url)
        }
    }
}

// MARK: - 4. 看词选音 WordToAudioGame

struct WordToAudioGame: View {
    let words: [WordEntry]

    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()

    @State private var questions: [WordEntry] = []
    @State private var index: Int = 0
    @State private var score: Int = 0
    @State private var options: [WordEntry] = []
    @State private var correctIndex: Int? = nil
    @State private var pickedState: [Int: AnswerState] = [:]
    @State private var answered: Bool = false
    @State private var finished: Bool = false
    @State private var successTrigger: Int = 0
    @State private var errorTrigger: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            if finished {
                resultView
            } else if questions.isEmpty {
                ProgressView("准备题目中…")
            } else {
                gameView
            }
        }
        .padding()
        .navigationTitle("看词选音")
        .onAppear { startNewGame() }
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.error, trigger: errorTrigger)
    }

    private var gameView: some View {
        VStack(spacing: 24) {
            Text("第 \(index + 1) / \(questions.count) 题  ·  得分 \(score)")
                .kidFont(17, .semibold, maxScale: 1.15)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text(questions[index].word)
                    .kidFont(64, .bold, maxScale: 1.15)
                Text("点喇叭听一听，选出正确的发音 🔊")
                    .kidFont(22, maxScale: 1.15)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 16) {
                ForEach(options.indices, id: \.self) { i in
                    let state = pickedState[i] ?? .none
                    Button {
                        tapOption(i)
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "speaker.wave.2.fill")
                                .kidFont(34, maxScale: 1.15)
                                .foregroundColor(.white)
                                .frame(width: 64, height: 64)
                                .background(Circle().fill(state == .correct ? Color.green : Color.orange))
                            Text("发音 \(i + 1)")
                                .kidFont(26, .semibold, maxScale: 1.15)
                            Spacer()
                            if state == .correct {
                                Image(systemName: "checkmark.circle.fill")
                                    .kidFont(34, maxScale: 1.15)
                                    .foregroundColor(.green)
                            } else if state == .wrong {
                                Image(systemName: "xmark.circle.fill")
                                    .kidFont(34, maxScale: 1.15)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .shadow(radius: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(borderColor(for: state), lineWidth: state == .none ? 2 : 6)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(answered)
                    .opacity(answered && state == .none ? 0.6 : 1.0)
                }
            }
            Spacer()
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🎉")
                .kidFont(90, maxScale: 1.15)
            Text("得了 \(score) 分！")
                .kidFont(40, .bold, maxScale: 1.15)
            Button("再来一局") {
                startNewGame()
            }
            .kidFont(28, .bold, maxScale: 1.15)
            .foregroundColor(.white)
            .padding(.horizontal, 48)
            .padding(.vertical, 18)
            .background(Capsule().fill(Color.green))
            Spacer()
        }
    }

    private func startNewGame() {
        questions = Array(words.shuffled().prefix(min(10, words.count)))
        index = 0
        score = 0
        finished = false
        answered = false
        setupQuestion()
    }

    private func setupQuestion() {
        guard index < questions.count else { return }
        let target = questions[index]
        let distractors = store.words
            .filter { $0.word != target.word }
            .shuffled()
            .prefix(3)
        options = ([target] + Array(distractors)).shuffled()
        correctIndex = options.firstIndex(where: { $0.word == target.word })
        pickedState = [:]
        answered = false
    }

    private func tapOption(_ i: Int) {
        guard !answered else { return }
        // 点哪个喇叭，就播放哪个词的发音
        playWord(options[i])
        if i == correctIndex {
            pickedState[i] = .correct
            answered = true
            score += 1
            successTrigger += 1
            advance()
        } else {
            pickedState[i] = .wrong
            errorTrigger += 1
        }
    }

    private func advance() {
        let current = index
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run {
                guard index == current, !finished else { return }
                if index + 1 < questions.count {
                    index += 1
                    setupQuestion()
                } else {
                    finished = true
                }
            }
        }
    }

    private func playWord(_ w: WordEntry) {
        if let url = store.bestAudioURL(forWord: w.word) {
            player.play(url: url)
        }
    }
}

// MARK: - 5. 看图选词 ImageToWordGame

struct ImageToWordGame: View {
    let words: [WordEntry]

    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()

    @State private var questions: [WordEntry] = []
    @State private var index: Int = 0
    @State private var score: Int = 0
    @State private var options: [WordEntry] = []
    @State private var correctIndex: Int? = nil
    @State private var pickedState: [Int: AnswerState] = [:]
    @State private var shakeCount: Int = 0
    @State private var answered: Bool = false
    @State private var finished: Bool = false
    @State private var successTrigger: Int = 0
    @State private var errorTrigger: Int = 0

    var body: some View {
        VStack(spacing: 20) {
            if finished {
                resultView
            } else if questions.isEmpty {
                ProgressView("准备题目中…")
            } else {
                gameView
            }
        }
        .padding()
        .navigationTitle("看图选词")
        .onAppear { startNewGame() }
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.error, trigger: errorTrigger)
    }

    private var gameView: some View {
        VStack(spacing: 16) {
            Text("第 \(index + 1) / \(questions.count) 题  ·  得分 \(score)")
                .kidFont(17, .semibold, maxScale: 1.15)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("这张图是哪个单词？🖼️")
                    .kidFont(24, .semibold, maxScale: 1.15)
                WordIconView(word: questions[index].word, size: 130)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(radius: 4)
                    )
            }

            VStack(spacing: 10) {
                ForEach(options.indices, id: \.self) { i in
                    let state = pickedState[i] ?? .none
                    Button {
                        tapOption(i)
                    } label: {
                        HStack {
                            Text(options[i].word)
                                .kidFont(26, .bold, maxScale: 1.15)
                            Spacer()
                            if state == .correct {
                                Image(systemName: "checkmark.circle.fill")
                                    .kidFont(26, maxScale: 1.15)
                                    .foregroundColor(.green)
                            } else if state == .wrong {
                                Image(systemName: "xmark.circle.fill")
                                    .kidFont(26, maxScale: 1.15)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white)
                                .shadow(radius: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(borderColor(for: state), lineWidth: state == .none ? 2 : 6)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(answered)
                    .modifier(ShakeEffect(animatableData: CGFloat(shakeCount)))
                    .opacity(answered && state == .none ? 0.6 : 1.0)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🎉")
                .kidFont(90, maxScale: 1.15)
            Text("得了 \(score) 分！")
                .kidFont(40, .bold, maxScale: 1.15)
            Button("再来一局") {
                startNewGame()
            }
            .kidFont(28, .bold, maxScale: 1.15)
            .foregroundColor(.white)
            .padding(.horizontal, 48)
            .padding(.vertical, 18)
            .background(Capsule().fill(Color.green))
            Spacer()
        }
    }

    private func startNewGame() {
        questions = Array(words.shuffled().prefix(min(10, words.count)))
        index = 0
        score = 0
        finished = false
        answered = false
        setupQuestion()
    }

    private func setupQuestion() {
        guard index < questions.count else { return }
        let target = questions[index]
        let distractors = store.words
            .filter { $0.word != target.word }
            .shuffled()
            .prefix(3)
        options = ([target] + Array(distractors)).shuffled()
        correctIndex = options.firstIndex(where: { $0.word == target.word })
        pickedState = [:]
        answered = false
    }

    private func tapOption(_ i: Int) {
        guard !answered else { return }
        if i == correctIndex {
            pickedState[i] = .correct
            answered = true
            score += 1
            successTrigger += 1
            // 读出正确单词，加深记忆
            playWord(questions[index])
            advance()
        } else {
            pickedState[i] = .wrong
            errorTrigger += 1
            withAnimation(.default) { shakeCount += 1 }
        }
    }

    private func advance() {
        let current = index
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            await MainActor.run {
                guard index == current, !finished else { return }
                if index + 1 < questions.count {
                    index += 1
                    setupQuestion()
                } else {
                    finished = true
                }
            }
        }
    }

    private func playWord(_ w: WordEntry) {
        if let url = store.bestAudioURL(forWord: w.word) {
            player.play(url: url)
        }
    }
}

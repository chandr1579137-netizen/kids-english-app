import SwiftUI

/// 练习页：4 种题型，60 分通过解锁下一课
struct QuizView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let lesson: Lesson

    @State private var index = 0
    @State private var correctCount = 0
    @State private var showResult = false
    @State private var currentCorrect: Bool?
    @State private var finished = false

    var body: some View {
        VStack {
            if finished {
                QuizResultView(
                    score: score,
                    passed: score >= 60,
                    onDone: {
                        store.completeLesson(lesson.id, quizScore: Double(score))
                        if let cards = lesson.rewards?.cards {
                            for c in cards { store.collectedCards.insert(c) }
                        }
                        store.saveProgress()
                        dismiss()
                    }
                )
            } else if index < lesson.quiz.count {
                VStack {
                    ProgressView(value: Double(index), total: Double(lesson.quiz.count))
                        .padding()
                    Text("第 \(index + 1) / \(lesson.quiz.count) 题")
                        .kidFont(17, .semibold)
                        .foregroundColor(.secondary)
                    QuizItemView(
                        item: lesson.quiz[index],
                        onAnswer: { correct in
                            currentCorrect = correct
                            if correct { correctCount += 1 }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                currentCorrect = nil
                                index += 1
                                if index >= lesson.quiz.count { finished = true }
                            }
                        }
                    )
                    if let c = currentCorrect {
                        Text(c ? "🎉 答对啦！" : "💪 再想想，下次加油！")
                            .kidFont(22, .bold)
                            .foregroundColor(c ? .green : .orange)
                            .padding()
                    }
                    Spacer()
                }
            }
        }
        .navigationTitle("练习时间")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var score: Int {
        guard !lesson.quiz.isEmpty else { return 0 }
        return Int(Double(correctCount) / Double(lesson.quiz.count) * 100)
    }
}

struct QuizResultView: View {
    let score: Int
    let passed: Bool
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(passed ? "🎉" : "💪").kidFont(100)
            Text("\(score) 分").kidFont(64, .bold)
            Text(passed ? "太棒了！下一课已解锁" : "差一点点，再学一次吧！")
                .kidFont(20)
                .foregroundColor(.secondary)
            Button(passed ? "继续闯关" : "知道了", action: onDone)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .kidFont(20)
        }
        .padding()
    }
}

// MARK: - 单题

struct QuizItemView: View {
    let item: QuizItem
    let onAnswer: (Bool) -> Void
    @State private var answered = false
    @State private var picked: String?

    var body: some View {
        VStack(spacing: 20) {
            Text(item.question)
                .kidFont(22, .bold)
                .multilineTextAlignment(.center)
                .padding()

            switch item.type {
            case "fill_blank", "image_choice":
                ChoiceOptions(item: item, answered: $answered, picked: $picked, onAnswer: onAnswer)
            case "sentence_order":
                OrderQuestion(item: item, answered: $answered, onAnswer: onAnswer)
            case "word_builder":
                BuilderQuestion(item: item, answered: $answered, onAnswer: onAnswer)
            default:
                Text("未知题型")
            }
        }
        .padding()
        .onChange(of: item.qid) {
            answered = false
            picked = nil
        }
    }
}

// MARK: 选择题（填空 / 看图）

struct ChoiceOptions: View {
    let item: QuizItem
    @Binding var answered: Bool
    @Binding var picked: String?
    let onAnswer: (Bool) -> Void

    var body: some View {
        VStack(spacing: 14) {
            ForEach(item.options ?? [], id: \.self) { opt in
                Button {
                    guard !answered else { return }
                    answered = true
                    picked = opt.value
                    onAnswer(opt.value == item.correctAnswer)
                } label: {
                    HStack {
                        // image 字段本意是 emoji；历史数据里混进过 "/assets/quiz/x.webp"
                        // 这类路径，直接 Text 会把整串路径画在选项上，这里只接受 emoji。
                        if let img = opt.image, !img.isEmpty, !img.hasPrefix("/") {
                            Text(img).kidFont(34)
                        }
                        Text(opt.text ?? opt.value ?? "")
                            .kidFont(20)
                        Spacer()
                        if answered && opt.value == item.correctAnswer {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        } else if answered && picked == opt.value {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(optionColor(opt))
                    .cornerRadius(14)
                }
                .disabled(answered)
            }
        }
    }

    private func optionColor(_ opt: QuizOption) -> Color {
        if answered && opt.value == item.correctAnswer { return .green.opacity(0.25) }
        if answered && picked == opt.value { return .red.opacity(0.2) }
        return Color(.secondarySystemBackground)
    }
}

// MARK: 句子排序

struct OrderQuestion: View {
    let item: QuizItem
    @Binding var answered: Bool
    let onAnswer: (Bool) -> Void
    @State private var selected: [String] = []
    @State private var remaining: [String] = []

    var body: some View {
        VStack(spacing: 16) {
            // 已选
            HStack {
                ForEach(Array(selected.enumerated()), id: \.offset) { _, w in
                    Text(w).kidFont(20, .bold).padding(8)
                        .background(Color.blue.opacity(0.2)).cornerRadius(8)
                }
            }
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            // 备选
            FlowWords(words: remaining) { w in
                guard !answered else { return }
                selected.append(w)
                if let i = remaining.firstIndex(of: w) { remaining.remove(at: i) }
                if remaining.isEmpty {
                    answered = true
                    onAnswer(selected == (item.correctOrder ?? []))
                }
            }

            if answered, let correct = item.correctOrder {
                Text("正确答案：" + correct.joined(separator: " "))
                    .kidFont(17).foregroundColor(.secondary)
            }

            Button("↩️ 重来") {
                selected = []
                remaining = item.shuffledWords ?? []
                answered = false
            }
            .disabled(answered)
        }
        .onAppear { remaining = item.shuffledWords ?? [] }
        .onChange(of: item.qid) {
            selected = []
            remaining = item.shuffledWords ?? []
            answered = false
        }
    }
}

// MARK: 单词拼装

struct BuilderQuestion: View {
    let item: QuizItem
    @Binding var answered: Bool
    let onAnswer: (Bool) -> Void
    @State private var selected: [String] = []
    @State private var remaining: [String] = []

    var body: some View {
        VStack(spacing: 16) {
            Text(selected.joined())
                .kidFont(40, .bold)
                .frame(minHeight: 60)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

            FlowWords(words: remaining) { letter in
                guard !answered else { return }
                selected.append(letter)
                if let i = remaining.firstIndex(of: letter) { remaining.remove(at: i) }
                if remaining.isEmpty {
                    answered = true
                    onAnswer(selected.joined() == (item.correctAnswer ?? ""))
                }
            }

            if answered {
                Text("正确答案：\(item.correctAnswer ?? "")")
                    .kidFont(17).foregroundColor(.secondary)
            }

            Button("↩️ 重来") {
                selected = []
                remaining = item.shuffledWords ?? []
                answered = false
            }
            .disabled(answered)
        }
        .onAppear { remaining = item.shuffledWords ?? [] }
        .onChange(of: item.qid) {
            selected = []
            remaining = item.shuffledWords ?? []
            answered = false
        }
    }
}

/// 简单流式布局
struct FlowWords: View {
    let words: [String]
    let onTap: (String) -> Void

    var body: some View {
        // 用 LazyVGrid 近似流式
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 64))], spacing: 10) {
            ForEach(Array(words.enumerated()), id: \.offset) { _, w in
                Button(w) { onTap(w) }
                    .kidFont(20, .bold)
                    .padding(.vertical, 10)
                    .frame(minWidth: 64)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(10)
            }
        }
    }
}

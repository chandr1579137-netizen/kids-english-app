import SwiftUI

/// 背单词 Tab：选词书 → 学习计划 → 今日新学（全屏卡片）→ 巩固练习入口
struct LearnWordsView: View {
    @Environment(DataStore.self) private var store
    @State private var player = AudioPlayer()

    /// 今日学习的卡片队列
    @State private var todayWords: [WordEntry] = []
    /// 当前卡片下标
    @State private var cardIndex = 0
    /// 是否显示庆祝页
    @State private var finished = false
    /// 今天新学的词（用于巩固练习入口）
    @State private var learnedToday: [WordEntry] = []
    /// 是否显示学习全屏页
    @State private var showStudy = false
    /// 是否跳转巩固练习
    @State private var goConsolidate = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. 今日计划（橙色渐变卡）
                    planCard
                        .padding(.horizontal)

                    // 2. 选词书（彩色横滑卡）
                    VStack(alignment: .leading, spacing: 12) {
                        Text("选词书")
                            .font(.title.bold())
                            .foregroundColor(AppTheme.navy)
                            .padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                bookCard(title: "全部单词", subtitle: "1074 词",
                                         color: AppTheme.brightBlue, iconName: "book",
                                         selected: store.selectedThemeId == nil) {
                                    store.selectedThemeId = nil
                                    store.saveProgress()
                                }
                                // 水果篇
                                bookCard(title: "水果篇", subtitle: "6 词",
                                         color: AppTheme.pink, iconName: "strawberry",
                                         selected: store.selectedThemeId == "fruits") {
                                    store.selectedThemeId = "fruits"
                                    store.saveProgress()
                                }
                                // 动物篇
                                bookCard(title: "动物篇", subtitle: "49 词",
                                         color: AppTheme.green, iconName: "panda",
                                         selected: store.selectedThemeId == "animals") {
                                    store.selectedThemeId = "animals"
                                    store.saveProgress()
                                }
                                // 交通工具
                                bookCard(title: "交通工具", subtitle: "7 词",
                                         color: AppTheme.purple, iconName: "bus",
                                         selected: store.selectedThemeId == "vehicles") {
                                    store.selectedThemeId = "vehicles"
                                    store.saveProgress()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // 3. 每日词数调节（白卡）
                    HStack {
                        Text("每天新学")
                            .font(.title3.bold())
                            .foregroundColor(AppTheme.navy)
                        Spacer()
                        Stepper("\(store.dailyNewWords) 个", value: .init(
                            get: { store.dailyNewWords },
                            set: { newValue in
                                store.dailyNewWords = newValue
                                store.saveProgress()
                            }
                        ), in: 5...20, step: 5)
                        .font(.title3)
                    }
                    .padding()
                    .whiteCard()
                    .padding(.horizontal)

                    // 4. 学习计划预览 Day1-Day3（白卡）
                    planPreviewCard
                        .padding(.horizontal)

                    // 5. 开始学习大按钮（绿）
                    BigButton(title: "开始学习 ▶", color: AppTheme.green) {
                        startStudy()
                    }
                    .padding(.horizontal)

                    // 6. 巩固练习入口（蓝）
                    BigButton(title: "巩固练习 · 9种玩法 🎮", color: Color(red: 0.55, green: 0.75, blue: 1.0)) {
                        goConsolidate = true
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .creamBackground()
            .navigationTitle("背单词")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                refreshToday()
            }
            .onChange(of: store.selectedThemeId) { _, _ in
                refreshToday()
            }
            .onChange(of: store.dailyNewWords) { _, _ in
                refreshToday()
            }
            .fullScreenCover(isPresented: $showStudy) {
                studyView
            }
            .navigationDestination(isPresented: $goConsolidate) {
                ConsolidationView(words: learnedToday.isEmpty ? todayWords : learnedToday)
            }
        }
    }

    // MARK: - 今日计划卡（橙色渐变 + 火箭图标）

    private var planCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("今日计划")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                Text("Day \(dayNumber)")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)
                Text("新学 \(todayWords.count) 个词")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                let total = store.words.count
                let done = store.learnedWords.count
                Text("已学 \(done) / \(total)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
            }
            Spacer()
            uiIcon("rocket")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 76, height: 76)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppTheme.planGradient)
        .cornerRadius(24)
        .shadow(color: .orange.opacity(0.3), radius: 12, y: 6)
    }

    private var dayNumber: Int {
        let perDay = max(1, store.dailyNewWords)
        return store.learnedWords.count / perDay + 1
    }

    // MARK: - 选词书彩色卡片（AI 图标）

    private func bookCard(title: String, subtitle: String, color: Color, iconName: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                uiIcon(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(width: 130, height: 150)
            .background(color)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white, lineWidth: selected ? 5 : 0)
            )
            .shadow(color: color.opacity(0.35), radius: 8, y: 4)
            .scaleEffect(selected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 学习计划预览

    private var planPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🗓️ 学习安排")
                .font(.title2.bold())
                .foregroundColor(AppTheme.navy)
            let days = Array(store.planDays().prefix(3))
            if days.isEmpty {
                Text("全部学完啦，太棒了！🎉")
                    .font(.title3)
            } else {
                ForEach(days.indices, id: \.self) { i in
                    HStack {
                        Text("Day\(i + 1)")
                            .font(.title3.bold())
                            .foregroundColor(i == 0 ? .orange : AppTheme.navy)
                            .frame(width: 70, alignment: .leading)
                        Text(days[i].prefix(3).map { $0.word }.joined(separator: " · "))
                            .font(.body)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        Spacer()
                        Text("\(days[i].count)词")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(i == 0 ? Color.orange : Color.gray.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .whiteCard()
    }

    // MARK: - 单词学习页（全屏）

    private var studyView: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if finished {
                    celebrationView
                } else if todayWords.isEmpty {
                    Text("今天没有新单词啦，换一本词书或明天再来吧！😊")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding()
                        .whiteCard()
                        .padding()
                } else {
                    HStack {
                        Text("\(cardIndex + 1) / \(todayWords.count)")
                            .font(.headline.bold())
                            .foregroundColor(AppTheme.navy)
                        ProgressView(value: Double(cardIndex) / Double(max(1, todayWords.count)))
                            .tint(.orange)
                    }
                    .padding(.horizontal, 24)

                    if todayWords.indices.contains(cardIndex) {
                        wordCard(todayWords[cardIndex])
                    }
                    Spacer()
                }
            }
            .creamBackground()
            .navigationTitle("今日新学")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("退出") { showStudy = false }
                        .font(.headline)
                }
            }
        }
    }

    private func wordCard(_ entry: WordEntry) -> some View {
        VStack(spacing: 16) {
            WordIconView(word: entry.word, size: 200)

            Text(entry.word)
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(AppTheme.brightBlue)
            Text(entry.phonetic)
                .font(.title2)
                .foregroundColor(.gray)
            Text(entry.meaningCn)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(AppTheme.wordOrange)

            HStack(spacing: 20) {
                PillButton(title: "🔊 正常", color: AppTheme.brightBlue) {
                    playBest(for: entry)
                }
                if store.slowAudioURL(forWord: entry.word) != nil {
                    PillButton(title: "🐢 慢速", color: AppTheme.green) {
                        playSlow(for: entry)
                    }
                }
            }
            .padding(.top, 8)

            HStack(spacing: 12) {
                studyActionButton("← 上一个", color: AppTheme.grayBtn) {
                    if cardIndex > 0 { cardIndex -= 1; playBest() }
                }
                studyActionButton("认识 ✓", color: AppTheme.green) {
                    markKnown(entry)
                }
                studyActionButton("不认识 ✕", color: AppTheme.red) {
                    nextCard()
                }
                studyActionButton("下一个 →", color: AppTheme.grayBtn) {
                    nextCard()
                }
            }
            .padding(.top, 4)
        }
        .padding(24)
        .whiteCard()
        .padding(.horizontal, 20)
    }

    private func studyActionButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 庆祝页

    private var celebrationView: some View {
        VStack(spacing: 24) {
            Text("🎉")
                .font(.system(size: 100))
            Text("今天学完啦！")
                .font(.largeTitle.bold())
                .foregroundColor(AppTheme.navy)
            Text("你学会了 \(learnedToday.count) 个新单词")
                .font(.title2)
                .foregroundColor(.gray)
            VStack(spacing: 14) {
                BigButton(title: "去巩固 🎮", color: AppTheme.brightBlue) {
                    showStudy = false
                    goConsolidate = true
                }
                BigButton(title: "再看一遍 📖", color: AppTheme.green) {
                    startStudy()
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(32)
        .whiteCard()
        .padding(.horizontal, 20)
    }

    // MARK: - 逻辑

    private func refreshToday() {
        todayWords = store.planDays().first ?? []
    }

    private func startStudy() {
        todayWords = store.planDays().first ?? []
        learnedToday = []
        cardIndex = 0
        finished = false
        showStudy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            playBest()
        }
    }

    private func currentEntry() -> WordEntry? {
        guard todayWords.indices.contains(cardIndex) else { return nil }
        return todayWords[cardIndex]
    }

    private func markKnown(_ entry: WordEntry) {
        store.markLearned(entry.word)
        store.saveProgress()
        if !learnedToday.contains(where: { $0.word == entry.word }) {
            learnedToday.append(entry)
        }
        nextCard()
    }

    private func nextCard() {
        if cardIndex + 1 < todayWords.count {
            cardIndex += 1
            playBest()
        } else {
            finished = true
        }
    }

    private func playBest() {
        if let entry = currentEntry() {
            playBest(for: entry)
        }
    }

    private func playBest(for entry: WordEntry) {
        if let url = store.bestAudioURL(forWord: entry.word) {
            player.play(url: url)
        }
    }

    private func playSlow(for entry: WordEntry) {
        if let url = store.slowAudioURL(forWord: entry.word) {
            player.play(url: url)
        }
    }
}
